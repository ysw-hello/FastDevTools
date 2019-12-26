//
//  NetStatus_StateUtil.h
//  NetStatus_Demo
//
//  Created by TimmyYan on 2018/11/28.
//  Copyright © 2018年 com.ysw. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NetStatus_Defines.h"

@interface NetStatus_StateUtil : NSObject

+ (NSStateID)NSStateFromValue:(NSString *)eventValue;

+ (NSStateID)NSStateFromPingFlag:(BOOL)isSuccess;

@end
