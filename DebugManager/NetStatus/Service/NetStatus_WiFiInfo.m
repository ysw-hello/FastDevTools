//
//  NetStatus_WiFiInfo.m
//  FastDevTools
//
//  Created by TimmyYan on 2019/2/21.
//

#import "NetStatus_WiFiInfo.h"
#import <SystemConfiguration/CaptiveNetwork.h>

@implementation NetStatus_WiFiInfo

+ (NSDictionary *)getCurrentWiFiInfo {
    CFArrayRef arrRef = CNCopySupportedInterfaces();
    if (arrRef) {
        CFDictionaryRef dictRef = CNCopyCurrentNetworkInfo(CFArrayGetValueAtIndex(arrRef, 0));
        if (dictRef) {
            NSDictionary *dict = (NSDictionary *)CFBridgingRelease(dictRef);
            return dict;
        }
    }
    return nil;
}

+ (NSString *)getCurrentWiFiName {
    return [[self getCurrentWiFiInfo] valueForKey:@"SSID"];
}

+ (NSString *)getCurrentWiFiMACAdress {
    return [[self getCurrentWiFiInfo] valueForKey:@"BSSID"];
}


+ (NSArray *)getOnlineDevicesInfo {
    NSMutableArray *arr = @[].mutableCopy;
    
    
    return arr;
}


@end
