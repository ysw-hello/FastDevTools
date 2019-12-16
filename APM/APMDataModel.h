//
//  APMDataModel.h
//  ZYBLogKit
//
//  Created by TimmyYan on 2019/12/10.
//

#import <Foundation/Foundation.h>
#import "APMDefine.h"

NS_ASSUME_NONNULL_BEGIN

@class DeviceModel_APM, DiskModel_APM, MemoryModel_APM, CPUModel_APM, APPModel_APM;

@interface APMDataModel : NSObject

/**
 机器信息
 */
@property (nonatomic, strong) DeviceModel_APM *device;

/**
 硬盘信息
 */
@property (nonatomic, strong) DiskModel_APM *disk;

/**
 内存信息
 */
@property (nonatomic, strong) MemoryModel_APM *memory;

/**
 cpu信息
 */
@property (nonatomic, strong) CPUModel_APM *cpu;

/**
 外部植入参数
 */
@property (nonatomic, strong) NSDictionary *param;

/**
 点位名称
 */
@property (nonatomic, strong) NSString *name;

/**
 帧率
 */
@property (nonatomic, assign) NSUInteger fps;

/**
 时间戳(ms)
 */
@property (nonatomic, assign) int64_t timeInterval;

/**
 app信息
 */
@property (nonatomic, strong) APPModel_APM *app;


+ (APMDataModel *)createAPMDataWithName:(NSString *)name param:(NSDictionary *)param fps:(NSUInteger)fps;

@end






@interface APPModel_APM : NSObject <APMModelDelegate>

@property (nonatomic, strong) NSString *appVersion;
@property (nonatomic, strong) NSString *appName;
@property (nonatomic, strong) NSString *appBuildNum;
@property (nonatomic, strong) NSString *appBundleID;

@end

@interface DeviceModel_APM : NSObject <APMModelDelegate>

@property (nonatomic, strong) NSString *machineModel_;
@property (nonatomic, strong) NSString *machineName_;
@property (nonatomic, strong) NSString *systemVersion_;

@end


@interface DiskModel_APM : NSObject <APMModelDelegate>

@property (nonatomic, assign) int64_t diskSpace;
@property (nonatomic, assign) int64_t diskSpaceFree;
@property (nonatomic, assign) int64_t diskSpaceUsed;

@end


@interface MemoryModel_APM : NSObject <APMModelDelegate>

@property (nonatomic, assign) int64_t memoryTotal;
@property (nonatomic, assign) int64_t memoryUsed;
@property (nonatomic, assign) int64_t memoryFree;
@property (nonatomic, assign) int64_t memoryActive;
@property (nonatomic, assign) int64_t memoryInactive;
@property (nonatomic, assign) int64_t memoryWired;
@property (nonatomic, assign) int64_t memoryPurgable;

@end


@interface CPUModel_APM : NSObject <APMModelDelegate>

@property (nonatomic, assign) NSUInteger cpuCount;
@property (nonatomic, assign) float cpuUsage;
@property (nonatomic, strong) NSArray <__kindof NSNumber *> *cpuUsagePerProcessor;

@end


NS_ASSUME_NONNULL_END
