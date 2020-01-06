//
//  APMDataModel.h
//  FastDevTools
//
//  Created by TimmyYan on 2019/12/10.
//

#import <Foundation/Foundation.h>
#import "APMDefine.h"

NS_ASSUME_NONNULL_BEGIN

@class DeviceModel_APM, DiskModel_APM, MemoryModel_APM, CPUModel_APM, APPModel_APM, PageModel_APM;

@interface APMDataModel : NSObject

/**
 外部植入参数
 */
@property (nonatomic, strong) NSDictionary *busiParam;

/**
 点位名称
 */
@property (nonatomic, strong) NSString *name;

/**
 机器信息 <APP生命周期内，只传一次>
 */
@property (nonatomic, strong) DeviceModel_APM *device;

/**
 app信息 <APP生命周期内，只传一次>
 */
@property (nonatomic, strong) APPModel_APM *app;

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
 页面信息
 */
@property (nonatomic, strong) PageModel_APM *page;


+ (APMDataModel *)createAPMDataWithName:(NSString *)name param:(NSDictionary *)param fps:(NSUInteger)fps;

@end

@interface PageModel_APM : NSObject

@property (nonatomic, strong) NSString *pageName;
@property (nonatomic, strong, nullable) NSString *pageTitle;
@property (nonatomic, assign) NSUInteger fps;
@property (nonatomic, assign) int64_t entryInterval;
@property (nonatomic, strong, nullable) NSString *webUrl;
@property (nonatomic, strong, nullable) NSString *webTitle;
@property (nonatomic, strong, nullable) NSString *viewClass;
@property (nonatomic, strong, nullable) NSString *webCoreType;
@property (nonatomic, strong) NSString *naFunc;

@end

@interface APPModel_APM : NSObject <APMModelDelegate>

@property (nonatomic, strong) NSString *appVersion;
@property (nonatomic, strong) NSString *appName;
@property (nonatomic, strong) NSString *appBuildNum;
@property (nonatomic, strong) NSString *appBundleID;
@property (nonatomic, assign) int64_t curInterval;

@end

@interface DeviceModel_APM : NSObject <APMModelDelegate>

@property (nonatomic, strong) NSString *machineModel_;
@property (nonatomic, strong) NSString *machineName_;
@property (nonatomic, strong) NSString *systemVersion_;
@property (nonatomic, assign) int64_t curInterval;

@end


@interface DiskModel_APM : NSObject <APMModelDelegate>

@property (nonatomic, assign) int64_t diskSpace;
@property (nonatomic, assign) int64_t diskSpaceFree;
@property (nonatomic, assign) int64_t diskSpaceUsed;
@property (nonatomic, assign) int64_t curInterval;

@end


@interface MemoryModel_APM : NSObject <APMModelDelegate>

@property (nonatomic, assign) int64_t memoryTotal;
@property (nonatomic, assign) int64_t memoryUsed;
@property (nonatomic, assign) int64_t memoryFree;
@property (nonatomic, assign) int64_t memoryActive;
@property (nonatomic, assign) int64_t memoryInactive;
@property (nonatomic, assign) int64_t memoryWired;
@property (nonatomic, assign) int64_t memoryPurgable;
@property (nonatomic, assign) int64_t curInterval;

@end


@interface CPUModel_APM : NSObject <APMModelDelegate>

@property (nonatomic, assign) NSUInteger cpuCount;
@property (nonatomic, assign) float cpuUsage;
@property (nonatomic, strong) NSArray <__kindof NSNumber *> *cpuUsagePerProcessor;
@property (nonatomic, assign) int64_t curInterval;

@end

NS_ASSUME_NONNULL_END
