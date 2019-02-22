//
//  NetStatus_TraceRoute.m
//  NetStatus_Demo
//
//  Created by TimmyYan on 2018/12/11.
//  Copyright © 2018年 com.zuoyebang. All rights reserved.
//

#include <netdb.h>
#include <arpa/inet.h>
#include <sys/time.h>

#import "NetStatus_TraceRoute.h"
#import "NetStatus_Timer.h"
#import "NetStatus_GetAddress.h"

@implementation NetStatus_TraceRoute

/**
 初始化
 */
- (NetStatus_TraceRoute *)initWithMaxTTL:(int)ttl timeout:(int)timeout maxAttempts:(int)attempts port:(int)port {
    self = [super init];
    if (self) {
        _maxTTL = ttl;
        _udpPort = port;
        _readTimeout = timeout;
        _maxAttempts = attempts;
    }
    return self;
}

/**
 监控traceroute 路径
 */
- (Boolean)doTraceRoute:(NSString *)host {
    //从name server获取server主机的地址
    NSArray *serverDNSs = [NetStatus_GetAddress getDNSWithDormain:host];
    if (!serverDNSs || serverDNSs.count <= 0) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(appendRouteLog:)] && [self.delegate respondsToSelector:@selector(traceRouteDidEnd)]) {
            [self.delegate appendRouteLog:@"TraceRoute>>> Could not get host address"];
            [self.delegate traceRouteDidEnd];
        }
        return false;
    }
    
    NSString *ipAddr0 = [serverDNSs objectAtIndex:0];
    //设置server主机的套接口地址
    NSData *addrData = nil;
    BOOL isIPV6 = NO;
    if ([ipAddr0 rangeOfString:@":"].location == NSNotFound) {
        isIPV6 = NO;
        struct sockaddr_in nativeAddr4;
        memset(&nativeAddr4, 0, sizeof(nativeAddr4));
        nativeAddr4.sin_len = sizeof(nativeAddr4);
        nativeAddr4.sin_family = AF_INET;
        nativeAddr4.sin_port = htons(_udpPort);
        inet_pton(AF_INET, ipAddr0.UTF8String, &nativeAddr4.sin_addr.s_addr);
        addrData = [NSData dataWithBytes:&nativeAddr4 length:sizeof(nativeAddr4)];
    } else {
        isIPV6 = YES;
        struct sockaddr_in6 nativeAddr6;
        memset(&nativeAddr6, 0, sizeof(nativeAddr6));
        nativeAddr6.sin6_len = sizeof(nativeAddr6);
        nativeAddr6.sin6_family = AF_INET6;
        nativeAddr6.sin6_port = htons(_udpPort);
        inet_pton(AF_INET6, ipAddr0.UTF8String, &nativeAddr6.sin6_addr);
        addrData = [NSData dataWithBytes:&nativeAddr6 length:sizeof(nativeAddr6)];
    }
    
    struct sockaddr *destination;
    destination = (struct sockaddr *)[addrData bytes];
    
    //初始化套接口
    struct sockaddr fromAddr;
    int recv_sock;
    int send_sock;
    Boolean error = false;
    
    _isrunning = YES;
    //创建一个支持ICMP协议的UDP网络套接口（用于接收）
    if ((recv_sock = socket(destination->sa_family, SOCK_DGRAM, isIPV6 ? IPPROTO_ICMPV6 : IPPROTO_ICMP)) < 0) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(appendRouteLog:)] && [self.delegate respondsToSelector:@selector(traceRouteDidEnd)]) {
            [self.delegate appendRouteLog:@"TraceRoute>>> Could not create recv socket"];
            [self.delegate traceRouteDidEnd];
        }
        return false;
    }
    
    //创建一个UDP套接口（用于发送）
    if ((send_sock  = socket(destination->sa_family, SOCK_DGRAM, 0)) < 0) {
        if (self.delegate  && [self.delegate respondsToSelector:@selector(appendRouteLog:)] && [self.delegate respondsToSelector:@selector(traceRouteDidEnd)]) {
            [self.delegate appendRouteLog:@"TraceRoute>>> Could not create send socket"];
            [self.delegate traceRouteDidEnd];
        }
        return false;
    }
    
    char *cmsg = "GET / HTTP/1.1\r\n\r\n"; //发送的报文
    socklen_t n = sizeof(fromAddr);
    char buf[100];
    
    int ttl = 1;  // 处理过程中的TTL路由消息索引
    int timeoutTTL = 0;
    bool icmp = false;  // 当收到ICMP帧时，置为true.
    long startTime;     // 开始的时间戳
    long delta;         // 持续时长
    
    //判断消息转发次数是否达到最大
    while (ttl <= _maxTTL) {
        memset(&fromAddr, 0, sizeof(fromAddr));
        //设置sender 套接字的ttl
        if ((isIPV6? setsockopt(send_sock,IPPROTO_IPV6, IPV6_UNICAST_HOPS, &ttl, sizeof(ttl)):setsockopt(send_sock, IPPROTO_IP, IP_TTL, &ttl, sizeof(ttl))) < 0) {
            error = true;
            if (self.delegate && [self.delegate respondsToSelector:@selector(appendRouteLog:)]) {
                [self.delegate appendRouteLog:@"TraceRoute>>> setsockopt failled"];
            }
        }
        
        
        //每一步连续发送maxAttenpts报文
        icmp = false;
        NSMutableString *traceTTLLog = [[NSMutableString alloc] initWithCapacity:20];
        [traceTTLLog appendFormat:@"%d\t", ttl];
        NSString *hostAddress = @"***";
        for (int try = 0; try < _maxAttempts; try ++) {
            startTime = [NetStatus_Timer getMicroSeconds];
            //发送成功返回值等于发送消息的长度
            ssize_t sentLen = sendto(send_sock, cmsg, sizeof(cmsg), 0, (struct sockaddr *)destination, isIPV6?sizeof(struct sockaddr_in6):sizeof(struct sockaddr_in));
            if (sentLen != sizeof(cmsg)) {
                NSLog(@"Error sending to server: %d %d", errno, (int)sentLen);
                error = true;
                [traceTTLLog appendFormat:@"*\t"];
            }
            
            long res = 0;
            //从（已连接）套接口上接收数据，并捕获数据发送源的地址。
            if (-1 == fcntl(recv_sock, F_SETFL, O_NONBLOCK)) {
                printf("fcntl socket error!\n");
                return -1;
            }
            /* set recvfrom from server timeout */
            struct timeval tv;
            fd_set readfds;
            tv.tv_sec = 1;
            tv.tv_usec = 0;  //设置了1s的延迟
            FD_ZERO(&readfds);
            FD_SET(recv_sock, &readfds);
            select(recv_sock + 1, &readfds, NULL, NULL, &tv);
            if (FD_ISSET(recv_sock, &readfds) > 0) {
                timeoutTTL = 0;
                if ((res = recvfrom(recv_sock, buf, 100, 0, (struct sockaddr *)&fromAddr, &n)) <
                    0) {
                    error = true;
                    [traceTTLLog appendFormat:@"%s\t", strerror(errno)];
                } else {
                    icmp = true;
                    delta = [NetStatus_Timer computeDurationSince:startTime];
                    
                    //将“二进制整数” －> “点分十进制，获取hostAddress和hostName
                    if (fromAddr.sa_family == AF_INET) {
                        
                        char display[INET_ADDRSTRLEN] = {0};
                        inet_ntop(AF_INET, &((struct sockaddr_in *)&fromAddr)->sin_addr.s_addr, display, sizeof(display));
                        hostAddress = [NSString stringWithFormat:@"%s", display];
                        
                    } else if (fromAddr.sa_family == AF_INET6) {
                        
                        char ip[INET6_ADDRSTRLEN];
                        inet_ntop(AF_INET6, &((struct sockaddr_in6 *)&fromAddr)->sin6_addr, ip, INET6_ADDRSTRLEN);
                        hostAddress = [NSString stringWithUTF8String:ip];
                        
                    }
                    
                    if (try == 0) {
                        [traceTTLLog appendFormat:@"%@\t\t", hostAddress];
                    }
                    [traceTTLLog appendFormat:@"%0.2fms\t", (float)delta / 1000];
                }
            } else {
                timeoutTTL++;
                break;
            }
            
            //监测是否要求停止追踪
            @synchronized(_running) {
                if (!_isrunning) {
                    ttl = _maxTTL;
                    icmp = true;
                    break;
                }
            }
            
        }
        
        //输出报文,如果三次都无法监控接收到报文，跳转结束
        if (icmp) {
            if ([NSThread isMainThread]) {
                if (self.delegate && [self.delegate respondsToSelector:@selector(appendRouteLog:)]) {
                    [self.delegate appendRouteLog:traceTTLLog];
                }
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (self.delegate && [self.delegate respondsToSelector:@selector(appendRouteLog:)]) {
                        [self.delegate appendRouteLog:traceTTLLog];
                    }
                });
            }
        } else {
            //如果连续三次接收不到icmp回显报文
            if (timeoutTTL >= 4) {
                break;
            } else {
                if (self.delegate && [self.delegate respondsToSelector:@selector(appendRouteLog:)]) {
                    [self.delegate appendRouteLog:[NSString stringWithFormat:@"%d\t********\t", ttl]];
                }
            }
        }
        
        //当返回地址为域名DNS解析后的IP时，终止traceroute
        if ([hostAddress isEqualToString:ipAddr0]) {
            break;
        }
        ttl++;
    }
    
    _isrunning = NO;
    //通知代理，traceroute结束
    if (self.delegate && [self.delegate respondsToSelector:@selector(traceRouteDidEnd)]) {
        [self.delegate traceRouteDidEnd];
    }
    
    return error;
}

/**
 停止traceroute追踪
 */
- (void)stopTrace {
    @synchronized (_running) {
        _isrunning = NO;
    }
}

/**
 获取traceroute运行状态
 */
- (BOOL)isRunning {
    return _isrunning;
}


@end
