//
//  NetStatus_WiFiInfo.h
//  FastDevTools
//
//  Created by TimmyYan on 2019/2/21.
//

#import <Foundation/Foundation.h>

@interface NetStatus_WiFiInfo : NSObject

/**
 获取当前连接WiFi的名称
 */
+ (NSString *)getCurrentWiFiName;

/**
 获取当前连接WiFi的在线设备信息
 */
+ (NSArray *)getOnlineDevicesInfo;

@end
