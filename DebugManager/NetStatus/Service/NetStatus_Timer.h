//
//  NetStatus_Timer.h
//  NetStatus_Demo
//
//  Created by TimmyYan on 2018/12/8.
//  Copyright © 2018年 com.zuoyebang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NetStatus_Timer : NSObject

/**
 * Retourne un timestamp en microsecondes.
 */
+ (long)getMicroSeconds;


/**
 * Calcule une durée en millisecondes par rapport au timestamp passé en paramètre.
 */
+ (long)computeDurationSince:(long)uTime;

@end
