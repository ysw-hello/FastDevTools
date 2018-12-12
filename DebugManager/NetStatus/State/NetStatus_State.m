//
//  NetStatus_State.m
//  NetStatus_Demo
//
//  Created by TimmyYan on 2018/11/28.
//  Copyright © 2018年 com.zuoyebang. All rights reserved.
//

#import "NetStatus_State.h"
#import "NetStatus_StateUtil.h"

@implementation NetStatus_State

+ (instancetype)state {
    return [[self alloc] init];
}

- (NSStateID)onEvent:(NSDictionary *)event withError:(NSError *__autoreleasing *)error {
    return NSStateInvalid;
}

@end


@implementation NetStatus_Loading

- (NSStateID)onEvent:(NSDictionary *)event withError:(NSError *__autoreleasing *)error {
    NSStateID resStateID = NSStateLoading;
    NSNumber *eventID = event[kEventKeyID];
    switch ([eventID intValue]) {
        case NSEventUnload:
            resStateID = NSStateUnLoaded;
            break;
            
        case NSEventPingCallback: {
            NSNumber *eventParam = event[kEventKeyParam];
            resStateID = [NetStatus_StateUtil NSStateFromPingFlag:[eventParam boolValue]];
            break;
        }
            
        case NSEventLocalConnectionCallback:
            resStateID = [NetStatus_StateUtil NSStateFromValue:event[kEventKeyParam]];
            break;
            
        default:
            if (error != NULL) {
                *error = [NSError errorWithDomain:@"NS" code:kNSErrorNotAccept userInfo:nil];
            }
            break;
    }
    return resStateID;
}

@end


@implementation NetStatus_Unloaded

- (NSStateID)onEvent:(NSDictionary *)event withError:(NSError *__autoreleasing *)error {
    NSStateID resStateID = NSStateUnLoaded;
    NSNumber *eventID = event[kEventKeyID];
    switch ([eventID intValue]) {
        case NSEventLoad:
            resStateID = NSStateLoading;
            break;
            
        default:
            if (error != NULL) {
                *error = [NSError errorWithDomain:@"NS" code:kNSErrorNotAccept userInfo:nil];
            }
            break;
    }
    return resStateID;
}

@end

@implementation NetStatus_UnReachable

- (NSStateID)onEvent:(NSDictionary *)event withError:(NSError *__autoreleasing *)error {
    NSStateID resStateID = NSStateUnReachable;
    NSNumber *eventID = event[kEventKeyID];
    switch ([eventID intValue]) {
        case NSEventUnload:
            resStateID = NSStateUnLoaded;
            break;
            
        case NSEventPingCallback:{
            NSNumber *eventParam = event[kEventKeyParam];
            resStateID = [NetStatus_StateUtil NSStateFromPingFlag:[eventParam boolValue]];
            break;
        }
            
        case NSEventLocalConnectionCallback:
            resStateID = [NetStatus_StateUtil NSStateFromValue:event[kEventKeyParam]];
            break;
            
        default:
            if (error != NULL) {
                *error = [NSError errorWithDomain:@"NS" code:kNSErrorNotAccept userInfo:nil];
            }
            break;
    }
    return resStateID;
}

@end

@implementation NetStatus_WiFi

- (NSStateID)onEvent:(NSDictionary *)event withError:(NSError *__autoreleasing *)error {
    NSStateID resStateID = NSStateWiFi;
    NSNumber *eventID = event[kEventKeyID];
    switch ([eventID intValue]) {
        case NSEventUnload:{
            resStateID = NSStateUnLoaded;
            break;
        }
            
        case NSEventPingCallback:{
            NSNumber *eventParam = event[kEventKeyParam];
            resStateID = [NetStatus_StateUtil NSStateFromPingFlag:[eventParam boolValue]];
            break;
        }
            
        case NSEventLocalConnectionCallback:{
            resStateID = [NetStatus_StateUtil NSStateFromValue:event[kEventKeyParam]];
            break;
        }
            
        default:{
            if (error != NULL) {
                *error = [NSError errorWithDomain:@"NS" code:kNSErrorNotAccept userInfo:nil];
            }
            break;
        }
    }
    return resStateID;
}

@end

@implementation NetStatus_WWAN

- (NSStateID)onEvent:(NSDictionary *)event withError:(NSError *__autoreleasing *)error {
    NSStateID resStateID = NSStateWWAN;
    NSNumber *eventID = event[kEventKeyID];
    switch ([eventID intValue]) {
        case NSEventUnload:
            resStateID = NSStateUnLoaded;
            break;
            
        case NSEventPingCallback:{
            NSNumber *eventParam = event[kEventKeyParam];
            resStateID = [NetStatus_StateUtil NSStateFromPingFlag:[eventParam boolValue]];
            break;
        }
            
        case NSEventLocalConnectionCallback:
            resStateID = [NetStatus_StateUtil NSStateFromValue:event[kEventKeyParam]];
            break;
            
        default:
            if (error != NULL) {
                *error = [NSError errorWithDomain:@"NS" code:kNSErrorNotAccept userInfo:nil];
            }
            break;
    }
    return resStateID;
}

@end

