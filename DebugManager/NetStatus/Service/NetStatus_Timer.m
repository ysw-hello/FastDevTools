//
//  NetStatus_Timer.m
//  NetStatus_Demo
//
//  Created by TimmyYan on 2018/12/8.
//  Copyright © 2018年 com.zuoyebang. All rights reserved.
//

#import "NetStatus_Timer.h"
#import <sys/time.h>

@implementation NetStatus_Timer

/**
 * Retourne un timestamp en microsecondes.
 */
+ (long)getMicroSeconds
{
    struct timeval time;
    gettimeofday(&time, NULL);
    return time.tv_usec;
}

/**
 * Calcule une durée en millisecondes par rapport au timestamp passé en paramètre.
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
