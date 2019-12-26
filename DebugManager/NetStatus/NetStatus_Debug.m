//
//  NetStatus_Debug.m
//  NetStatus_Demo
//
//  Created by TimmyYan on 2018/12/3.
//  Copyright © 2018年 com.ysw. All rights reserved.
//

#import "NetStatus_Debug.h"
#import "NetStatus_ContentView.h"
#import "UIView+Debug_Additions.h"

@interface NetStatus_Debug () <NetStatus_ServiceDelegate>

@property (nonatomic, strong) dispatch_source_t timer;

@property (nonatomic, strong) NetStatus_Service *netService;
@property (nonatomic, strong) NSString *logInfo;

@property (nonatomic, strong) NetStatus_ContentView *contentView;
@end

@implementation NetStatus_Debug

#pragma mark - public SEL
+ (instancetype)sharedInstance {
    static NetStatus_Debug *nt = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        nt = [[NetStatus_Debug alloc] init];
    });
    return nt;
}

- (void)showNetMonitorViewWithRootViewController:(UIViewController *)rootViewController  uid:(NSString *)uid{
    self.contentView = [[NetStatus_ContentView alloc] initWithFrame:CGRectMake(0, kDebug_StatusBarHeight, kDebug_ScreenWidth, kDebug_ScreenHeight - kDebug_StatusBarHeight) uid:uid];
    _contentView.tag = NetStatus_ContentView_TAG;
    _contentView.alpha = 0.8;
    _contentView.backgroundColor = [UIColor blackColor];
    [rootViewController.view addSubview:_contentView];
}

- (void)hideNetMonitorView {
    [self.contentView removeFromSuperview];
    self.contentView = nil;
}

#pragma mark - 网络诊断分析
- (void)startAnalyzeNetServiceWithDormain:(NSString *)dormain uid:(NSString *)uid logStepInfoBlock:(NetAnalyzeBlock)logStepInfoBlock{
    _netService = [[NetStatus_Service alloc] initWithAppName:nil appVersion:nil uid:uid deviceId:nil dormain:dormain];
    _netService.delegate = self;
    _isServiceRunning = NO;
    _logInfo = @"";
    self.serviceBlock = [logStepInfoBlock copy];
    [_netService startNetService];
}

- (void)stopAnalyzeNetService {
    NSLog(@"网络诊断终止");

    if (_netService) {
        [_netService stopNetService];
        _netService = nil;
    }
}

#pragma mark netServiceDelegate
///开始诊断
- (void)netServiceDidStarted {
    NSLog(@"开始进行网络诊断");
    self.isServiceRunning = YES;
    [self excuteOnMainThread:@"" isRunning:YES];
}
///分步骤返回诊断信息
- (void)netServiceStepInfo:(NSString *)stepInfo {
    NSLog(@"网络诊断中：%@", stepInfo);
    _logInfo = [_logInfo stringByAppendingString:stepInfo];
    [self excuteOnMainThread:_logInfo isRunning:YES];
}
///诊断结束
- (void)netServiceDidEnd:(NSString *)allLogInfo {
    NSLog(@"网络诊断结束");
    self.isServiceRunning = NO;
    [self excuteOnMainThread:allLogInfo isRunning:NO];
}

- (void)excuteOnMainThread:(NSString *)logInfo isRunning:(BOOL)isRunning {
    if ([NSThread isMainThread]) {
        if (self.serviceBlock) {
            self.serviceBlock(logInfo, isRunning);
        }
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.serviceBlock) {
                self.serviceBlock(logInfo, isRunning);
            }
        });
    }
}

#pragma mark - 网络状态监测
- (void)startMonitorNetStateWithBlock:(NetStateBlock)block {
    [NSReachabilityInstance startNotifier];

    self.stateBlock = [block copy];
    if (self.stateBlock) {
        self.stateBlock([NSReachabilityInstance currentReachabilityStatus], [NSReachabilityInstance currentWWANType], [NSReachabilityInstance isVPNOn]);
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkChanged:) name:kNSReachabilityChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(VPNStatusChanged:) name:kNSVPNChangedNotification object:nil];
}
- (void)networkChanged:(NSNotification *)notification {
    self.stateBlock([NSReachabilityInstance currentReachabilityStatus], [NSReachabilityInstance currentWWANType], [NSReachabilityInstance isVPNOn]);
}
- (void)VPNStatusChanged:(NSNotification *)notification {
    self.stateBlock([NSReachabilityInstance currentReachabilityStatus], [NSReachabilityInstance currentWWANType], [NSReachabilityInstance isVPNOn]);
}

- (void)stopMonitorNetState {
    [NSReachabilityInstance stopNotifier];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNSReachabilityChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNSVPNChangedNotification object:nil];
}

#pragma mark - 网速监测
- (void)startMonitorNetSpeedWithBlock:(NetDataPerSecBlock)block {
    self.dataHandler = [block copy];
    if (!_timer) {
        __block NSUInteger wifiSent = 0, wifiReceive = 0, WWANSent = 0, WWANReceive = 0;
        __weak typeof(self) weakSelf = self;
        dispatch_queue_t queue = dispatch_queue_create(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        self.timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
        dispatch_source_set_timer(_timer, dispatch_walltime(NULL, 0), 1.0*NSEC_PER_SEC, 0);
        dispatch_source_set_event_handler(self.timer, ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            NSDictionary *dict = [NetStatus_Speed getNetSpeedData];
            NSUInteger followWiFiSent = 0, followWiFiReceive = 0, followWWANSent = 0, followWWANReceive = 0;
            switch ([NSReachabilityInstance currentReachabilityStatus]) {
                case NetStatusViaWiFi:
                    followWiFiSent = [dict[WiFiSentKey] integerValue];
                    followWiFiReceive = [dict[WiFiReceiveKey] integerValue];
                    if (wifiSent == 0 || wifiReceive == 0 || (followWiFiSent - wifiSent < 1 && followWiFiReceive - wifiReceive < 1)) {
                        wifiSent = followWiFiSent;
                        wifiReceive = followWiFiReceive;
                        return;
                    }
                    break;
                    
                case NetStatusViaWWAN:
                    followWWANSent = [dict[WWANSentKey] integerValue];
                    followWWANReceive = [dict[WWANReceiveKey] integerValue];
                    if (WWANSent == 0 || WWANReceive == 0 || (followWWANSent - WWANSent < 1 && followWWANReceive - WWANReceive < 1)) {
                        WWANSent = followWWANSent;
                        WWANReceive = followWWANReceive;
                        return;
                    }
                    break;
                    
                default:
                    break;
            }
            __weak typeof(strongSelf) wSelf = strongSelf;
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong typeof(wSelf) sSelf = wSelf;
                CGFloat dSpeed = 0.00, uSpeed = 0.00;
                switch ([NSReachabilityInstance currentReachabilityStatus]) {
                    case NetStatusViaWiFi:
                        dSpeed = (followWiFiReceive - wifiReceive) / 1024.f;
                        uSpeed = (followWiFiSent - wifiSent) / 1024.f;
                        sSelf.dataHandler(dSpeed, uSpeed);
                        wifiSent = followWiFiSent;
                        wifiReceive = followWiFiReceive;
                        break;
                        
                    case NetStatusViaWWAN:
                        dSpeed = (followWWANReceive - WWANReceive) / 1024.f;
                        uSpeed = (followWWANSent - WWANSent) / 1024.f;
                        sSelf.dataHandler(dSpeed, uSpeed);
                        WWANSent = followWWANSent;
                        WWANReceive = followWWANReceive;
                        break;
                        
                    default:
                        sSelf.dataHandler(0.00, 0.00);
                        break;
                }
            });
        });
        
        dispatch_resume(self.timer);
    }
}

- (void)stopMonitorNetSpeed {
    if (_timer) {
        dispatch_source_cancel(self.timer);
        self.timer = nil;
    }
}

@end
