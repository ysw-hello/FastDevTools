//
//  NetStatus_StateUtil.m
//  NetStatus_Demo
//
//  Created by TimmyYan on 2018/11/28.
//  Copyright © 2018年 com.zuoyebang. All rights reserved.
//

#import "NetStatus_StateUtil.h"
#import "NetStatus_Reachability.h"

@implementation NetStatus_StateUtil

+ (NSStateID)NSStateFromValue:(NSString *)eventValue {
    if ([eventValue isEqualToString:kParamValueUnReachable]) {
        return NSStateUnReachable;
    } else if ([eventValue isEqualToString:kParamValueWWAN]) {
        return NSStateWWAN;
    } else if ([eventValue isEqualToString:kParamValueWIFI]) {
        return NSStateWiFi;
    } else {
        return NSStateInvalid;
    }
}

+ (NSStateID)NSStateFromPingFlag:(BOOL)isSuccess {
    NS_LocalConnectionStatus status = NSReachabilityInstance.localObserver.currentLocalConnectionStatus;
    if (!isSuccess) {
        return NSStateUnReachable;
    } else {
        switch (status) {
            case NS_UnReachable:
                return NSStateUnReachable;
            
            case NS_WiFi:
                return NSStateWiFi;
            
            case NS_WWAN:
                return NSStateWWAN;
                
            default:
                return NSStateWiFi;
        }
    }
}

@end
