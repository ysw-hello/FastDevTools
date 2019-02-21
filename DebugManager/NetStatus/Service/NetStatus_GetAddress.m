//
//  NetStatus_GetAddress.m
//  NetStatus_Demo
//
//  Created by TimmyYan on 2018/12/7.
//  Copyright © 2018年 com.zuoyebang. All rights reserved.
//

#import "NetStatus_GetAddress.h"
#include <ifaddrs.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <sys/socket.h>

#include <resolv.h>
#include <dns.h>

#import <sys/sysctl.h>
#import <netinet/in.h>

#if TARGET_IPHONE_SIMULATOR
    #if __IPHONE_OS_VERSION_MAX_ALLOWED < 110000 //iOS11，用数字不用宏定义的原因是低版本XCode不支持110000的宏定义
        #include <net/route.h>
    #else
        #include "Route.h"
    #endif
#else
    #include "Route.h"
#endif

#define ROUNDUP(a) ((a) > 0 ? (1 + (((a)-1) | (sizeof(long) - 1))) : sizeof(long))

@implementation NetStatus_GetAddress

//获取IP地址
+ (NSString *)deviceIPAdress {
    NSString *address = @"";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    success = getifaddrs(&interfaces);
    
    if (success == 0) { // 0 表示获取成功
        temp_addr = interfaces;
        while (temp_addr != NULL) {
            if ([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"] || [[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"pdp_ip0"]) {
                //如果是IPV4地址，直接转化
                if (temp_addr->ifa_addr->sa_family == AF_INET) {
                    address = [self formatIPV4Address:((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr];
                } else if (temp_addr->ifa_addr->sa_family == AF_INET6) {
                    address = [self formatIPV6Address:((struct sockaddr_in6 *)temp_addr->ifa_addr)->sin6_addr];
                }
            }
            temp_addr = temp_addr->ifa_next;
        }
    }
    
    freeifaddrs(interfaces);
    
    if (address && ![address isEqualToString:@""] && ![address.uppercaseString hasPrefix:@"FE80"]) {
        return address;
    } else {
        return @"127.0.0.1";
    }
}

//获取子网掩码
+ (NSString *)getSubnetMask {
    NSString *subnetMask = @"";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    success = getifaddrs(&interfaces);
    if (success == 0) {
        temp_addr = interfaces;
        while (temp_addr != NULL) {
            if (temp_addr->ifa_addr->sa_family == AF_INET) {
                if ([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) {
                    //WIFI & IPV4
                    subnetMask = [self formatIPV4Address:((struct sockaddr_in *)temp_addr->ifa_netmask)->sin_addr];
                }
            }
            temp_addr = temp_addr->ifa_next;
        }
    }
    return subnetMask;
}

//获取当前网络DNS服务器地址
+ (NSArray *)outPutDNSServers {
    res_state res = malloc(sizeof(struct __res_state));
    int result = res_ninit(res);

    NSMutableArray *servers = [[NSMutableArray alloc] init];
    if (result == 0) {
        union res_9_sockaddr_union *addr_union = malloc(res->nscount * sizeof(union res_9_sockaddr_union));
        res_getservers(res, addr_union, res->nscount);

        for (int i = 0; i < res->nscount; i++) {
            if (addr_union[i].sin.sin_family == AF_INET) {
                char ip[INET_ADDRSTRLEN];
                inet_ntop(AF_INET, &(addr_union[i].sin.sin_addr), ip, INET_ADDRSTRLEN);
                NSString *dnsIP = [NSString stringWithUTF8String:ip];
                [servers addObject:dnsIP];
                NSLog(@"IPv4 DNS IP: %@", dnsIP);
            } else if (addr_union[i].sin6.sin6_family == AF_INET6) {
                char ip[INET6_ADDRSTRLEN];
                inet_ntop(AF_INET6, &(addr_union[i].sin6.sin6_addr), ip, INET6_ADDRSTRLEN);
                NSString *dnsIP = [NSString stringWithUTF8String:ip];
                [servers addObject:dnsIP];
                NSLog(@"IPv6 DNS IP: %@", dnsIP);
            } else {
                NSLog(@"Undefined family.");
            }
        }
    }
    res_nclose(res);
    free(res);

    return [NSArray arrayWithArray:servers];
}

//根据statusBar获取当前网络状态
+ (NetworkType)getNetworkTypeFromStatusBar {
    UIApplication *app = [UIApplication sharedApplication];
    NetworkType netType = NetworkType_None;
    //iOS 11
    if ([[app valueForKeyPath:@"_statusBar"] isKindOfClass:NSClassFromString(@"UIStatusBar_Modern")]) {
        NSArray *views = [[[[app valueForKeyPath:@"statusBar"] valueForKeyPath:@"statusBar"] valueForKeyPath:@"foregroundView"] subviews];
        for (UIView *view in views) {
            for (id child in view.subviews) {
                //wifi
                if ([child isKindOfClass:NSClassFromString(@"_UIStatusBarWifiSignalView")]) {
                    netType = NetworkType_WiFi;
                }
                //2G 3G 4G
                if ([child isKindOfClass:NSClassFromString(@"_UIStatusBarStringView")]) {
                    if ([[child valueForKey:@"_originalText"] containsString:@"2G"]) {
                        netType = NetworkType_2G;
                    } else if ([[child valueForKey:@"_originalText"] containsString:@"3G"]) {
                        netType = NetworkType_3G;
                    } else if ([[child valueForKey:@"_originalText"] containsString:@"4G"]) {
                        netType = NetworkType_4G;
                    }
                }
            }
        }
    } else {
        NSArray *subviews = [[[[UIApplication sharedApplication] valueForKey:@"statusBar"] valueForKey:@"foregroundView"] subviews];
        NSNumber *dataNetworkItemView = nil;
        for (id subView in subviews) {
            if ([subView isKindOfClass:[NSClassFromString(@"UIStatusBarDataNetworkItemView") class]]) {
                dataNetworkItemView = subView;
                break;
            }
        }
        NSNumber *num = [dataNetworkItemView valueForKey:@"dataNetworkType"];
        netType = [num intValue];
    }
    return netType;
}

//获取当前设备网关地址
+ (NSString *)getGatewayIPAddress {
    NSString  *address = nil;
    
    NSString *gatewayIPV4 = [self getGatewayIPV4Address];
    NSString *gatewayIPV6 = [self getGatewayIPV6Address];
    
    if (gatewayIPV6 != nil && ![gatewayIPV6.uppercaseString hasPrefix:@"FE80"]) {
        address = gatewayIPV6;
    } else {
        address = gatewayIPV4;
    }
    
    return address;
}

//通过域名获取DNS解析后ip列表
+ (NSArray *)getDNSWithDormain:(NSString *)hostName {
    NSMutableArray *result = [[NSMutableArray alloc] init];
    NSArray *IPV4DNSs = [self getIPV4DNSWithHostName:hostName];
    if (IPV4DNSs && IPV4DNSs.count > 0) {
        [result addObjectsFromArray:IPV4DNSs];
    }
    
    //由于在IPV6环境下不能用IPV4的地址进行连接监测
    //所以只返回IPV6的服务器DNS地址
    NSArray *IPV6DNSs = [self getIPV6DNSWithHostName:hostName];
    if (IPV6DNSs && IPV6DNSs.count > 0) {
        [result removeAllObjects];
        [result addObjectsFromArray:IPV6DNSs];
    }
    
    return [NSArray arrayWithArray:result];
}

#pragma mark - private SEL
+ (NSArray *)getIPV4DNSWithHostName:(NSString *)hostName {
    const char *hostN = [hostName UTF8String];
    struct hostent *phot;
    
    @try {
        phot = gethostbyname(hostN);
    } @catch (NSException *exception) {
        return nil;
    }
    
    NSMutableArray *result = [[NSMutableArray alloc] init];
    int j = 0;
    while (phot && phot->h_addr_list && phot->h_addr_list[j]) {
        struct in_addr ip_addr;
        memcpy(&ip_addr, phot->h_addr_list[j], 4);
        char ip[20] = {0};
        inet_ntop(AF_INET, &ip_addr, ip, sizeof(ip));
        
        NSString *strIPAddress = [NSString stringWithUTF8String:ip];
        [result addObject:strIPAddress];
        j++;
    }
    
    return [NSArray arrayWithArray:result];
}

+ (NSArray *)getIPV6DNSWithHostName:(NSString *)hostName {
    const char *hostN = [hostName UTF8String];
    struct hostent *phot;
    
    @try {
        /**
         * 只有在IPV6的网络下才会有返回值
         */
        phot = gethostbyname2(hostN, AF_INET6);
    } @catch (NSException *exception) {
        return nil;
    }
    
    NSMutableArray *result = [[NSMutableArray alloc] init];
    int j = 0;
    while (phot && phot->h_addr_list && phot->h_addr_list[j]) {
        struct in6_addr ip6_addr;
        memcpy(&ip6_addr, phot->h_addr_list[j], sizeof(struct in6_addr));
        NSString *strIPAddress = [self formatIPV6Address: ip6_addr];
        [result addObject:strIPAddress];
        j++;
    }
    
    return [NSArray arrayWithArray:result];
}

+ (NSString *)getGatewayIPV4Address {
    NSString *address = nil;
    
    /* net.route.0.inet.flags.gateway */
    int mib[] = {CTL_NET, PF_ROUTE, 0, AF_INET, NET_RT_FLAGS, RTF_GATEWAY};
    
    size_t l;
    char *buf, *p;
    struct rt_msghdr *rt;
    struct sockaddr *sa;
    struct sockaddr *sa_tab[RTAX_MAX];
    int i;
    
    if (sysctl(mib, sizeof(mib) / sizeof(int), 0, &l, 0, 0) < 0) {
        address = @"192.168.0.1";
    }
    
    if (l > 0) {
        buf = malloc(l);
        if (sysctl(mib, sizeof(mib) / sizeof(int), buf, &l, 0, 0) < 0) {
            address = @"192.168.0.1";
        }
        
        for (p = buf; p < buf + l; p += rt->rtm_msglen) {
            rt = (struct rt_msghdr *)p;
            sa = (struct sockaddr *)(rt + 1);
            for (i = 0; i < RTAX_MAX; i++) {
                if (rt->rtm_addrs & (1 << i)) {
                    sa_tab[i] = sa;
                    sa = (struct sockaddr *)((char *)sa + ROUNDUP(sa->sa_len));
                } else {
                    sa_tab[i] = NULL;
                }
            }
            
            if (((rt->rtm_addrs & (RTA_DST | RTA_GATEWAY)) == (RTA_DST | RTA_GATEWAY)) &&
                sa_tab[RTAX_DST]->sa_family == AF_INET &&
                sa_tab[RTAX_GATEWAY]->sa_family == AF_INET) {
                unsigned char octet[4] = {0, 0, 0, 0};
                int i;
                for (i = 0; i < 4; i++) {
                    octet[i] = (((struct sockaddr_in *)(sa_tab[RTAX_GATEWAY]))->sin_addr.s_addr >>
                                (i * 8)) &
                    0xFF;
                }
                if (((struct sockaddr_in *)sa_tab[RTAX_DST])->sin_addr.s_addr == 0) {
                    in_addr_t addr =
                    ((struct sockaddr_in *)(sa_tab[RTAX_GATEWAY]))->sin_addr.s_addr;
                    address = [self formatIPV4Address:*((struct in_addr *)&addr)];
                    NSLog(@"IPV4address%@", address);
                    break;
                }
            }
        }
        free(buf);
    }
    
    return address;
}

+ (NSString *)getGatewayIPV6Address {
    
    NSString *address = nil;
    
    /* net.route.0.inet.flags.gateway */
    int mib[] = {CTL_NET, PF_ROUTE, 0, AF_INET6, NET_RT_FLAGS, RTF_GATEWAY};
    
    size_t l;
    char *buf, *p;
    struct rt_msghdr *rt;
    struct sockaddr_in6 *sa;
    struct sockaddr_in6 *sa_tab[RTAX_MAX];
    int i;
    
    if (sysctl(mib, sizeof(mib) / sizeof(int), 0, &l, 0, 0) < 0) {
        address = @"192.168.0.1";
    }
    
    if (l > 0) {
        buf = malloc(l);
        if (sysctl(mib, sizeof(mib) / sizeof(int), buf, &l, 0, 0) < 0) {
            address = @"192.168.0.1";
        }
        
        for (p = buf; p < buf + l; p += rt->rtm_msglen) {
            rt = (struct rt_msghdr *)p;
            sa = (struct sockaddr_in6 *)(rt + 1);
            for (i = 0; i < RTAX_MAX; i++) {
                if (rt->rtm_addrs & (1 << i)) {
                    sa_tab[i] = sa;
                    sa = (struct sockaddr_in6 *)((char *)sa + sa->sin6_len);
                } else {
                    sa_tab[i] = NULL;
                }
            }
            
            if( ((rt->rtm_addrs & (RTA_DST|RTA_GATEWAY)) == (RTA_DST|RTA_GATEWAY))
               && sa_tab[RTAX_DST]->sin6_family == AF_INET6
               && sa_tab[RTAX_GATEWAY]->sin6_family == AF_INET6)
            {
                address = [self formatIPV6Address:((struct sockaddr_in6 *)(sa_tab[RTAX_GATEWAY]))->sin6_addr];
                NSLog(@"IPV6address%@", address);
                break;
            }
        }
        free(buf);
    }
    
    return address;
}

+ (NSString *)formatIPV6Address:(struct in6_addr)ipv6Addr {
    NSString *address = nil;
    
    char dstStr[INET6_ADDRSTRLEN];
    char srcStr[INET6_ADDRSTRLEN];
    memcpy(srcStr, &ipv6Addr, sizeof(struct in6_addr));
    if(inet_ntop(AF_INET6, srcStr, dstStr, INET6_ADDRSTRLEN) != NULL){
        address = [NSString stringWithUTF8String:dstStr];
    }
    
    return address;
}

+ (NSString *)formatIPV4Address:(struct in_addr)ipv4Addr {
    NSString *address = nil;
    
    char dstStr[INET_ADDRSTRLEN];
    char srcStr[INET_ADDRSTRLEN];
    memcpy(srcStr, &ipv4Addr, sizeof(struct in_addr));
    if(inet_ntop(AF_INET, srcStr, dstStr, INET_ADDRSTRLEN) != NULL){
        address = [NSString stringWithUTF8String:dstStr];
    }
    
    return address;
}

@end
