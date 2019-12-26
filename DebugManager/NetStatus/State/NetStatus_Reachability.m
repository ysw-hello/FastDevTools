//
//  NetStatus_Reachability.m
//  NetStatus_Demo
//
//  Created by TimmyYan on 2018/11/29.
//  Copyright © 2018年 com.ysw. All rights reserved.
//

#import "NetStatus_Reachability.h"
#import <ifaddrs.h>
#import "NetStatus_Engine.h"
#import "NetStatus_PingHelper.h"
#import <UIKit/UIKit.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>

#if (!defined(DEBUG))
#define NSLog(...)
#endif

#define kNSDefaultHost @"www.baidu.com"
#define kNSDefaultCheckInterval 2.0f
#define kNSDefaultPingTimeout 2.0f

#define kNSMinAutoCheckInterval 0.3f
#define kNSMaxAutoCheckInterval 60.0f

NSString *const kNSReachabilityChangedNotification = @"kNSReachabilityChangedNotification";
NSString *const kNSVPNChangedNotification = @"kNSVPNChangedNotification";

@interface NetStatus_Reachability ()
@property (nonatomic, assign) BOOL vpnFlag;
@property (nonatomic, strong) NetStatus_Engine *engine;
@property (nonatomic, assign) BOOL isNotifying;

@property (nonatomic,strong) NSArray *typeStrings4G;
@property (nonatomic,strong) NSArray *typeStrings3G;
@property (nonatomic,strong) NSArray *typeStrings2G;
@property (nonatomic, assign) NSReachabilityStatus previousStatus;

/**
 main helper
 */
@property (nonatomic, strong) NetStatus_PingHelper *pingHelper;

/**
 double check
 */
@property (nonatomic, strong) NetStatus_PingHelper *pingChecker;

@end

@implementation NetStatus_Reachability

- (instancetype)init {
    self = [super init];
    if (self) {
        _engine = [[NetStatus_Engine alloc] init];
        [_engine start];
        
        _typeStrings2G = @[CTRadioAccessTechnologyEdge,
                           CTRadioAccessTechnologyGPRS,
                           CTRadioAccessTechnologyCDMA1x];
        _typeStrings3G = @[CTRadioAccessTechnologyHSDPA,
                           CTRadioAccessTechnologyWCDMA,
                           CTRadioAccessTechnologyHSUPA,
                           CTRadioAccessTechnologyCDMAEVDORev0,
                           CTRadioAccessTechnologyCDMAEVDORevA,
                           CTRadioAccessTechnologyCDMAEVDORevB,
                           CTRadioAccessTechnologyeHRPD];
        _typeStrings4G = @[CTRadioAccessTechnologyLTE];
        
        _hostForPing = kNSDefaultHost;
        _hostForCheck = kNSDefaultHost;
        _autoCheckInterval = kNSDefaultCheckInterval;
        _pingTimeout = kNSDefaultPingTimeout;
        
        _vpnFlag = NO;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
        _localObserver = [[NetStatus_LocalConnection alloc] init];
        _pingHelper = [[NetStatus_PingHelper alloc] init];
        _pingChecker = [[NetStatus_PingHelper alloc] init];

    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.engine = nil;
    [self.localObserver stopNotifier];
    _localObserver = nil;
}

+ (instancetype)sharedInstance {
    static NetStatus_Reachability *reachability = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        reachability = [[NetStatus_Reachability alloc] init];
    });
    return reachability;
}

- (void)startNotifier {
    if (self.isNotifying) {
        return;
    }
    self.isNotifying = YES;
    self.previousStatus = NetStatusUnknown;
    
    NSDictionary *inputDic = @{kEventKeyID : @(NSEventLoad)};
    [self.engine receiveInput:inputDic];
    
    [self.localObserver startNotifier];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(localConnectionHandler:) name:kLocalConnectionChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(localConnectionHandler:) name:kLocalConnectionInitializedNotification object:nil];
    
    self.pingHelper.host = _hostForPing;
    self.pingHelper.timeout = self.pingTimeout;
    
    self.pingChecker.host = _hostForCheck;
    self.pingChecker.timeout = self.pingTimeout;
    
    [self autoCheckReachability];
}

- (void)stopNotifier {
    if (!self.isNotifying) {
        return;
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kLocalConnectionChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kLocalConnectionInitializedNotification object:nil];
    
    NSDictionary *inputDic = @{kEventKeyID : @(NSEventUnload)};
    [self.engine receiveInput:inputDic];
    [self.localObserver stopNotifier];
    self.isNotifying = NO;
}

- (void)reachabilityWithBlock:(void (^)(NSReachabilityStatus))asyncHandler {
    if ([self.localObserver currentLocalConnectionStatus] == NS_UnReachable) {
        if (asyncHandler != nil) {
            asyncHandler(NetStatusNotReachable);
        }
        return;
    }
    
    if ([self isVPNOn]) {
        NSReachabilityStatus status = [self currentReachabilityStatus];
        if (asyncHandler != nil) {
            asyncHandler(status);
        }
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    [self.pingHelper pingWithBlock:^(BOOL isSuccess) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (isSuccess) {
            NSReachabilityStatus status = [self currentReachabilityStatus];
            NSDictionary *inputDic = @{kEventKeyID : @(NSEventPingCallback), kEventKeyParam : @(YES)};
            NSInteger rtn = [strongSelf.engine receiveInput:inputDic];
            if (rtn == 0) {
                if ([strongSelf.engine isCurrentStateAvailable]) {
                    strongSelf.previousStatus = status;
                    __weak typeof(self) weakSelf = strongSelf;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        __strong typeof(weakSelf) strongSelf = weakSelf;
                        [[NSNotificationCenter defaultCenter] postNotificationName:kNSReachabilityChangedNotification object:strongSelf];
                    });
                }
            }
            
            if (asyncHandler != nil) {
                NSReachabilityStatus currentStatus = [strongSelf currentReachabilityStatus];
                asyncHandler(currentStatus);
            }
        } else {
            if ([self isVPNOn]) {
                //vpn on.ignore ping
            } else {
                dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1*NSEC_PER_SEC));
                __weak typeof(self) weakSelf = self;
                dispatch_after(time, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    __strong typeof(weakSelf) strongSelf = weakSelf;
                    [strongSelf makeDoubleCheck:asyncHandler];
                });
            }
        }
    }];
}

- (NSReachabilityStatus)currentReachabilityStatus {
    NSStateID currentID = self.engine.currentStateID;
    switch (currentID) {
        case NSStateUnReachable:
            return NetStatusNotReachable;
        case NSStateWiFi:
            return NetStatusViaWiFi;
        case NSStateWWAN:
            return NetStatusViaWWAN;
        case NSStateLoading:
            return (NSReachabilityStatus)(self.localObserver.currentLocalConnectionStatus);
            
        default:
            return NetStatusNotReachable;
    }
}

- (NSReachabilityStatus)previousReachabilityStatus {
    return self.previousStatus;
}

- (void)setHostForPing:(NSString *)hostForPing {
    _hostForPing = nil;
    _hostForPing = [hostForPing copy];
    
    self.pingHelper.host = _hostForPing;
}

- (void)setHostForCheck:(NSString *)hostForCheck {
    _hostForCheck = nil;
    _hostForCheck = [hostForCheck copy];
    
    self.pingChecker.host = _hostForCheck;
}

- (void)setPingTimeout:(NSTimeInterval)pingTimeout {
    _pingTimeout = pingTimeout;
    self.pingHelper.timeout = _pingTimeout;
    self.pingChecker.timeout = _pingTimeout;
}

- (NSWWANAccessType)currentWWANType {
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 7.0) {
        CTTelephonyNetworkInfo *teleInfo = [[CTTelephonyNetworkInfo alloc] init];
        NSString *accessString = teleInfo.currentRadioAccessTechnology;
        if ([accessString length] > 0) {
            return [self accessTypeForString:accessString];
        } else {
            return NSWWANTypeUnknown;
        }
    } else {
        return NSWWANTypeUnknown;
    }
}

- (BOOL)isVPNOn {
    BOOL flag = NO;
    NSString *version = [UIDevice currentDevice].systemVersion;
    if (version.doubleValue >= 9.0) {
        NSDictionary *dict = CFBridgingRelease(CFNetworkCopySystemProxySettings());
        NSArray *keys = [dict[@"__SCOPED__"] allKeys];
        for (NSString *key in keys) {
            if ([key rangeOfString:@"tap"].location != NSNotFound ||
                [key rangeOfString:@"tun"].location != NSNotFound ||
                [key rangeOfString:@"ipsec"].location != NSNotFound ||
                [key rangeOfString:@"ppp"].location != NSNotFound) {
                flag = YES;
                break;
            }
        }
    } else {
        struct ifaddrs *interfaces = NULL;
        struct ifaddrs *temp_addr = NULL;
        int success = 0;
        
        success = getifaddrs(&interfaces);
        if (success == 0) {
            temp_addr = interfaces;
            while (temp_addr != NULL) {
                NSString *string = [NSString stringWithFormat:@"%s", temp_addr->ifa_name];
                if ([string rangeOfString:@"tap"].location != NSNotFound ||
                    [string rangeOfString:@"tun"].location != NSNotFound ||
                    [string rangeOfString:@"ipsec"].location != NSNotFound ||
                    [string rangeOfString:@"ppp"].location != NSNotFound) {
                    flag = YES;
                    break;
                }
                temp_addr = temp_addr->ifa_next;
            }
        }
        
        freeifaddrs(interfaces);
    }
    
    if (_vpnFlag != flag) {
        _vpnFlag = flag;
        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            [[NSNotificationCenter defaultCenter] postNotificationName:kNSVPNChangedNotification object:strongSelf];
        });
    }
    return flag;
}

#pragma mark - notify event
- (void)appBecomeActive {
    if (self.isNotifying) {
        [self reachabilityWithBlock:nil];
    }
}

- (void)localConnectionHandler:(NSNotification *)notification {
    NetStatus_LocalConnection *connection = (NetStatus_LocalConnection *)notification.object;
    NS_LocalConnectionStatus lcStatus = [connection currentLocalConnectionStatus];
    NSReachabilityStatus status = [self currentReachabilityStatus];
    
    NSDictionary *inputDic = @{kEventKeyID : @(NSEventLocalConnectionCallback), kEventKeyParam : [self paramValueFromStatus:lcStatus]};
    NSInteger rtn = [self.engine receiveInput:inputDic];
    
    if (rtn == 0) {
        if ([self.engine isCurrentStateAvailable]) {
            self.previousStatus = status;
            if ([notification.name isEqualToString:kLocalConnectionChangedNotification]) {
                [[NSNotificationCenter defaultCenter] postNotificationName:kNSReachabilityChangedNotification object:self];
            }
            if (lcStatus != NS_UnReachable) {
                [self reachabilityWithBlock:nil];
            }
        }
    }
}

#pragma mark - private SEL
- (NSString *)paramValueFromStatus:(NS_LocalConnectionStatus)status {
    switch (status) {
        case NS_UnReachable:
            return kParamValueUnReachable;
        
        case NS_WiFi:
            return kParamValueWIFI;
        
        case NS_WWAN:
            return kParamValueWWAN;
            
        default:
            return @"";
    }
}

- (void)autoCheckReachability {
    if (!self.isNotifying) {
        return;
    }
    if (self.autoCheckInterval < kNSMinAutoCheckInterval) {
        self.autoCheckInterval = kNSMinAutoCheckInterval;
    }
    if (self.autoCheckInterval > kNSMaxAutoCheckInterval) {
        self.autoCheckInterval = kNSMaxAutoCheckInterval;
    }
    
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.autoCheckInterval*60*NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf reachabilityWithBlock:nil];
        [strongSelf autoCheckReachability];
    });
}

- (void)makeDoubleCheck:(void(^)(NSReachabilityStatus status))asyncHandler {
    __weak typeof(self) weakSelf = self;
    [self.pingChecker pingWithBlock:^(BOOL isSuccess) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        NSReachabilityStatus status = [strongSelf currentReachabilityStatus];
        
        NSDictionary *dic = @{kEventKeyID : @(NSEventPingCallback), kEventKeyParam : @(isSuccess)};
        NSInteger rtn = [strongSelf.engine receiveInput:dic];
        if (rtn == 0) {
            if ([strongSelf.engine isCurrentStateAvailable]) {
                strongSelf.previousStatus = status;
                __weak typeof(strongSelf) weakSelf = strongSelf;
                dispatch_async(dispatch_get_main_queue(), ^{
                    __strong typeof(weakSelf) strongSelf = weakSelf;
                    [[NSNotificationCenter defaultCenter] postNotificationName:kNSReachabilityChangedNotification object:strongSelf];
                });
            }
        }
        if (asyncHandler != nil) {
            NSReachabilityStatus status = [strongSelf currentReachabilityStatus];
            asyncHandler(status);
        }
    }];
}

- (NSWWANAccessType)accessTypeForString:(NSString *)accessString {
    if ([self.typeStrings4G containsObject:accessString]) {
        return NSWWANType4G;
    } else if ([self.typeStrings3G containsObject:accessString]) {
        return NSWWANType3G;
    } else if ([self.typeStrings2G containsObject:accessString]) {
        return NSWWANType2G;
    } else {
        return NSWWANTypeUnknown;
    }
}

@end
