//
//  NetStatus_Timer.m
//  NetStatus_Demo
//
//  Created by TimmyYan on 2018/12/8.
//  Copyright © 2018年 com.ysw. All rights reserved.
//

#import "NetStatus_Timer.h"
#import <sys/time.h>

@implementation NetStatus_Timer

/**
 * 获取当前时间的微秒时间戳
 */
+ (long)getMicroSeconds
{
    struct timeval time;
    gettimeofday(&time, NULL);
    return time.tv_usec;
}

/**
 * 计算uTime至当前的微秒时间间隔
 */
+ (long)computeDurationSince:(long)uTime
{
    long now = [NetStatus_Timer getMicroSeconds];
    if (now < uTime) {
        return 1000000 - uTime + now;
    }
    return now - uTime;
}

@end
