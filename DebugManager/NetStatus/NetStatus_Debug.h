//
//  NetStatus_Debug.h
//  NetStatus_Demo
//
//  Created by TimmyYan on 2018/12/3.
//  Copyright © 2018年 com.zuoyebang. All rights reserved.
//  基于RealReachability<实时监测实际网络状态> & LDNetDiagnoService<进行网络诊断分析> & ifaddrs.h <读取网卡I/O数据，进行实时网速监测>

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "NetStatus_Reachability.h"
#import "NetStatus_Speed.h"
#import "NetStatus_Service.h"

typedef void(^NetDataPerSecBlock) (CGFloat dSpeed, CGFloat uSpeed);
typedef void(^NetStateBlock) (NSReachabilityStatus status, NSWWANAccessType wwanType, BOOL isVpnOn);
typedef void(^NetAnalyzeBlock)(NSString *logInfo, BOOL isRunning);

@interface NetStatus_Debug : NSObject

/**
 获取单例对象
*/
+ (instancetype)sharedInstance;

- (void)showNetMonitorViewWithRootViewController:(UIViewController *)rootViewController uid:(NSString *)uid;
- (void)hideNetMonitorView;




#pragma mark - 网络服务
@property (nonatomic, copy) NetAnalyzeBlock serviceBlock;

/**
 网络诊断运行状态
 */
@property (nonatomic, assign) BOOL isServiceRunning;

/**
 开启网络诊断服务 dormain不可为空
 */
- (void)startAnalyzeNetServiceWithDormain:(NSString *)dormain uid:(NSString *)uid logStepInfoBlock:(NetAnalyzeBlock)logStepInfoBlock;

/**
 停止网络诊断服务
 */
- (void)stopAnalyzeNetService;





#pragma mark - 网络状态监控
@property (nonatomic, copy) NetStateBlock stateBlock;

/**
 开启网络状态监控

 @param block 网络状态回调
 */
- (void)startMonitorNetStateWithBlock:(NetStateBlock)block;

/**
 关闭网络状态监控
 */
- (void)stopMonitorNetState;





#pragma mark - 网速监控
/**
 开启网速监控后，每秒回调此block
 */
@property (nonatomic, copy) NetDataPerSecBlock dataHandler;

/**
 开启网速监控
 */
- (void)startMonitorNetSpeedWithBlock:(NetDataPerSecBlock)block;

/**
 关闭网速监控
 */
- (void)stopMonitorNetSpeed;


@end
