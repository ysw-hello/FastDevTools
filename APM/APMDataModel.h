//
//  APMDataModel.h
//  ZYBLogKit
//
//  Created by TimmyYan on 2019/12/10.
//

#import <Foundation/Foundation.h>
#import "APMDefine.h"

NS_ASSUME_NONNULL_BEGIN

@class DeviceModel_APM, DiskModel_APM, MemoryModel_APM, CPUModel_APM;

@interface APMDataModel : NSObject

@property (nonatomic, strong) DeviceModel_APM *device;
@property (nonatomic, strong) DiskModel_APM *disk;
@property (nonatomic, strong) MemoryModel_APM *memory;
@property (nonatomic, strong) CPUModel_APM *cpu;
@property (nonatomic, strong) NSDictionary *param;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, assign) NSUInteger fps;
@property (nonatomic, assign) int64_t timeInterval;

+ (APMDataModel *)createAPMDataWithName:(NSString *)name param:(NSDictionary *)param fps:(NSUInteger)fps;

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
