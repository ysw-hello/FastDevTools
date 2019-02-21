//
//  NetStatus_WiFiInfo.m
//  FastDevTools
//
//  Created by TimmyYan on 2019/2/21.
//

#import "NetStatus_WiFiInfo.h"
#import <SystemConfiguration/CaptiveNetwork.h>

@implementation NetStatus_WiFiInfo

+ (NSString *)getCurrentWiFiName {
    NSString *ssid = @"--";
    NSString *bssid = @"--";
    CFArrayRef arrRef = CNCopySupportedInterfaces();
    if (arrRef) {
        CFDictionaryRef dictRef = CNCopyCurrentNetworkInfo(CFArrayGetValueAtIndex(arrRef, 0));
        if (dictRef) {
            NSDictionary *dict = (NSDictionary *)CFBridgingRelease(dictRef);
            ssid = [dict valueForKey:@"SSID"];
            bssid = [dict   valueForKey:@"BSSID"];
            ssid = [ssid stringByAppendingString:[NSString stringWithFormat:@"  <WiFi路由地址：%@>", bssid]];
        }
    }
    return ssid;
}

+ (NSArray *)getOnlineDevicesInfo {
    NSMutableArray *arr = @[].mutableCopy;
    
    
    return arr;
}


@end
