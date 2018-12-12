//
//  NetStatus_Engine.m
//  NetStatus_Demo
//
//  Created by TimmyYan on 2018/11/28.
//  Copyright © 2018年 com.zuoyebang. All rights reserved.
//

#import "NetStatus_Engine.h"
#import "NetStatus_State.h"

#if (!defined(DEBUG))
#define NSLog(...)
#endif

@interface NetStatus_Engine ()

@property (nonatomic, assign) NSStateID currentStateID;
@property (nonatomic, strong) NSArray *allStates;

@end

@implementation NetStatus_Engine

- (instancetype)init {
    self = [super init];
    if (self) {
        _allStates = @[[NetStatus_Unloaded state], [NetStatus_Loading state], [NetStatus_UnReachable state], [NetStatus_WiFi state], [NetStatus_WWAN state]];
    }
    return self;
}

- (void)dealloc {
    self.allStates = nil;
}

- (void)start {
    self.currentStateID = NSStateUnLoaded;
}

- (NSUInteger)receiveInput:(NSDictionary *)dic {
    NSError *error = nil;
    NetStatus_State *currentState = self.allStates[self.currentStateID];
    NSStateID newStateID = [currentState onEvent:dic withError:&error];
    if (error) {
        NSLog(@"onEvent error:%@", error);
    }
    NSStateID previousStateID = self.currentStateID;
    self.currentStateID = newStateID;
    
    return (previousStateID == self.currentStateID ) ? -1 : 0;
}

- (BOOL)isCurrentStateAvailable {
    if (self.currentStateID == NSStateUnReachable || self.currentStateID == NSStateWWAN || self.currentStateID == NSStateWiFi) {
        return YES;
    } else {
        return NO;
    }
}

@end
