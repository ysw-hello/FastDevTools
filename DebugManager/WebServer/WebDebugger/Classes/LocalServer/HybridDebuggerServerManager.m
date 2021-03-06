//
//  HybridDebuggerServerManager.m
//  FastDevTools
//
//  Created by TimmyYan on 2019/8/16.
//

#import "HybridDebuggerServerManager.h"
#import "HybridDebuggerMessageDispatch.h"
#import "HybridDebuggerViewController.h"
#import "HybridDebuggerLogger.h"
#import "HybridDebuggerDefine.h"
#import <FastDevTools/APMDataModel.h>

#import <GCDWebServer/GCDWebServerPrivate.h>
#import <YYModel/YYModel.h>
#import "WSFMDB.h"

@interface HybridDebuggerServerManager () <HybridDebuggerViewDelegate>

#pragma mark - Properties
@property (nonatomic, strong) dispatch_queue_t logQueue;

@property (nonatomic, strong) UIWindow *debugWindow;
@property (nonatomic, strong) UIButton *toggleButton;
@property (nonatomic, assign) CGPoint lastOffset;

@property (nonatomic, strong) GCDWebServer *webServer;

@property (nonatomic, copy) NSMutableArray *eventLogs;

@property (nonatomic, strong) HybridDebuggerViewController *debugVC;

@property (nonatomic, strong) WSFMDB *apm_db;

@property (nonatomic, strong) NSLock *lock;

#pragma mark - SEL

@end

static NSUInteger port = 8181;
static NSString *bonjourName = @"me.local";

@implementation HybridDebuggerServerManager

#pragma mark - Life Cycle
- (instancetype)init {
    self = [super init];
    if (self) {
        _eventLogs = [NSMutableArray array];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(requestEventOccur:) name:kHybridDebuggerInvokeRequestEvent object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(responseEventOccur:) name:kHybridDebuggerInvokeResponseEvent object:nil];
        [[HybridDebuggerMessageDispatch sharedInstance] setupDebugger];
        
        self.lock = [[NSLock alloc] init];
        self.logQueue = dispatch_queue_create("com.wslogger.syncQueue", DISPATCH_QUEUE_SERIAL);
        //初始化db
        NSString *dbName = @"APM_DB.sqlite";
        NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
        self.apm_db = [WSFMDB shareDatabase:dbName path:path];
        if(![_apm_db jq_isExistTable:@"apm_page"]) [_apm_db jq_createTable:@"apm_page" dicOrModel:[PageModel_APM class]];
        if(![_apm_db jq_isExistTable:@"apm_device"]) [_apm_db jq_createTable:@"apm_device" dicOrModel:[DeviceModel_APM class]];
        if(![_apm_db jq_isExistTable:@"apm_cpu"]) [_apm_db jq_createTable:@"apm_cpu" dicOrModel:[CPUModel_APM class]];
        if(![_apm_db jq_isExistTable:@"apm_memory"]) [_apm_db jq_createTable:@"apm_memory" dicOrModel:[MemoryModel_APM class]];
        if(![_apm_db jq_isExistTable:@"apm_disk"]) [_apm_db jq_createTable:@"apm_disk" dicOrModel:[DiskModel_APM class]];
        if(![_apm_db jq_isExistTable:@"apm_app"]) [_apm_db jq_createTable:@"apm_app" dicOrModel:[APPModel_APM class]];

    }
    return self;
}

#pragma mark - Getter Block
- (GCDWebServerProcessBlock)getRequestCallBack {
    typeof(self) __weak weakSelf = self;
    GCDWebServerProcessBlock block = ^GCDWebServerResponse *(GCDWebServerRequest *request) {
        
        NSBundle *bundle = [weakSelf getDebuggerBundle];
        NSString *filePath = request.URL.path;
        if ([filePath isEqualToString:@"/"]) {
            filePath = @"server.html";
        } 
        
        NSString *dataType = @"text";
        NSString *contentType = @"text/plain";
        if ([filePath hasSuffix:@".html"]) {
            contentType = @"text/html; charset=utf-8";
        } else if ([filePath hasSuffix:@".js"]) {
            contentType = @"application/javascript";
        } else if ([filePath hasSuffix:@".css"]) {
            contentType = @"text/css";
        } else if ([filePath hasSuffix:@".png"] || [filePath hasSuffix:@".ico"]) {
            contentType = @"image/png";
            dataType = @"data";
        } else if ([filePath hasSuffix:@".jpg"] || [filePath hasSuffix:@".jpeg"]) {
            contentType = @"image/jpeg";
            dataType = @"data";
        }
        
        NSURL *htmlURL = [[bundle bundleURL] URLByAppendingPathComponent:filePath];
        NSData *contentData = [NSData dataWithContentsOfURL:htmlURL];
        if (contentData.length > 0) {
            return [GCDWebServerDataResponse responseWithData:contentData contentType:contentType];
        }
        return [GCDWebServerDataResponse responseWithHTML:@"<html><body><p>Error </p></body></html>"];
        
    };
    return [block copy];
}

- (GCDWebServerProcessBlock)postRequestCallBack {
    typeof(self) __weak weakSelf = self;
    GCDWebServerProcessBlock block = ^GCDWebServerResponse *(GCDWebServerURLEncodedFormRequest *request) {
        typeof(weakSelf) __strong strongSelf = weakSelf;

        NSURL *url = request.URL;
        __block NSDictionary *result = @{};
        
        if ([url.path hasPrefix:@"/react_log.do"]) {
            dispatch_sync(strongSelf->_logQueue, ^{
                NSMutableArray *logStrs = [NSMutableArray arrayWithCapacity:10];
                [strongSelf.eventLogs enumerateObjectsUsingBlock:^(id _Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
                    
                    NSError *error;
                    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:obj options:NSJSONWritingPrettyPrinted error:&error];
                    if (!jsonData) {
                        WSLog(@"%s: error: %@", __func__, error.localizedDescription);
                    } else {
                        [logStrs addObject:[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]];
                    }
                }];
                result = @{ @"count" : @(strongSelf->_eventLogs.count), @"logs" : logStrs };
                
                [strongSelf.eventLogs removeAllObjects];
            });
            
        } else if ([url.path hasPrefix:@"/command.do"]) {
            NSString *action = [request.arguments objectForKey:kHybridDebuggerActionKey];
            NSString *param = [request.arguments objectForKey:kHybridDebuggerParamKey] ?: @"";
            
            NSDictionary *contentJSON = nil;
            NSError *contentParseError;
            if (param) {
                param = [self stringDecodeURIComponent:param];
                contentJSON = [NSJSONSerialization JSONObjectWithData:[param dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&contentParseError];
            }
            if (action.length > 0 ) {
                if ([NSThread isMainThread]) {
                    [[HybridDebuggerMessageDispatch sharedInstance] debugCommand:action param:contentJSON];
                } else {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[HybridDebuggerMessageDispatch sharedInstance] debugCommand:action param:contentJSON];
                    });
                }
                [strongSelf.webServer logInfo:@"action:%@, param:%@", action, param];
            } else {
                // 异常记录
                if (action.length < 1) {
                    WSLog(@"action 为空");
                    [strongSelf.webServer logInfo:@"Command input is nil"];
                }
                
                if (![contentJSON isKindOfClass:[NSDictionary class]] || contentParseError) {
                    WSLog(@"参数解析或类型错误, err:%@", contentParseError.localizedDescription);
                }
                [strongSelf.webServer logInfo:@"ParamParseError, err:%@", contentParseError.localizedDescription];
            }
        } else if ([url.path hasPrefix:[@"/" stringByAppendingString:APM_WritePath]]) { //APM写入数据接口
            [strongSelf proceeWriteAPMData:request.data];
        } else if ([url.path containsString:[@"/" stringByAppendingString:APM_ReadPath]]) { //APM读取数据接口
            if (request.data.length > 0) {
                [strongSelf.apm_db jq_inDatabase:^{
                    result = [strongSelf proceeReadAPMData:request.data];
                }];
            }
        }
        
        return [GCDWebServerDataResponse responseWithJSONObject:@{@"code" : @(200), @"data" : result.mutableCopy}];
        
    };
    return [block copy];
}

#pragma mark - Public SEL
+ (instancetype)sharedInstance {
    static HybridDebuggerServerManager *_manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _manager = [[HybridDebuggerServerManager alloc] init];        
    });
    return _manager;
}

- (void)hideDebugWindow {
    if (self.debugWindow) {
        self.debugWindow.hidden = YES;
    }
}

- (void)showDebugWindow {
    if (self.debugWindow) {
        self.debugWindow.hidden = NO;
        return;
    }
    
    UIWindow *window = [[UIWindow alloc] initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width - 60, 150, 55.f, 46.f)];
    window.backgroundColor = [UIColor clearColor];
    window.windowLevel = UIWindowLevelStatusBar - 1;
    window.hidden = NO;
    window.clipsToBounds = YES;
    window.tag = 1818;
    self.debugWindow = window;
    
    // 增加显示隐藏按钮， 切换按钮，展开时，隐藏；收起时显示
    UIButton *toggle = [UIButton buttonWithType:UIButtonTypeCustom];
    NSString *imagePath = [[self getDebuggerBundle].bundlePath stringByAppendingString:@"/images/debuggerLogo.png"];
    UIImage *ico = [UIImage imageWithContentsOfFile:imagePath];
    [toggle setImage:ico forState:UIControlStateNormal];
    [toggle addTarget:self action:@selector(toggleWin:) forControlEvents:UIControlEventTouchUpInside];
    [window addSubview:toggle];
    self.toggleButton = toggle;
    
    toggle.translatesAutoresizingMaskIntoConstraints = NO;
    if (@available(iOS 9.0, *)) {
        [toggle.topAnchor constraintEqualToAnchor:window.topAnchor constant:0].active = YES;
        [toggle.rightAnchor constraintEqualToAnchor:window.rightAnchor].active = YES;
        [toggle.widthAnchor constraintEqualToConstant:40].active = YES;
        [toggle.heightAnchor constraintEqualToConstant:40].active = YES;
    }
    // 为 window 增加拖拽功能
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleDrag:)]; //创建手势
    window.userInteractionEnabled = YES;
    [window addGestureRecognizer:pan];
}

- (__kindof NSString *)startDebugServer {
    if (_webServer) {
        return _webServer.serverURL.absoluteString?:@"--";
    }
    
    [self showDebugWindow];
    
    // Create server
    _webServer = [[GCDWebServer alloc] init];
    
    if (kGCDWebServer_logging_enabled) { // 开启本地日志记录
        [[HybridDebuggerLogger sharedInstance] startLogger];
    }
    
    // 添加GET请求的回调处理<不区分URL>
    [_webServer addDefaultHandlerForMethod:@"GET"
                              requestClass:[GCDWebServerRequest class]
                              processBlock:[self getRequestCallBack]];
    
    // 添加POST请求的回调处理<不区分URL>
    [_webServer addDefaultHandlerForMethod:@"POST"
                              requestClass:[GCDWebServerURLEncodedFormRequest class]
                              processBlock:[self postRequestCallBack]];
    
    // 开启Server（port：8181）
    BOOL res = [_webServer startWithPort:port bonjourName:bonjourName];
    if (res) {
      [_webServer logInfo:@"HybridLogServer -- start(url:%@)", _webServer.serverURL];
        WSLog(@"xxx-DebugServerStartSuccess!!!");
    } else {
        WSLog(@"xxx-DebugServerStartFailure!!!");
    }
    
    return res ? _webServer.serverURL.description?:@"--" : @"webServer 服务开启失败";
}

- (GCDWebServer *)getLocalServer {
    return _webServer;
}

- (void)stopDebugServer {
    if (_webServer.isRunning) {
      [_webServer stop];
        _webServer = nil;
    }
    [self hideDebugWindow];
}

#pragma mark - pravite SEL
- (float)changeToMBWithByte:(long long)byte { //保留三位小数
    float mb = byte / 1024.0 / 1024.0;
    return roundf(mb * 1000) / 1000;
}

- (NSDictionary *)proceeReadAPMData:(NSData *)bodyData { //TODO：从数据库取数据，实时绘制
    NSDictionary *bodyDic = [NSDictionary ws_dictionaryWithJSON:bodyData];
    WSLog(@"webServer接收的APM数据Body:\n%@",bodyDic);
    
    long long time = [[bodyDic objectForKey:@"interval"] longLongValue] - 60*5; //查询时间戳参数前五分钟的数据
    NSString *sqlStr = [NSString stringWithFormat:@"select memoryFree,memoryActive,memoryInactive,memoryWired,memoryPurgable,curInterval from apm_memory where cast(curInterval as long) > %lld ", time];
    
    FMResultSet *res = [self.apm_db.db executeQuery:sqlStr];
    NSMutableArray *freeArr = @[].mutableCopy;
    NSMutableArray *activeArr = @[].mutableCopy;
    NSMutableArray *wiredArr = @[].mutableCopy;
    NSMutableArray *inactiveArr = @[].mutableCopy;
    NSMutableArray *purgableArr = @[].mutableCopy;
    
    long long interval = time * 1000 + 8*3600*1000;
    BOOL flag = NO;
    while ([res next]) {
        NSDictionary *dic = [res resultDictionary];
        //空闲内存
        float free = [self changeToMBWithByte:[[dic objectForKey:@"memoryFree"] longLongValue]];
        [freeArr addObject:[NSNumber numberWithFloat:free]];
        //活跃内存
        float act = [self changeToMBWithByte:[[dic objectForKey:@"memoryActive"] longLongValue]]; //系统活跃内存
        [activeArr addObject:[NSNumber numberWithFloat:act]];
        //联动内存(系统内核)
        float wired = [self changeToMBWithByte:[[dic objectForKey:@"memoryWired"] longLongValue]]; //系统内核占用内存
        [wiredArr addObject:[NSNumber numberWithFloat:wired]];
        //系统管控可擦除内存(可能是缓存相关占用)
        float purgable = [self changeToMBWithByte:[[dic objectForKey:@"memoryPurgable"] longLongValue]];
        [purgableArr addObject:[NSNumber numberWithFloat:purgable]];
        //当前不活跃内存
        float inactive = [self changeToMBWithByte:[[dic objectForKey:@"memoryInactive"] longLongValue]];
        [inactiveArr addObject:[NSNumber numberWithFloat:inactive]];
        
        if (!flag) {
            interval = [[dic objectForKey:@"curInterval"] longLongValue] * 1000 + 8*3600*1000;
            flag = YES;
        }
        
    }
    
    NSDictionary *perUnit_Active = @{
                                   @"data": activeArr,
                                   @"name": @"活跃内存",
                                   @"pointStart" : @(interval),
                                   @"pointInterval" : @(2000)
                                   };
    
    NSDictionary *perUnit_Free = @{
                                   @"data": freeArr,
                                   @"name": @"空闲内存",
                                   @"pointStart" : @(interval),
                                   @"pointInterval" : @(2000)
                                   };
    NSDictionary *perUnit_Inactive = @{
                                     @"data": inactiveArr,
                                     @"name": @"不活跃内存",
                                     @"pointStart" : @(interval),
                                     @"pointInterval" : @(2000)
                                     };
    NSDictionary *perUnit_Wired = @{
                                     @"data": wiredArr,
                                     @"name": @"系统联动内存",
                                     @"pointStart" : @(interval),
                                     @"pointInterval" : @(2000)
                                     };
    NSDictionary *perUnit_Purgable = @{
                                     @"data": purgableArr,
                                     @"name": @"可擦除内存",
                                     @"pointStart" : @(interval),
                                     @"pointInterval" : @(2000)
                                     };

    
    NSDictionary *param = @{
                            @"series": @[
                                    perUnit_Free,
                                    perUnit_Active,
                                    perUnit_Wired,
                                    perUnit_Inactive,
                                    perUnit_Purgable
                                    ],
                            @"titleName": @"内存图表",
                            @"subtitleName": @"",
                            @"xAxis_maxZoom": @(300000)
                            };
    return param;
}
- (void)proceeWriteAPMData:(NSData *)bodyData { //TODO:设置数据库存储大小
    __weak typeof(self) weakSelf = self;
    [_apm_db jq_inDatabase:^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        APMDataModel *model = [APMDataModel yy_modelWithJSON:bodyData];
        if (model.page.fps > 0) {
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^{
                [strongSelf.apm_db jq_insertTable:@"apm_device" dicOrModel:model.device];
                [strongSelf.apm_db jq_insertTable:@"apm_app" dicOrModel:model.app];
            });
            [strongSelf.apm_db jq_insertTable:@"apm_cpu" dicOrModel:model.cpu];
            [strongSelf.apm_db jq_insertTable:@"apm_disk" dicOrModel:model.disk];
            [strongSelf.apm_db jq_insertTable:@"apm_memory" dicOrModel:model.memory];
            [strongSelf.apm_db jq_insertTable:@"apm_page" dicOrModel:model.page];
        }
        
#if DEBUG
        NSDictionary *apmDic = [NSDictionary ws_dictionaryWithJSON:bodyData];
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:apmDic options:NSJSONWritingPrettyPrinted  error:nil];
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        WSLog(@"webServer接收的APM数据:\n%@",jsonString);
#endif
        
    }];
    
}

- (NSBundle *)getDebuggerBundle {
    NSBundle *debuggerBundle = [NSBundle bundleWithURL:[[NSBundle mainBundle] URLForResource:kHybridDebuggerBundleName withExtension:@"bundle"]];
    return debuggerBundle;
}

- (NSString *)stringDecodeURIComponent:(NSString *)encoded {
    NSString *decoded = [encoded stringByRemovingPercentEncoding];
    WSLog(@"DecodedString %@", decoded);
    return decoded;
}

#pragma mark - noti
- (void)requestEventOccur:(NSNotification *)notification {
    dispatch_async(_logQueue, ^{
        [self.eventLogs addObject:@{ @"type" : @".invoke", @"value" : notification.object }];
    });
}

- (void)responseEventOccur:(NSNotification *)notification {
    dispatch_async(_logQueue, ^{
        [self.eventLogs addObject:@{ @"type" : @".on", @"value" : notification.object }];
    });
}

#pragma mark - action
- (void)toggleWin:(UIButton *)sender {
    if (!self.debugVC) {
        self.debugVC = [[HybridDebuggerViewController alloc] init];
        _debugVC.debugViewDelegate = self;
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:_debugVC];
        self.debugWindow.rootViewController = nav;
    }
    self.debugWindow.frame = [[UIScreen mainScreen] bounds];
    [[HybridDebuggerLogger sharedInstance] clearOffset];
    [self.debugVC onWindowShow];
    self.toggleButton.hidden = YES;
}

- (void)handleDrag:(UIPanGestureRecognizer *)pan {
    if (pan.state == UIGestureRecognizerStateBegan) {
        self.lastOffset = CGPointZero;
    }
    // 注意：这里的 offset 是相对于在手势开始之前的位置作为基准，和当前手势做差值得出来的位移
    CGPoint offset = [pan translationInView:self.debugWindow];
    CGRect newFrame = CGRectOffset(self.debugWindow.frame, offset.x - self.lastOffset.x, offset.y - self.lastOffset.y);
    if (newFrame.origin.x < 0) {
        newFrame.origin.x = 0;
    } else if (newFrame.origin.x > [UIScreen mainScreen].bounds.size.width - newFrame.size.width / 2) {
        newFrame.origin.x = [UIScreen mainScreen].bounds.size.width - newFrame.size.width / 2;
    }
    
    if (newFrame.origin.y < 0) {
        newFrame.origin.y = 0;
    } else if (newFrame.origin.y > [UIScreen mainScreen].bounds.size.height - newFrame.size.height / 2) {
        newFrame.origin.y = [UIScreen mainScreen].bounds.size.height - newFrame.size.height / 2;
    }
    
    self.debugWindow.frame = newFrame;
    self.lastOffset = offset;
    
    if (pan.state == UIGestureRecognizerStateEnded || pan.state == UIGestureRecognizerStateCancelled || pan.state == UIGestureRecognizerStateFailed) {
        self.lastOffset = CGPointZero;
    }
}

#pragma mark - Protocol Conform
- (void)onCloseWindow:(HybridDebuggerViewController *)viewController {
    self.debugWindow.frame = CGRectMake([UIScreen mainScreen].bounds.size.width - 60, 150, 55.f, 46.f);
    self.toggleButton.hidden = NO;
    [self.debugWindow bringSubviewToFront:self.toggleButton];
    self.debugWindow.rootViewController = nil;
    self.debugVC = nil;
    [[HybridDebuggerLogger sharedInstance] clearOffset];
}

- (void)fetchData:(HybridDebuggerViewController *)viewController completion:(void (^)(NSArray<NSString *> *))completion {
    [[HybridDebuggerLogger sharedInstance] parseLog:[completion copy]];
}


@end
