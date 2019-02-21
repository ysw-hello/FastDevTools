//
//  NetStatus_GetAddress.h
//  NetStatus_Demo
//
//  Created by TimmyYan on 2018/12/7.
//  Copyright © 2018年 com.zuoyebang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, NetworkType) {
    NetworkType_None = 0,
    NetworkType_2G,
    NetworkType_3G,
    NetworkType_4G,
    NetworkType_5G,
    NetworkType_WiFi
};

@interface NetStatus_GetAddress : NSObject

/**
 获取当前设备ip地址
 */
+ (NSString *)deviceIPAdress;

/**
 获取当前设备子网掩码
 */
+ (NSString *)getSubnetMask;

/**
 获取当前设备网关地址
 */
+ (NSString *)getGatewayIPAddress;

/**
 通过域名获取服务器DNS地址
 */
+ (NSArray *)getDNSWithDormain:(NSString *)hostName;

/**
 获取本地网络的DNS地址
 */
+ (NSArray *)outPutDNSServers;

/**
 获取当前网络类型
 */
+ (NetworkType)getNetworkTypeFromStatusBar;

/**
 格式化IPV6地址
 */
+ (NSString *)formatIPV6Address:(struct in6_addr)ipv6Addr;

@end
