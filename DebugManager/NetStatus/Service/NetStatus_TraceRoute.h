//
//  NetStatus_TraceRoute.h
//  NetStatus_Demo
//
//  Created by TimmyYan on 2018/12/11.
//  Copyright © 2018年 com.ysw. All rights reserved.
//

#import <Foundation/Foundation.h>

static const int TRACEROUTE_PORT = 30001;
static const int TRACEROUTE_MAX_TTL = 30;
static const int TRACEROUTE_ATTEMPTS = 3;
static const int TRACEROUTE_TIMEOUT = 5000000;

@protocol NetStatus_TraceRouteDelegate <NSObject>
- (void)appendRouteLog:(NSString *)routeLog;
- (void)traceRouteDidEnd;
@end

/**
 TraceRoute：主要是通过模拟shell命令traceRoute的过程，监控网络站点间的跳转，默认执行30转，每转进行三次发送测速
 */
@interface NetStatus_TraceRoute : NSObject {
    int _udpPort;      //执行端口
    int _maxTTL;       //执行转数
    int _readTimeout;  //每次发送时间的timeout
    int _maxAttempts;  //每转的发送次数
    NSString *_running;
    BOOL _isrunning;
}

//注：当此处delegate为weak时，traceRoute在子线程执行时会将Delegate置空
@property (nonatomic, retain) id<NetStatus_TraceRouteDelegate> delegate;

- (NetStatus_TraceRoute *)initWithMaxTTL:(int)ttl timeout:(int)timeout maxAttempts:(int)attempts port:(int)port;
- (Boolean)doTraceRoute:(NSString *)host;
- (void)stopTrace;
- (BOOL)isRunning;

@end
