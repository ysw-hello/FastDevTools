//
//  NetStatus_Speed.h
//  NetStatus_Demo
//
//  Created by TimmyYan on 2018/11/29.
//  Copyright © 2018年 com.zuoyebang. All rights reserved.
//

#import <Foundation/Foundation.h>

static NSString *const WiFiSentKey = @"WiFiSentKey";
static NSString *const WiFiReceiveKey = @"WiFiReceiveKey";
static NSString *const WWANSentKey = @"WWANSentKey";
static NSString *const WWANReceiveKey = @"WWANReceiveKey";

@interface NetStatus_Speed : NSObject

/**
 获取当前网卡数据

 @return @{@"WiFiSentKey" : @123456,
           @"WiFiReceiveKey": @123456,
           @"WWANSentKey" : @123456,
           @"WWANReceiveKey" : @123456
          }
 */
+ (NSDictionary *)getNetSpeedData;

@end
