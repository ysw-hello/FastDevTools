//
//  UIDevice+APMLog.h
//  FastDevTools
//
//  Created by TimmyYan on 2019/12/10.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIDevice (APMLog)

#pragma mark - Device Info
/// Device system version (e.g. 8.1)
@property (nullable, nonatomic, readonly) NSString *systemVersion_;

/// The device's machine model.  e.g. "iPhone6,1" "iPad4,6"
/// @see http://theiphonewiki.com/wiki/Models
@property (nullable, nonatomic, readonly) NSString *machineModel_;

/// The device's machine model name. e.g. "iPhone 5s" "iPad mini 2"
/// @see http://theiphonewiki.com/wiki/Models
@property (nullable, nonatomic, readonly) NSString *machineName_;

#pragma mark - Disk Info
/// Total disk space in byte. (-1 when error occurs)
@property (nonatomic, readonly) int64_t diskSpace;

/// Free disk space in byte. (-1 when error occurs)
@property (nonatomic, readonly) int64_t diskSpaceFree;

/// Used disk space in byte. (-1 when error occurs)
@property (nonatomic, readonly) int64_t diskSpaceUsed;


#pragma mark - Memory Info
/// Total physical memory in byte. (-1 when error occurs)
@property (nonatomic, readonly) int64_t memoryTotal;

/// Used (active + inactive + wired) memory in byte. (-1 when error occurs)
@property (nonatomic, readonly) int64_t memoryUsed;

/// Free memory in byte. (-1 when error occurs)
@property (nonatomic, readonly) int64_t memoryFree;

/// Acvite memory in byte. (-1 when error occurs)
@property (nonatomic, readonly) int64_t memoryActive;

/// Inactive memory in byte. (-1 when error occurs)
@property (nonatomic, readonly) int64_t memoryInactive;

/// Wired memory in byte. (-1 when error occurs)
@property (nonatomic, readonly) int64_t memoryWired;

/// Purgable memory in byte. (-1 when error occurs)
@property (nonatomic, readonly) int64_t memoryPurgable;


#pragma mark - CPU Info
/// Avaliable CPU processor count.
@property (nonatomic, readonly) NSUInteger cpuCount;

/// Current CPU usage, 1.0 means 100%. (-1 when error occurs)
@property (nonatomic, readonly) float cpuUsage;

/// Current CPU usage per processor (array of NSNumber), 1.0 means 100%. (nil when error occurs)
@property (nullable, nonatomic, readonly) NSArray<NSNumber *> *cpuUsagePerProcessor;


#pragma mark - Network Info
/**
 获取网络运营商名称
 <ps：国内/国际 >
 */
+ (NSString*)getNetworkOperationName;

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
 格式化IPV6地址
 */
+ (NSString *)formatIPV6Address:(struct in6_addr)ipv6Addr;

@end

NS_ASSUME_NONNULL_END
