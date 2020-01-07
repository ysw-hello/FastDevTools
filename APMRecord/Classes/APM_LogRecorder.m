//
//  APM_LogRecorder.m
//  FastDevTools
//
//  Created by TimmyYan on 2019/12/9.
//

#import "APM_LogRecorder.h"
#import "NSData+gzip.h"
#import <Foundation/Foundation.h>

@interface APM_LogRecorder ()

@property (nonatomic, strong) dispatch_source_t timer;
@property (nonatomic, strong) dispatch_queue_t safeQueue;

@property (nonatomic, copy) DeviceAPM_Handler handler;

@property (nonatomic, assign) __block NSUInteger times;

@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, assign) NSTimeInterval lastTimeStamp;
@property (nonatomic, assign) NSUInteger countPerFrame;
@property (nonatomic, assign) NSUInteger currentFPS;
@property (nonatomic, strong) NSLock *lock;

@end

@implementation APM_LogRecorder

#pragma mark - init
+ (instancetype)sharedInstance {
    static APM_LogRecorder *alr = nil;
    static dispatch_once_t onceToken ;
    dispatch_once(&onceToken, ^{
        alr = [[APM_LogRecorder alloc] init] ;
        alr.safeQueue = dispatch_queue_create("com.device.apm", DISPATCH_QUEUE_SERIAL);
        [[NSNotificationCenter defaultCenter] addObserver:alr selector:@selector(stopFetchData) name:UIApplicationDidEnterBackgroundNotification object:nil];
        alr.lock = [[NSLock alloc] init];
    });
    return alr ;
}

#pragma mark - settter
- (void)setReceiveUrl:(NSString *)receiveUrl {
    if (receiveUrl.length < 3) {
        _receiveUrl = nil;
    }
    _receiveUrl = receiveUrl;
}

#pragma mark - public SEL
void APM_RecorderSetURL (NSString *apmUrlStr) {
    [[APM_LogRecorder sharedInstance] setReceiveUrl:apmUrlStr];
}

void APM_RecordLog(NSString *name, NSDictionary *param) {
    [[APM_LogRecorder sharedInstance] logRecordWithName:name busiParam:param interval:4 dataHandler:nil];
}

void APM_RecordStop() {
    [[APM_LogRecorder sharedInstance] stopFetchData];
}

void APM_SamplingRecordLog(NSString *name, NSDictionary *param) {
    [[APM_LogRecorder sharedInstance] fetchDeviceAPMWithName:name param:param SamplingCount:18 interval:0.8 dataHandler:nil];
}

- (void)logRecordWithName:(NSString *)name busiParam:(NSDictionary * __nullable)busiParam interval:(CGFloat)interval dataHandler:(DeviceAPM_Handler)dataHandler {
    [self fetchDeviceAPMWithName:name param:busiParam SamplingCount:ULONG_MAX interval:interval dataHandler:dataHandler];
}

- (void)tracelessRecordWithPageModel:(PageModel_APM *)pageModel interval:(CGFloat)interval dataHandler:(DeviceAPM_Handler)dataHandler {
    [self logRecordWithName:pageModel.pageName busiParam:[pageModel yy_modelToJSONObject] interval:interval dataHandler:dataHandler];;
}

- (void)fetchDeviceAPMWithName:(NSString *)name param:(NSDictionary * __nullable)param SamplingCount:(NSUInteger)count interval:(CGFloat)interval dataHandler:(DeviceAPM_Handler)dataHandler {
    [_lock lock];
    
    if (self.receiveUrl.length < 3) {
        return;
    }
    
    if (interval < 0.1) {
        interval = 1.8; //默认1.8s
    }
    [self stopFetchData];
    [self startMonitorFPS];
    self.handler = [dataHandler copy];
    self.times = 0;
    
    __weak typeof(self) weakSelf = self;
    @try {
        self.timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, self.safeQueue ? : dispatch_queue_create("com.system.monitor", DISPATCH_QUEUE_SERIAL));
        dispatch_source_set_timer(_timer, dispatch_walltime(NULL, 0), interval*NSEC_PER_SEC, 0);
        dispatch_source_set_event_handler(_timer, ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            
            APMDataModel *model = [APMDataModel createAPMDataWithName:name param:param fps:strongSelf.currentFPS];
            [strongSelf processHandlerWithModel:model]; //回调数据

            strongSelf.times++;
            if (strongSelf.times >= count) {
                [strongSelf stopFetchData];
            }
            
        });
        
        if (@available(iOS 10.0, *)) {
            dispatch_activate(_timer);
        } else {
            dispatch_resume(_timer);
        }
        
    } @catch (NSException *exception) {
        NSLog(@"性能检测异常:%@",exception.description);
    }
    
    [_lock unlock];
}

- (void)stopFetchData {
    //销毁定时器
    if (_timer) {
        dispatch_source_cancel(_timer);
        //尝试修复可能导致的crash block_invoke / objc_msg_send
        if (dispatch_source_testcancel(_timer)) {
            self.timer = nil;
        }
    }
    [self destoryFPSMonitor];
}


- (void)processHandlerWithModel:(APMDataModel *)model {
    __weak typeof(self) wSelf = self;
    dispatch_async(self.safeQueue, ^{
        __strong typeof(wSelf) strongSelf = wSelf;
        [strongSelf sendAPMModel:model];
    });
    
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof(wSelf) sSelf = wSelf;
        if (sSelf.handler) {
            sSelf.handler(model);
        }
    });
}

#pragma mark - FPS
- (void)startMonitorFPS {
    _lastTimeStamp = -1;
    _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(envokeDisplayLink:)];
    _displayLink.paused = NO;
    [_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)envokeDisplayLink:(CADisplayLink *)displaylink {
    if (_lastTimeStamp == -1) {
        _lastTimeStamp = displaylink.timestamp;
        return;
    }
    _countPerFrame ++;
    NSTimeInterval interval = displaylink.timestamp - _lastTimeStamp;
    if (interval < 1) {
        return;
    }
    _lastTimeStamp = displaylink.timestamp;
    NSUInteger fpsCount = (NSUInteger)round(_countPerFrame / interval);
    self.currentFPS = fpsCount > 60 ? 60 : (fpsCount < 0 ? 0 : fpsCount);
    _countPerFrame = 0;
}

- (void)destoryFPSMonitor {
    if (_displayLink) {
        _displayLink.paused = YES;
        [_displayLink invalidate];
    }
}

#pragma mark - private SEL
- (BOOL)sendAPMModel:(APMDataModel *)model {
    if (self.receiveUrl.length < 3 || !model.name) {
        return NO;
    }
    
    NSString *url = [self.receiveUrl stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    NSMutableURLRequest *req = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
    
    NSString *logStr = [model yy_modelToJSONString];
    NSData *logData = [logStr dataUsingEncoding:NSUTF8StringEncoding];
    NSData *gziped = [logData gzipDeflate];
    [req setHTTPMethod: @"POST"];
    [req setHTTPBody:gziped];
    [req setTimeoutInterval:10];//设置请求超时时间为10s
    [req addValue:@"gzip" forHTTPHeaderField:@"Content-Encoding"];
    
    // 配合日志服务器校验，需要增加额外HTTP Header
    NSInteger rawLength = logStr.length;
    NSInteger gzipLength = gziped.length;
    [req addValue:@(rawLength).stringValue forHTTPHeaderField:@"length"];
    [req addValue:@(gzipLength).stringValue forHTTPHeaderField:@"Content-Length"];
    
    // crc32校验(规则：json串长度%%压缩后二进制流长度)
    NSString *combineStr = [NSString stringWithFormat:@"%ld%%%ld", (long)rawLength, (long)gzipLength];
    NSData *sourceStrData = [combineStr dataUsingEncoding:NSUTF8StringEncoding];
    unsigned long result = crc32(0, sourceStrData.bytes, (unsigned int)sourceStrData.length);
    [req addValue:[NSString stringWithFormat:@"%lu",result] forHTTPHeaderField:@"sign"];
    
    if (@available(iOS 9.0, *)) {
        __block BOOL succeed = NO;
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(1); //利用信号量阻塞当前线程，模拟同步请求
        
        NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:req completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
            succeed = [httpResponse statusCode] == 200;
            
            dispatch_semaphore_signal(semaphore);
        }];
        [task resume];
        
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        return succeed;
        
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        NSURLResponse *response = nil;
        [NSURLConnection sendSynchronousRequest:req returningResponse:&response error:nil];
        NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
#pragma clang diagnostic pop
        return [httpResponse statusCode] == 200;
    }
    
}



@end
