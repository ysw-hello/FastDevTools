//
//  NetStatus_Timer.h
//  NetStatus_Demo
//
//  Created by TimmyYan on 2018/12/8.
//  Copyright © 2018年 com.ysw. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NetStatus_Timer : NSObject

/**
 * 获取当前时间的微秒时间戳
 */
+ (long)getMicroSeconds;


/**
 * 计算uTime至当前的微秒时间间隔
 */
+ (long)computeDurationSince:(long)uTime;

@end
