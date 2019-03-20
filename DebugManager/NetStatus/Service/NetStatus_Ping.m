//
//  NetStatus_Ping.m
//  NetStatus_Demo
//
//  Created by TimmyYan on 2018/12/11.
//  Copyright © 2018年 com.zuoyebang. All rights reserved.
//

#include <netdb.h>

#import "NetStatus_Ping.h"
#import "NetStatus_Timer.h"

@interface NetStatus_Ping () {
    BOOL _isStartSuccess; //监测第一次ping是否成功
    int _sendCount;  //当前执行次数
    long _startTime; //每次执行的开始时间
    NSString *_hostAddress; //目标域名的IP地址
    BOOL _isLargePing;
    NSTimer *_timer;
}

@property (nonatomic, assign) NSUInteger maxCount_Ping;

@property (nonatomic, strong) NSSimplePing *pinger;

@end

@implementation NetStatus_Ping

- (void)dealloc {
    [self->_pinger stop];
}

- (void)stopPing {
    [self->_pinger stop];
    self.pinger = nil;
    _sendCount = self.maxCount_Ping + 1;
}

- (NSUInteger)maxCount_Ping {
    if (_maxCount_Ping == 0) {
        return 10;
    }
    return _maxCount_Ping;
}


/**
 调用pinger解析指定域名
 */
- (void)runWithHostName:(NSString *)hostName normalPing:(BOOL)normalPing {
    [self runWithHostName:hostName normalPing:normalPing maxCount:10];
}
- (void)runWithHostName:(NSString *)hostName normalPing:(BOOL)normalPing maxCount:(NSUInteger)maxCount{
    assert(self.pinger == nil);
    self.pinger = [[NSSimplePing alloc] initWithHostName:hostName];
    assert(self.pinger != nil);
    
    self.maxCount_Ping = maxCount;
    
    _isLargePing = !normalPing;
    self.pinger.delegate = self;
    [self.pinger start];
    
    //在当前线程一直执行
    _sendCount = 1;
    do {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    } while (self.pinger != nil || _sendCount <= self.maxCount_Ping);
}

/**
 发送ping数据，pinger会组装一个ICMP控制报文的数据发送过去
 */
- (void)sendPing {
    if (_timer) {
        [_timer invalidate];
    }
    if (_sendCount > self.maxCount_Ping) {
        _sendCount++;
        self.pinger = nil;
        if (self.delegate && [self.delegate respondsToSelector:@selector(netPingDidEnd)]) {
            [self.delegate netPingDidEnd];
        }
    } else {
        assert(self.pinger != nil);
        _sendCount++;
        _startTime = [NetStatus_Timer getMicroSeconds];
        if (_isLargePing) {
            NSString *testStr = @"";
            for (int i = 0; i < 408; i++) {
                testStr = [testStr stringByAppendingString:@"abcdefghi "];
            }
            testStr = [testStr stringByAppendingString:@"abcdefgh"];
            NSData *data = [testStr dataUsingEncoding:NSASCIIStringEncoding];
            [self.pinger sendPingWithData:data];
        } else {
            [self.pinger sendPingWithData:nil];
        }
        //3s超时后，重发机制
        _timer = [NSTimer scheduledTimerWithTimeInterval:3.0 target:self selector:@selector(pingTimeout:) userInfo:[NSNumber numberWithInt:_sendCount] repeats:NO];
    }
}

- (void)pingTimeout:(NSTimer *)index {
    if ([[index userInfo] intValue] == _sendCount && _sendCount <= self.maxCount_Ping + 1 && _sendCount > 1) {
        NSString *timeoutLog = [NSString stringWithFormat:@"ping: cannot resolve %@: TimeOut", _hostAddress];
        if (self.delegate && [self.delegate respondsToSelector:@selector(appendPingLog:)]) {
            [self.delegate appendPingLog:timeoutLog];
        }
        [self sendPing];
    }
}

/**
 * 将ping接收的数据转换成ip地址
 * @param address 接受的ping数据
 */
-(NSString *)displayAddressForAddress:(NSData *)address
{
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
    
    // Handle DNS errors as a special case.
    
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
    
    // Otherwise try various properties of the error object.
    
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

#pragma mark - PingDelegate
/**
 套接口开启之后发送ping数据，并开启一个timer（1s间隔发送数据）
 */
- (void)simplePing:(NSSimplePing *)pinger didStartWithAddress:(NSData *)address {
#pragma unused(pinger)
    assert(pinger == self.pinger);
    assert(address != nil);
    _hostAddress = [self displayAddressForAddress:address];
    //send the first ping straight away
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
    NSString *failCreateLog = [NSString stringWithFormat:@"#%u try create failed: %@", _sendCount, [self shortErrorFromError:error]];
    if (self.delegate && [self.delegate respondsToSelector:@selector(appendPingLog:)]) {
        [self.delegate appendPingLog:failCreateLog];
    }
    
    //如果不是创建套接字失败，都是发送数据过程中的错误，可以继续try发送数据
    if (_isStartSuccess) {
        [self sendPing];
    } else {
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
    NSString *sendFailLog =
    [NSString stringWithFormat:@"#%u send failed: %@",sequenceNumber,
     [self shortErrorFromError:error]];
    //记录
    if (self.delegate && [self.delegate respondsToSelector:@selector(appendPingLog:)]) {
        [self.delegate appendPingLog:sendFailLog];
    }
    
    [self sendPing];
}

/**
 成功接收到PingResponse数据
 */
- (void)simplePing:(NSSimplePing *)pinger didReceivePingResponsePacket:(NSData *)packet sequenceNumber:(uint16_t)sequenceNumber {
#pragma unused(pinger)
    assert(pinger == self.pinger);
#pragma unused(packet)
    //由于IPV6在IPheader中不返回TTL数据，所以这里不返回TTL，改为返回Type
    NSString *icmpReplyType = [NSString stringWithFormat:@"%@", [NSSimplePing icmpInPacket:packet]->type == 129 ? @"ICMPv6TypeEchoReply" : @"ICMPv4TypeEchoReply"];
    NSString *successLog = [NSString stringWithFormat:@"%lu bytes from %@ icmp_seq=#%u type=%@ time=%ldms", (unsigned long)[packet length], _hostAddress, sequenceNumber, icmpReplyType, [NetStatus_Timer computeDurationSince:_startTime] / 1000];
    //记录ping成功的数据
    if (self.delegate && [self.delegate respondsToSelector:@selector(appendPingLog:)]) {
        [self.delegate appendPingLog:successLog];
    }
    
    [self sendPing];
}

/**
 接收到错误的pingResponse数据
 */
- (void)simplePing:(NSSimplePing *)pinger didReceiveUnexpectedPacket:(NSData *)packet {
    const ICMPHeader *icmpPtr;
    if (self.pinger && pinger == self.pinger) {
        icmpPtr = [NSSimplePing icmpInPacket:packet];
        NSString *errorLog = @"";
        if (icmpPtr != NULL) {
            errorLog = [NSString
                        stringWithFormat:@"#%u unexpected ICMP type=%u, code=%u, identifier=%u",
                        (unsigned int)OSSwapBigToHostInt16(icmpPtr->sequenceNumber),
                        (unsigned int)icmpPtr->type, (unsigned int)icmpPtr->code,
                        (unsigned int)OSSwapBigToHostInt16(icmpPtr->identifier)];
        } else {
            errorLog = [NSString stringWithFormat:@"#%u try unexpected packet size=%zu", _sendCount,
                        (size_t)[packet length]];
        }
        //记录
        if (self.delegate && [self.delegate respondsToSelector:@selector(appendPingLog:)]) {
            [self.delegate appendPingLog:errorLog];
        }
    }
    
    //当检测到错误数据的时候，再次发送
    [self sendPing];
}

@end
