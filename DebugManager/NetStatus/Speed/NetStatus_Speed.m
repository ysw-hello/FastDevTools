//
//  NetStatus_Speed.m
//  NetStatus_Demo
//
//  Created by TimmyYan on 2018/11/29.
//  Copyright © 2018年 com.ysw. All rights reserved.
//


#import "NetStatus_Speed.h"
#import <arpa/inet.h>
#import <net/if.h>
#import <ifaddrs.h>
#import <net/if_dl.h>

@implementation NetStatus_Speed

+ (NSDictionary *)getNetSpeedData {
    BOOL   success;
    struct ifaddrs *addrs;
    const struct ifaddrs *cursor;
    const struct if_data *networkStatisc;
    
    u_int32_t WiFiSent = 0;
    u_int32_t WiFiReceived = 0;
    u_int32_t WWANSent = 0;
    u_int32_t WWANReceived = 0;
    
    NSString *name = @"";
    success = getifaddrs(&addrs) == 0;
    if (success) {
        cursor = addrs;
        while (cursor != NULL) {
            name = [NSString stringWithFormat:@"%s",cursor->ifa_name];
            // names of interfaces: en前缀 是 WiFi ,pdp_ip前缀 是 蜂窝网络, utun前缀 是 VPN,
            if (cursor->ifa_addr->sa_family == AF_LINK) {
                if ([name hasPrefix:@"en"]) {
                    networkStatisc = (const struct if_data *) cursor->ifa_data;
                    WiFiSent += networkStatisc->ifi_obytes;
                    WiFiReceived += networkStatisc->ifi_ibytes;
                }
                if ([name hasPrefix:@"pdp_ip"]) {
                    networkStatisc = (const struct if_data *) cursor->ifa_data;
                    WWANSent += networkStatisc->ifi_obytes;
                    WWANReceived += networkStatisc->ifi_ibytes;
                }
            }
            cursor = cursor->ifa_next;
        }
        freeifaddrs(addrs);
    }
    NSDictionary *dataDic = @{
                              WiFiSentKey : @(WiFiSent),
                              WiFiReceiveKey : @(WiFiReceived),
                              WWANSentKey : @(WWANSent),
                              WWANReceiveKey : @(WWANReceived)
                              };
    return dataDic;

}

@end
