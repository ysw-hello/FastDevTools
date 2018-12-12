//
//  NetStatus_Connect.h
//  NetStatus_Demo
//
//  Created by TimmyYan on 2018/12/10.
//  Copyright © 2018年 com.zuoyebang. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol NetStatus_ConnectDelegate <NSObject>
- (void)appendSocketLog:(NSString *)socketLog;
- (void)connectDidEnd:(BOOL)success;
@end

/**
 Ping 监控
 主要是通过建立socket连接的过程，监控目标主机是否连通
 连续执行五次，因为每次的速度不一致，可以观察其平均速度来判断网络情况
 */

@interface NetStatus_Connect : NSObject

@property (nonatomic, weak) id<NetStatus_ConnectDelegate> delegate;

- (void)runWithHostAddress:(NSString *)hostAddress port:(int)port;

- (void)stopConnect;

@end
