//
//  NetStatus_State.h
//  NetStatus_Demo
//
//  Created by TimmyYan on 2018/11/28.
//  Copyright © 2018年 com.zuoyebang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NetStatus_Defines.h"

@interface NetStatus_State : NSObject

+ (instancetype)state;

- (NSStateID)onEvent:(NSDictionary *)event withError:(NSError **)error;

@end


@interface NetStatus_Loading : NetStatus_State
@end

@interface NetStatus_Unloaded : NetStatus_State
@end

@interface NetStatus_UnReachable : NetStatus_State
@end

@interface NetStatus_WiFi : NetStatus_State
@end

@interface NetStatus_WWAN : NetStatus_State
@end

