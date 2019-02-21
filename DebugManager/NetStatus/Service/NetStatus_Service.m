//
//  NetStatus_Service.m
//  NetStatus_Demo
//
//  Created by TimmyYan on 2018/12/7.
//  Copyright © 2018年 com.zuoyebang. All rights reserved.
//

#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <sys/sysctl.h>
#import <UIKit/UIKit.h>

#import "NetStatus_Service.h"
#import "NetStatus_GetAddress.h"
#import "NetStatus_Timer.h"
#import "NetStatus_Connect.h"
#import "NetStatus_Ping.h"
#import "NetStatus_TraceRoute.h"
#import "NetStatus_WiFiInfo.h"

static NSString *const kPingOpenServerIP = @"61.135.169.121";//默认ping 百度的ip
static NSString *const kCheckOutIPURL = @"";

@interface NetStatus_Service () <NetStatus_PingDelegate, NetStatus_ConnectDelegate, NetStatus_TraceRouteDelegate>

@property (nonatomic, strong) NSString *appName;
@property (nonatomic, strong) NSString *appVersion;
@property (nonatomic, strong) NSString *uid;
@property (nonatomic, strong) NSString *deviceId;


//运营商相关
@property (nonatomic, strong) NSString *carrierName;
@property (nonatomic, strong) NSString *ISOCountryCode;
@property (nonatomic, strong) NSString *MobileCountryCode;
@property (nonatomic, strong) NSString *MobileNetCode;

//协议相关
@property (nonatomic, strong) NSString *localIp;
@property (nonatomic, strong) NSString *gatewayIp;
@property (nonatomic, strong) NSArray *dnsServers;
@property (nonatomic, strong) NSArray *hostAddress;

@property (nonatomic, strong) NSMutableString *logInfo;

@property (nonatomic, assign) NetworkType curNetType;
@property (nonatomic, strong) NetStatus_Connect *tcpConnect;
@property (nonatomic, strong) NetStatus_Ping *netPinger;
@property (nonatomic, strong) NetStatus_TraceRoute *traceRouter;

@property (nonatomic, assign) BOOL isRunning;
@property (nonatomic, assign) BOOL connectSuccess;


@end

@implementation NetStatus_Service

#pragma mark - public SEL
- (instancetype)initWithAppName:(NSString *)appName appVersion:(NSString *)appVersion uid:(NSString *)uid deviceId:(NSString *)deviceId dormain:(NSString *)dormain {
    self = [super init];
    if (self) {
        _appName = appName;
        _appVersion = appVersion;
        _uid = uid;
        _deviceId = deviceId;
        _dormain = dormain;
        
        _logInfo = [[NSMutableString alloc] init];
        _isRunning = NO;
    }
    return self;
}

- (void)startNetService {
    if (!_dormain || [_dormain isEqualToString:@""]) {
        return;
    }
    _isRunning = YES;
    [_logInfo setString:@""];
    [self recordStepInfo:@"开始诊断..."];
    [self recordStepInfo:[@"\n当前时间为: " stringByAppendingString:[self getCurrentTimes]]];
    [self recordCurrentAppVersion];
    [self recordLocalNetEnvironment];
    
    //未联网不进行任何检测
    if (_curNetType == 0) {
        _isRunning = NO;
        [self recordStepInfo:[NSString stringWithFormat:@"\n当前主机未联网，请检查网络! "]];
        [self recordStepInfo:@"\n网络诊断结束\n"];
        if (self.delegate && [self.delegate respondsToSelector:@selector(netServiceDidEnd:)]) {
            [self.delegate netServiceDidEnd:_logInfo];
        }
        return;
    }
    
//    if (_isRunning) {
//        [self recordOutIPInfo];
//    }
    
    if (_isRunning) {
        //connect诊断，同步过程，如果TCP无法连接，检查本地网络环境
        _connectSuccess = NO;
        [self recordStepInfo:@"\n开始TCP连接测试..."];
        if ([_hostAddress count] > 0) {
            self.tcpConnect = [[NetStatus_Connect alloc] init];
            self.tcpConnect.delegate = self;
            for (int i = 0; i < [_hostAddress count]; i++) {
                [_tcpConnect runWithHostAddress:[_hostAddress objectAtIndex:i] port:80];
            }
        } else {
            [self recordStepInfo:@"DNS解析失败，主机地址不可达"];
        }
        if (_isRunning) {
            [self pingService:!_connectSuccess];
        }
    }
    
    if (_isRunning) {
        //开始诊断traceRoute
        [self recordStepInfo:@"\n开始traceRoute..."];
        self.traceRouter = [[NetStatus_TraceRoute alloc] initWithMaxTTL:TRACEROUTE_MAX_TTL timeout:TRACEROUTE_TIMEOUT maxAttempts:TRACEROUTE_ATTEMPTS port:TRACEROUTE_PORT];
        self.traceRouter.delegate = self;
        if (_traceRouter) {
            [NSThread detachNewThreadSelector:@selector(doTraceRoute:) toTarget:self.traceRouter withObject:self.dormain];
//            [self.traceRouter doTraceRoute:self.dormain];
        }
    }
    
}

- (void)stopNetService {
    if (_isRunning) {
        if (_tcpConnect) {
            [_tcpConnect stopConnect];
            _tcpConnect = nil;
        }
        
        if (_netPinger) {
            [_netPinger stopPing];
            _netPinger = nil;
        }
        
        if (_traceRouter) {
            [_traceRouter stopTrace];
            _traceRouter = nil;
        }
        
        _isRunning = NO;
    }
}

- (void)printNetServiceLogInfo {
    NSLog(@"\n%@\n", _logInfo);
}

#pragma mark - private SEL
//构建ping列表并进行ping诊断
- (void)pingService:(BOOL)pingLocal {
    //诊断ping信息，同步过程
    NSMutableArray *pingAdd = [[NSMutableArray alloc] init];
    NSMutableArray *pingInfo = [[NSMutableArray alloc] init];
    if (pingLocal) {
        [pingAdd addObject:@"127.0.0.1"];
        [pingInfo addObject:@"本机"];
        [pingAdd addObject:_localIp];
        [pingInfo addObject:@"本机IP"];
        if (_gatewayIp && ![_gatewayIp isEqualToString:@""]) {
            [pingAdd addObject:_gatewayIp];
            [pingInfo addObject:@"本地网关"];
        }
        if ([_dnsServers count] > 0) {
            [pingAdd addObject:[_dnsServers objectAtIndex:0]];
            [pingInfo addObject:@"DNS服务器"];
        }
    }
    
    //不管服务器解析DNS是否到达，均需要ping指定的ip地址
    if ([_localIp rangeOfString:@":"].location == NSNotFound) {
        [pingAdd addObject:kPingOpenServerIP.length > 0 ? kPingOpenServerIP : _hostAddress.count > 0 ? [_hostAddress firstObject] : @""];
        [pingInfo addObject:@"开发服务器"];
    }
    
    [self recordStepInfo:@"\n开始ping..."];
    _netPinger = [[NetStatus_Ping alloc] init];
    _netPinger.delegate = self;
    for (int i = 0; i < [pingAdd count]; i++) {
        [self recordStepInfo:[NSString stringWithFormat:@"ping: %@ %@ ...", [pingInfo objectAtIndex:i], [pingAdd objectAtIndex:i]]];
        if ([[pingAdd objectAtIndex:i] isEqualToString:kPingOpenServerIP]) {
            [_netPinger runWithHostName:[pingAdd objectAtIndex:i] normalPing:YES];
        } else {
            [_netPinger runWithHostName:[pingAdd objectAtIndex:i] normalPing:YES];
        }
    }
    
}

//使用接口获取用户的出口IP和DNS信息
- (void)recordOutIPInfo {
    [self recordStepInfo:@"\n开始获取运营商信息..."];
    //初始化请求
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:kCheckOutIPURL] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:20];
    __weak typeof(self) wSelf = self;
    [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        __strong typeof(wSelf) sSelf = wSelf;
        if (error != nil) {
            [sSelf recordStepInfo:@"\n获取超时"];
            return;
        }
        NSString *dataStr = [[NSString alloc] initWithData:data encoding:0x80000632];
        [sSelf recordStepInfo:[NSString stringWithFormat:@"%@返回的response为:\n%@\n Data:%@", kCheckOutIPURL, response, dataStr]];
    }];
}

/**
 获取本地网络环境相关信息
 */
- (void)recordLocalNetEnvironment {
    [self recordStepInfo:[NSString stringWithFormat:@"\n\n诊断域名 %@...\n", _dormain]];
    //根据statusBar判断是否联网及获取网络类型
    NSArray *typeArr = [NSArray arrayWithObjects:@"2G", @"3G", @"4G", @"5G", @"WiFi", nil];
    _curNetType = [NetStatus_GetAddress getNetworkTypeFromStatusBar];
    if (_curNetType == 0) {
        [self recordStepInfo:[NSString stringWithFormat:@"当前是否联网: 未联网"]];
    } else {
        [self recordStepInfo:[NSString stringWithFormat:@"当前是否联网: 已联网"]];
        if (_curNetType > 0 && _curNetType < 6) {
            [self recordStepInfo:[NSString stringWithFormat:@"当前联网类型: %@", [typeArr objectAtIndex:_curNetType - 1]]];
        }
    }
    
    //WiFi路由器相关信息
    if (_curNetType == NetworkType_WiFi) {
        NSString *wifiSSID = [NetStatus_WiFiInfo getCurrentWiFiName];
        [self recordStepInfo:[NSString stringWithFormat:@"当前连接WiFi名称: %@", wifiSSID]];
        NSArray *onlineDevices = [NetStatus_WiFiInfo getOnlineDevicesInfo];
        [self recordStepInfo:[NSString stringWithFormat:@"当前WiFi在线设备数量: %ld台", onlineDevices.count]];
        if (onlineDevices.count > 0) {
            [self recordStepInfo:@"在线设备列表信息如下："];
            for (NSString  *str in onlineDevices) {
                NSInteger i = 1;
                [self recordStepInfo:[NSString stringWithFormat:@"设备%ld         IP:%@", i, str]];
                i++;
            }
        }
    }
    
    //本地ip信息
    _localIp = [NetStatus_GetAddress deviceIPAdress];
    [self recordStepInfo:[NSString stringWithFormat:@"当前本地IP: %@", _localIp]];
    
    if (_curNetType == NetworkType_WiFi) {
        _gatewayIp = [NetStatus_GetAddress getGatewayIPAddress];
        [self recordStepInfo:[NSString stringWithFormat:@"本地网关: %@", _gatewayIp]];
    } else {
        _gatewayIp = @"";
    }
    
    //DNS服务器
    _dnsServers = [NSArray arrayWithArray:[NetStatus_GetAddress outPutDNSServers]];
    [self recordStepInfo:[NSString stringWithFormat:@"本地DNS: %@", [_dnsServers componentsJoinedByString:@", "]]];
    
    [self recordStepInfo:[NSString stringWithFormat:@"远端域名: %@", _dormain]];
    
    //host地址IP列表
    long time_start = [NetStatus_Timer getMicroSeconds];
    _hostAddress = [NSArray arrayWithArray:[NetStatus_GetAddress getDNSWithDormain:_dormain]];
    long time_duration = [NetStatus_Timer computeDurationSince:time_start] / 1000;
    if ([_hostAddress count] == 0) {
        [self recordStepInfo:[NSString stringWithFormat:@"DNS解析结果: 解析失败"]];
    } else {
        [self recordStepInfo:[NSString stringWithFormat:@"DNS解析结果: %@ (%ldms)", [_hostAddress componentsJoinedByString:@", "], time_duration]];
    }
    
}

/**
 获取APP相关信息
 */
- (void)recordCurrentAppVersion {
    //输出应用版本信息和uid
    NSDictionary *dicBundle = [[NSBundle mainBundle] infoDictionary];
    if (!_appName || [_appName isEqualToString:@""]) {
        _appName = [dicBundle objectForKey:@"CFBundleDisplayName"];
    }
    [self recordStepInfo:[NSString stringWithFormat:@"应用名称: %@", _appName]];
    
    if (!_appVersion || [_appVersion isEqualToString:@""]) {
        _appVersion = [dicBundle objectForKey:@"CFBundleShortVersionString"];
    }
    [self recordStepInfo:[NSString stringWithFormat:@"应用版本: %@", _appVersion]];
    
    [self recordStepInfo:[NSString stringWithFormat:@"用户id: %@", _uid]];
    
    //输出机器信息
    UIDevice *device = [UIDevice currentDevice];
    [self recordStepInfo:[NSString stringWithFormat:@"设备型号: %@", [self machineModel]]];
    [self recordStepInfo:[NSString stringWithFormat:@"系统版本: %@ %@", [device systemName], [device systemVersion]]];
    if (!_deviceId || [_deviceId isEqualToString:@""]) {
        _deviceId = [self uniqueAppInstanceIdentifier];
    }
    [self recordStepInfo:[NSString stringWithFormat:@"设备ID: %@", _deviceId]];
    
    //运营商信息
    if (!_carrierName || [_carrierName isEqualToString:@""]) {
        CTTelephonyNetworkInfo *netInfo = [[CTTelephonyNetworkInfo alloc] init];
        CTCarrier *carrier = [netInfo subscriberCellularProvider];
        if (carrier != NULL) {
            _carrierName = [carrier carrierName];
            _ISOCountryCode = [carrier isoCountryCode];
            _MobileCountryCode = [carrier mobileCountryCode];
            _MobileNetCode = [carrier mobileNetworkCode];
        } else {
            _carrierName = @"";
            _ISOCountryCode = @"";
            _MobileCountryCode = @"";
            _MobileNetCode = @"";
        }
    }
    [self recordStepInfo:[NSString stringWithFormat:@"运营商: %@", _carrierName]];
    [self recordStepInfo:[NSString stringWithFormat:@"ISOCountryCode: %@", _ISOCountryCode]];
    [self recordStepInfo:[NSString stringWithFormat:@"MobileCountryCode: %@", _MobileCountryCode]];
    [self recordStepInfo:[NSString stringWithFormat:@"MobileNetworkCode: %@", _MobileNetCode]];
}

- (void)recordStepInfo:(NSString *)stepInfo {
    if (stepInfo == nil) {
        stepInfo = @"";
    }
    [_logInfo appendString:stepInfo];
    [_logInfo appendString:@"\n"];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(netServiceStepInfo:)]) {
        if ([NSThread isMainThread]) {
            [self.delegate netServiceStepInfo:[NSString stringWithFormat:@"%@\n", stepInfo]];
        } else {
            __weak typeof(self) wSelf = self;
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong typeof(wSelf) sSelf = wSelf;
                [sSelf.delegate netServiceStepInfo:[NSString stringWithFormat:@"%@\n", stepInfo]];
            });
        }
    }
}


/**
 获取设备型号

 @return 返回设备型号ID，需匹配找到具体设备型号
 */
- (NSString *)machineModel {
    static dispatch_once_t one;
    static NSString *model;
    dispatch_once(&one, ^{
        size_t size;
        sysctlbyname("hw.machine", NULL, &size, NULL, 0);
        char *machine = malloc(size);
        sysctlbyname("hw.machine", machine, &size, NULL, 0);
        model = [NSString stringWithUTF8String:machine];
        free(machine);
    });
    return model;
}

/**
 获取deviceID
 */
- (NSString *)uniqueAppInstanceIdentifier {
    NSString *app_uuid = @"";
    CFUUIDRef uuidRef = CFUUIDCreate(kCFAllocatorDefault);
    CFStringRef uuidString = CFUUIDCreateString(kCFAllocatorDefault, uuidRef);
    app_uuid = [NSString stringWithString:(__bridge NSString *)uuidString];
    CFRelease(uuidString);
    CFRelease(uuidRef);
    return app_uuid;
}

/**
 获取当前系统时间

 @return 返回时间字符串
 */
- (NSString *)getCurrentTimes {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"YYYY-MM-dd HH:mm:ss"];
    [formatter setTimeZone:[NSTimeZone systemTimeZone]];
    NSString *currentTimeString = [formatter stringFromDate:[NSDate date]];
    return currentTimeString;
}

#pragma mark - ConnectDelegate
- (void)appendSocketLog:(NSString *)socketLog {
    [self recordStepInfo:socketLog];
}
- (void)connectDidEnd:(BOOL)success {
    if (success) {
        _connectSuccess = YES;
    }
}

#pragma mark - PingDelegate
- (void)appendPingLog:(NSString *)pingLog {
    [self recordStepInfo:pingLog];
}
- (void)netPingDidEnd {
    NSLog(@"Ping is over!");
}

#pragma mark - TraceRouteDelegate
- (void)appendRouteLog:(NSString *)routeLog {
    [self recordStepInfo:routeLog];
}
- (void)traceRouteDidEnd {
    _isRunning = NO;
    [self recordStepInfo:@"\n网络诊断结束\n"];
    [self recordStepInfo:[[@"\n当前时间为: " stringByAppendingString:[self getCurrentTimes]] stringByAppendingString:@"\n"]];
    if (self.delegate && [self.delegate respondsToSelector:@selector(netServiceDidEnd:)]) {
        [self.delegate netServiceDidEnd:_logInfo];
    }
}

@end
