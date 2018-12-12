//
//  NetStatus_Defines.h
//  NetStatus_Demo
//
//  Created by TimmyYan on 2018/11/28.
//  Copyright © 2018年 com.zuoyebang. All rights reserved.
//

#ifndef NetStatus_Defines_h
#define NetStatus_Defines_h

typedef NS_ENUM(NSUInteger, NSStateID) {
    NSStateInvalid = -1,
    NSStateUnLoaded = 0,
    NSStateLoading,
    NSStateUnReachable,
    NSStateWiFi,
    NSStateWWAN
};

typedef NS_ENUM(NSUInteger, NSEventID) {
    NSEventLoad = 0,
    NSEventUnload,
    NSEventLocalConnectionCallback,
    NSEventPingCallback
};

#define kEventKeyID         @"event_id"
#define kEventKeyParam      @"event_param"

#define kParamValueUnReachable @"ParamValueUnReachable"
#define kParamValueWWAN        @"ParamValueWWAN"
#define kParamValueWIFI        @"ParamValueWIFI"

#define kNSErrorNotAccept 13


#endif /* NetStatus_Defines_h */
