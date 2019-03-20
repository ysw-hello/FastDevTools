//
//  NetStatus_Ping.h
//  NetStatus_Demo
//
//  Created by TimmyYan on 2018/12/11.
//  Copyright © 2018年 com.zuoyebang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSSimplePing.h"

//监测Ping命令的输出到日志变量
@protocol NetStatus_PingDelegate <NSObject>
- (void)appendPingLog:(NSString *)pingLog;
- (void)netPingDidEnd;
@end

/**
 Ping监控：主要是通过模拟shell命令的ping过程，监控目标主机是否连通，连续执行五次，因为每次速度不一致，可以观察其平均速度来判断网络情况
 */
@protocol NSSimplePingDelegate;

@interface NetStatus_Ping : NSObject <NSSimplePingDelegate>

@property (nonatomic, weak) id<NetStatus_PingDelegate> delegate;

- (void)runWithHostName:(NSString *)hostName normalPing:(BOOL)normalPing maxCount:(NSUInteger)maxCount;

- (void)runWithHostName:(NSString *)hostName normalPing:(BOOL)normalPing;

- (void)stopPing;

@end
