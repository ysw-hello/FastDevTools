//
//  NetStatus_WiFiInfo.h
//  FastDevTools
//
//  Created by TimmyYan on 2019/2/21.
//

#import <Foundation/Foundation.h>

@interface NetStatus_WiFiPing : NSObject

- (void)startPingWithHost:(NSString *)host;

@end

typedef void(^NetStatus_OnlineHostsBlock)(NSArray *hosts);

@interface NetStatus_WiFiInfo : NSObject

/**
 获取当前连接WiFi的名称
 */
+ (NSString *)getCurrentWiFiName;

+ (NSString *)getCurrentWiFiMACAdress;

/**
 获取当前连接WiFi的在线设备信息
 
 实现原理：基于ICMP协议，在局域网内ping该网段的所有IP地址，有响应的就会返回MAC地址，此时可记录下MAC地址和对应的IP地址，无响应超时的就是空地址。
 <PS：目前只支持IPV4版本，根据本地网关IP及子网掩码计算需要ping的IP域>
 */
- (void)fetchOnlineDevicesHosts:(NetStatus_OnlineHostsBlock)onlineHostsBlock;


@end
