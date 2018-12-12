//
//  NetStatus_Service.h
//  NetStatus_Demo
//
//  Created by TimmyYan on 2018/12/7.
//  Copyright © 2018年 com.zuoyebang. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol NetStatus_ServiceDelegate <NSObject>

/**
 网络服务诊断开始
 */
- (void)netServiceDidStarted;

/**
 逐步返回监控信息
 */
- (void)netServiceStepInfo:(NSString *)stepInfo;

/**
 监控是一个异步过程，监控结束输出所有log
 */
- (void)netServiceDidEnd:(NSString *)allLogInfo;

@end

@interface NetStatus_Service : NSObject

/**
 获取监控状态的代理
 注：当此处delegate为weak时，traceRoute在子线程执行时会将Delegate置空
 */
@property (nonatomic, retain) id<NetStatus_ServiceDelegate> delegate;

/**
 诊断的域名
 */
@property (nonatomic, strong) NSString *dormain;

/**
 初始化网络服务
 */
- (instancetype)initWithAppName:(NSString *)appName
                     appVersion:(NSString *)appVersion
                            uid:(NSString *)uid
                       deviceId:(NSString *)deviceId
                        dormain:(NSString *)dormain;

/**
 开始诊断网络服务
 */
- (void)startNetService;

/**
 停止诊断网络服务
 */
- (void)stopNetService;

/**
 打印网络服务诊断日志
 */
- (void)printNetServiceLogInfo;

@end
