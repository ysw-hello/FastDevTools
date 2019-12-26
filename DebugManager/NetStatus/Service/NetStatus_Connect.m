//
//  NetStatus_Connect.m
//  NetStatus_Demo
//
//  Created by TimmyYan on 2018/12/10.
//  Copyright © 2018年 com.ysw. All rights reserved.
//

#import <netinet/in.h>
#import <arpa/inet.h>
#import <unistd.h>

#import "NetStatus_Connect.h"
#import "NetStatus_Timer.h"

#define MAXCOUNT_CONNECT 5

@interface NetStatus_Connect () {
    BOOL _isExistSuccess;//监测是否有connect成功
    int _connectCount; //当前执行次数
    int _tcpPort; //执行端口
    NSString *_hostAddress; //目标域名的IP地址
    BOOL _isIPV6;
    NSString *_resultLog;
    NSInteger _sumTime;
    CFSocketRef _socket;
}
@property (nonatomic, assign) long _startTime; //每次执行的开始时间

@end


@implementation NetStatus_Connect

- (void)stopConnect {
    _connectCount = MAXCOUNT_CONNECT + 1;
}

- (void)runWithHostAddress:(NSString *)hostAddress port:(int)port {
    _hostAddress = hostAddress;
    _isIPV6 = [_hostAddress rangeOfString:@":"].location == NSNotFound ? NO :YES;
    _tcpPort = port;
    _isExistSuccess = FALSE;
    _connectCount = 0;
    _sumTime = 0;
    _resultLog = @"";
    if (self.delegate && [self.delegate respondsToSelector:@selector(appendSocketLog:)]) {
        [self.delegate appendSocketLog:[NSString stringWithFormat:@"connect to host %@ ...", _hostAddress]];
    }
    __startTime = [NetStatus_Timer getMicroSeconds];
    [self connect];
    do {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    } while (_connectCount < MAXCOUNT_CONNECT);
}

- (void)connect {
    NSData *addrData = nil;
    //设置地址
    if (!_isIPV6) {
        struct sockaddr_in nativeAddr4;
        memset(&nativeAddr4, 0, sizeof(nativeAddr4));
        nativeAddr4.sin_len = sizeof(nativeAddr4);
        nativeAddr4.sin_family = AF_INET;
        nativeAddr4.sin_port = htons(_tcpPort);
        inet_pton(AF_INET, _hostAddress.UTF8String, &nativeAddr4.sin_addr.s_addr);
        addrData = [NSData dataWithBytes:&nativeAddr4 length:sizeof(nativeAddr4)];
    } else {
        struct sockaddr_in6 nativeAddr6;
        memset(&nativeAddr6, 0, sizeof(nativeAddr6));
        nativeAddr6.sin6_len = sizeof(nativeAddr6);
        nativeAddr6.sin6_family = AF_INET6;
        nativeAddr6.sin6_port = htons(_tcpPort);
        inet_pton(AF_INET6, _hostAddress.UTF8String, &nativeAddr6.sin6_addr);
        addrData = [NSData dataWithBytes:&nativeAddr6 length:sizeof(nativeAddr6)];
    }
    
    if (addrData != nil) {
        [self connectWithAddress:addrData];
    }
}

- (void)connectWithAddress:(NSData *)addr {
    struct sockaddr *pSockAddr = (struct sockaddr *)[addr bytes];
    int addressFamily = pSockAddr->sa_family;
    
    //创建套接字
    CFSocketContext ctx = {0, (__bridge_retained void *)self, NULL, NULL, NULL};
    _socket = CFSocketCreate(kCFAllocatorDefault, addressFamily, SOCK_STREAM, IPPROTO_TCP, kCFSocketConnectCallBack, TCPServerConnectCallBack, &ctx);
    
    //执行连接,通过runloop保活
    CFSocketConnectToAddress(_socket, (__bridge CFDataRef)addr, 3);//延时3秒
    CFRunLoopRef runloop = CFRunLoopGetCurrent();
    CFRunLoopSourceRef source = CFSocketCreateRunLoopSource(kCFAllocatorDefault, _socket, _connectCount); //初始化runloop->source对象
    CFRunLoopAddSource(runloop, source, kCFRunLoopDefaultMode);//将循环对象加入到当前runloop
    CFRelease(source);
}
//connect 回调函数
static void TCPServerConnectCallBack(CFSocketRef socket, CFSocketCallBackType type, CFDataRef address, const void *data, void *info) {
    if (data != NULL) {
        NetStatus_Connect *connect = (__bridge_transfer NetStatus_Connect *)info;
        [connect readStream:FALSE];
    } else {
        NetStatus_Connect *connect = (__bridge_transfer NetStatus_Connect *)info;
        [connect readStream:TRUE];
    }
}

- (void)readStream:(BOOL)success {
    if (success) {
        _isExistSuccess = TRUE;
        NSInteger interval = [NetStatus_Timer computeDurationSince:__startTime] / 1000;
        _sumTime += interval;
        _resultLog = [_resultLog stringByAppendingString:[NSString stringWithFormat:@"%d's time=%ldms, ", _connectCount + 1, (long)interval]];
    } else {
        _sumTime = 99999;
        _resultLog = [_resultLog stringByAppendingString:[NSString stringWithFormat:@"%d's time=TimeOut", _connectCount + 1]];
    }
    if (_connectCount == MAXCOUNT_CONNECT - 1) {
        if (_sumTime >= 99999) {
            _resultLog = [_resultLog substringToIndex:[_resultLog length] - 1];
        } else {
            _resultLog = [_resultLog stringByAppendingString:[NSString stringWithFormat:@"average=%ldms", (long)(_sumTime / MAXCOUNT_CONNECT)]];
        }
        if (self.delegate && [self.delegate respondsToSelector:@selector(appendSocketLog:)]) {
            [self.delegate appendSocketLog:_resultLog];
        }
    }
    CFRelease(_socket);
    _connectCount++;
    if (_connectCount < MAXCOUNT_CONNECT) {
        __startTime = [NetStatus_Timer getMicroSeconds];
        [self connect];
    } else {
        if (self.delegate && [self.delegate respondsToSelector:@selector(connectDidEnd:)]) {
            [self.delegate connectDidEnd:_isExistSuccess];
        }
    }
}

@end
