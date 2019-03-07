//
//  NetStatus_WiFiInfo.m
//  FastDevTools
//
//  Created by TimmyYan on 2019/2/21.
//

#import "NetStatus_WiFiInfo.h"
#import <SystemConfiguration/CaptiveNetwork.h>
#import "NetStatus_GetAddress.h"
#import "NetStatus_Ping.h"

#import "NSSimplePing.h"
#include <netdb.h>

/*********************************************************************************************************************/

static NSInteger const MAXCount = 2;//遇到错误或者超时，自动重试一次

//协议
@protocol NetStatus_WiFiPingDelegate <NSObject>
@optional
- (void)pingOccusError:(NSString *)errMsg;
- (void)onlineDeviceHosts:(NSArray *)hosts;
- (void)pingDidEnd;

@end


@interface NetStatus_WiFiPing () <NSSimplePingDelegate>

@property (nonatomic, weak) id <NetStatus_WiFiPingDelegate> delegate;

@property (nonatomic, strong) NSSimplePing *pinger;
@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic, assign) int sendCount;
@property (nonatomic, strong) NSString *hostAddress;//目标域名IP地址
@property (nonatomic, assign) BOOL isStartSuccess;//监测第一次ping是否成功

@property (nonatomic, strong) NSMutableArray *onlineHosts;//能ping通的host集合

@end

@implementation NetStatus_WiFiPing

- (void)dealloc {
    [self->_pinger stop];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.onlineHosts = @[].mutableCopy;
    }
    return self;
}

- (void)startPingWithHost:(NSString *)host{
    self.pinger = [[NSSimplePing alloc] initWithHostName:host];
    self.pinger.delegate = self;
    self.pinger.addressStyle = NSSimplePingAddressStyleICMPv4;
    [self.pinger start];
    
    //在当前线程一直执行
    _sendCount = 1;
    do {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantPast]];
    } while (self.pinger != nil || _sendCount <= MAXCount);

    
}

- (void)stopPing {
    [self->_pinger stop];
    self.pinger = nil;
    _sendCount = MAXCount + 1;
}
#pragma mark - NSSimplePingDelegate
/**
 套接口开启之后发送ping数据，并开启一个timer（1s间隔发送数据）
 */
- (void)simplePing:(NSSimplePing *)pinger didStartWithAddress:(NSData *)address {
#pragma unused (pinger)
    assert(pinger == self.pinger);
    assert(address != nil);
    _hostAddress = [self displayAddressForAddress:address];
    _isStartSuccess = YES;
    [self sendPing];
}

/**
 ping命令发生错误之后，立即停止timer和线程操作
 */
- (void)simplePing:(NSSimplePing *)pinger didFailWithError:(NSError *)error {
#pragma unused(pinger)
    assert(pinger == self.pinger);
#pragma unused(error)
 
    //如果不是创建套接字失败，都是发送数据过程中的错误，可以继续try发送数据
    if (_isStartSuccess) {
        [self sendPing];
    } else {
        NSString *failCreateLog = [NSString stringWithFormat:@"#%u try create failed: %@", _sendCount, [self shortErrorFromError:error]];
        if (self.delegate && [self.delegate respondsToSelector:@selector(pingOccusError:)]) {
            [self.delegate pingOccusError:failCreateLog];
        }
        [self stopPing];
    }
}
/**
 发送ping数据成功
 */
- (void)simplePing:(NSSimplePing *)pinger didSendPacket:(NSData *)packet sequenceNumber:(uint16_t)sequenceNumber {
#pragma unused(pinger)
    assert(pinger == self.pinger);
#pragma unused(packet)
    NSLog(@"#%u sent success", sequenceNumber);
}

/**
 发送ping数据失败
 */
- (void)simplePing:(NSSimplePing *)pinger didFailToSendPacket:(NSData *)packet sequenceNumber:(uint16_t)sequenceNumber error:(NSError *)error {
#pragma unused(pinger)
    assert(pinger == self.pinger);
#pragma unused(packet)
#pragma unused(error)
    
    [self sendPing];
}

/**
 成功接收到PingResponse数据
 */
- (void)simplePing:(NSSimplePing *)pinger didReceivePingResponsePacket:(NSData *)packet sequenceNumber:(uint16_t)sequenceNumber {
#pragma unused(pinger)
    assert(pinger == self.pinger);
#pragma unused(packet)
    [self.onlineHosts addObject:_hostAddress];
    if (self.delegate && [self.delegate respondsToSelector:@selector(onlineDeviceHosts:)]) {
        [self.delegate onlineDeviceHosts:self.onlineHosts];
    }
    
    [self stopPing];
}

/**
 接收到错误的pingResponse数据
 */
- (void)simplePing:(NSSimplePing *)pinger didReceiveUnexpectedPacket:(NSData *)packet {
    //当检测到错误数据的时候，再次发送
    [self sendPing];
}
#pragma mark - tools
/**
 * 将ping接收的数据转换成ip地址
 * @param address 接受的ping数据
 */
-(NSString *)displayAddressForAddress:(NSData *)address {
    int err;
    NSString *result;
    char hostStr[NI_MAXHOST];
    
    result = nil;
    
    if (address != nil) {
        err = getnameinfo([address bytes], (socklen_t)[address length], hostStr, sizeof(hostStr),
                          NULL, 0, NI_NUMERICHOST);
        if (err == 0) {
            result = [NSString stringWithCString:hostStr encoding:NSASCIIStringEncoding];
            assert(result != nil);
        }
    }
    
    return result;
}

/**
 发送ping数据，pinger会组装一个ICMP控制报文的数据发送过去
 */
- (void)sendPing {
    if (_timer) {
        [_timer invalidate];
    }
    if (_sendCount > MAXCount) {
        _sendCount++;
        self.pinger = nil;
        if (self.delegate && [self.delegate respondsToSelector:@selector(pingDidEnd)]) {
            [self.delegate pingDidEnd];
        }
    } else {
        assert(self.pinger != nil);
        _sendCount++;
        [self.pinger sendPingWithData:nil];
        //100ms超时后，重发机制
        _timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(pingTimeout:) userInfo:[NSNumber numberWithInt:_sendCount] repeats:NO];
    }
}

- (void)pingTimeout:(NSTimer *)index {
    if ([[index userInfo] intValue] == _sendCount && _sendCount <= MAXCount + 1 && _sendCount > 1) {
        [self sendPing];
    }
}

/*
 * 解析错误数据并翻译
 */
- (NSString *)shortErrorFromError:(NSError *)error {
    NSString *result;
    NSNumber *failureNum;
    int failure;
    const char *failureStr;
    
    assert(error != nil);
    
    result = nil;
    
    //处理DNS错误
    if ([[error domain] isEqual:(NSString *)kCFErrorDomainCFNetwork] &&
        ([error code] == kCFHostErrorUnknown)) {
        failureNum = [[error userInfo] objectForKey:(id)kCFGetAddrInfoFailureKey];
        if ([failureNum isKindOfClass:[NSNumber class]]) {
            failure = [failureNum intValue];
            if (failure != 0) {
                failureStr = gai_strerror(failure);
                if (failureStr != NULL) {
                    result = [NSString stringWithUTF8String:failureStr];
                    assert(result != nil);
                }
            }
        }
    }
    
    //尝试错误对象的各种属性
    if (result == nil) {
        result = [error localizedFailureReason];
    }
    if (result == nil) {
        result = [error localizedDescription];
    }
    if (result == nil) {
        result = [error description];
    }
    assert(result != nil);
    return result;
}

@end








/*********************************************************************************************************************/

@interface NetStatus_WiFiInfo () <NetStatus_WiFiPingDelegate>

@property (nonatomic, strong) NetStatus_WiFiPing *netPinger;

@property (nonatomic, copy) NetStatus_OnlineHostsBlock onlineHostsBlock;


@end

@implementation NetStatus_WiFiInfo

- (instancetype)init {
    self = [super init];
    if (self) {
        self.onlineHostsBlock = [self.onlineHostsBlock copy];
    }
    return self;
}

//获取当前设备连接WiFi信息
+ (NSDictionary *)getCurrentWiFiInfo {
    CFArrayRef arrRef = CNCopySupportedInterfaces();
    if (arrRef) {
        CFDictionaryRef dictRef = CNCopyCurrentNetworkInfo(CFArrayGetValueAtIndex(arrRef, 0));
        if (dictRef) {
            NSDictionary *dict = (NSDictionary *)CFBridgingRelease(dictRef);
            return dict;
        }
    }
    return nil;
}

+ (NSString *)getCurrentWiFiName {
    return [[self getCurrentWiFiInfo] valueForKey:@"SSID"];
}

+ (NSString *)getCurrentWiFiMACAdress {
    return [[self getCurrentWiFiInfo] valueForKey:@"BSSID"];
}

//计算需要ping的ip域
- (NSArray <__kindof NSString *> *)calculateIPThreshod {
    NSMutableArray *ipArr = @[].mutableCopy;
    NSString *gatewayAddress = [NetStatus_GetAddress getGatewayIPAddress];
    NSString *subnetMask = [NetStatus_GetAddress getSubnetMask];
    NSString *curDeviceIP = [NetStatus_GetAddress deviceIPAdress];
    if ([gatewayAddress rangeOfString:@":"].location == NSNotFound && [curDeviceIP rangeOfString:@":"].location == NSNotFound) {
        //IPV4
        NSInteger flag = 0;
        NSArray *subnetArr = [subnetMask componentsSeparatedByString:@"."];
        for (int i = 0; i < 4; i++) {
            if ([[subnetArr objectAtIndex:i] isEqualToString:@"0"]) {
                flag = i;
            }
        }
        
        NSArray *gatewayArr = [gatewayAddress componentsSeparatedByString:@"."];
        if (flag == 3) {
            for (int n = 0; n <= 255; n++) {
                NSString *ip = [NSString stringWithFormat:@"%@.%@.%@.%d", gatewayArr[0], gatewayArr[1], gatewayArr[2], n];
                [ipArr addObject:ip];
            }
        } else if (flag == 2) {
            for (int m = 0; m <= 255 ; m++) {
                for (int k = 0; k <= 255; k++) {
                    NSString *ip_ = [NSString stringWithFormat:@"%@.%@.%d.%d", gatewayArr[0], gatewayArr[1], m, k];
                    [ipArr addObject:ip_];
                }
            }
        } else {
            NSLog(@"子网掩码为：255.0.0.0 几乎不可能出现且耗时太长，暂不处理");
        }
        
    }
    return ipArr;
}

- (void)fetchOnlineDevicesHosts:(NetStatus_OnlineHostsBlock)onlineHostsBlock {
    self.onlineHostsBlock = [onlineHostsBlock copy];
    NSArray *ipArr = [self calculateIPThreshod];
    
    self.netPinger = [[NetStatus_WiFiPing alloc] init];
    self.netPinger.delegate = self;

    for (NSString *ip in ipArr) {
        [self.netPinger startPingWithHost:ip];
    }


    
}

#pragma mark - NetStatus_WiFiPingDelegate
- (void)onlineDeviceHosts:(NSArray *)hosts {
    NSLog(@"在线设备IP为：%@", hosts);
    if (self.onlineHostsBlock) {
        self.onlineHostsBlock(hosts);
    }
}


@end
