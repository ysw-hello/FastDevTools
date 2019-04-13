//
//  NetStatus_Reachability.h
//  NetStatus_Demo
//
//  Created by TimmyYan on 2018/11/29.
//  Copyright © 2018年 com.zuoyebang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NetStatus_LocalConnection.h"

#define NSReachabilityInstance [NetStatus_Reachability sharedInstance]

extern NSString *const kNSReachabilityChangedNotification;
extern NSString *const kNSVPNChangedNotification;

typedef NS_ENUM(NSUInteger, NSReachabilityStatus) {
    NetStatusUnknown = -1,
    NetStatusNotReachable = 0,
    NetStatusViaWWAN = 1,
    NetStatusViaWiFi = 2
};

typedef NS_ENUM(NSUInteger, NSWWANAccessType) {
    NSWWANTypeUnknown = -1,
    NSWWANType4G = 0,
    NSWWANType3G = 1,
    NSWWANType2G = 3
};

@protocol NSReachabilityDelegate <NSObject>
@optional
/**
TODO:通过挂载一个定制的代理请求来检查网络。可以通过这种方式规避解决http可用但icmp被阻止的场景下框架判断不正确的问题。
(Update: 已经添加了判断VPN的相关逻辑，以解决这种场景下大概率误判的问题)
此方法阻塞？同步返回？还是异步？如果阻塞主线程超过n秒是不行的。
当CustomAgent的doubleCheck被启用时，ping的doubleCheck将不再工作。
 */
- (BOOL)doubleCheckByCustomAgent;
@end

@interface NetStatus_Reachability : NSObject

@property (nonatomic, strong) NetStatus_LocalConnection *localObserver;
@property (nonatomic, copy) NSString *hostForPing;
@property (nonatomic, copy) NSString *hostForCheck;

/**
 Interval in minutes; default is 2.0f, suggest value from 0.3f to 60.0f;
 If exceeded, the value will be reset to 0.3f or 60.0f (the closer one).
 */
@property (nonatomic, assign) float autoCheckInterval;
@property (nonatomic, assign) NSTimeInterval pingTimeout;

+ (instancetype)sharedInstance;

- (void)startNotifier;
- (void)stopNotifier;

- (void)reachabilityWithBlock:(void(^)(NSReachabilityStatus status))asyncHandler;

- (NSReachabilityStatus)currentReachabilityStatus;

- (NSReachabilityStatus)previousReachabilityStatus;

- (NSWWANAccessType)currentWWANType;

- (BOOL)isVPNOn;






@end
