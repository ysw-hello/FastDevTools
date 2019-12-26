//
//  NetStatus_LocalConnection.h
//  NetStatus_Demo
//
//  Created by TimmyYan on 2018/11/28.
//  Copyright © 2018年 com.ysw. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SystemConfiguration/SystemConfiguration.h>

extern NSString *const kLocalConnectionChangedNotification;
extern NSString *const kLocalConnectionInitializedNotification;

typedef NS_ENUM(NSUInteger, NS_LocalConnectionStatus) {
    NS_UnReachable = 0,
    NS_WWAN = 1,
    NS_WiFi = 2,
};

@interface NetStatus_LocalConnection : NSObject

@property (nonatomic, assign) BOOL isReachable;

- (void)startNotifier;

- (void)stopNotifier;

- (NS_LocalConnectionStatus)currentLocalConnectionStatus;

@end
