//
//  APMDataModel.m
//  ZYBLogKit
//
//  Created by TimmyYan on 2019/12/10.
//

#import "APMDataModel.h"
#import "UIDevice+APMLog.h"

static UIDevice *_device = nil;

@implementation APMDataModel
+ (APMDataModel *)createAPMDataWithName:(NSString *)name param:(NSDictionary *)param fps:(NSUInteger)fps {
    if (!name) {
        return nil;
    }
    _device = [UIDevice currentDevice];
    APMDataModel *model = [[APMDataModel alloc] init];
    model.name = name;
    model.param = param;
    model.fps = fps;
    model.device = [DeviceModel_APM customCreate];
    model.disk = [DiskModel_APM customCreate];
    model.memory = [MemoryModel_APM customCreate];
    model.cpu = [CPUModel_APM customCreate];
    model.timeInterval = (int64_t)([[NSDate date] timeIntervalSince1970] * 1000);
    model.app = [APPModel_APM customCreate];
    return model;
}

@end

@implementation APPModel_APM

+ (instancetype)customCreate {
    APPModel_APM *appInfo = [[APPModel_APM alloc] init];
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    appInfo.appVersion = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
    appInfo.appName = [infoDictionary objectForKey:@"CFBundleDisplayName"];
    appInfo.appBuildNum = [infoDictionary objectForKey:@"CFBundleVersion"];
    return appInfo;
}

@end

@implementation DeviceModel_APM

+ (instancetype)customCreate {
    DeviceModel_APM *model = [[DeviceModel_APM alloc] init];
    model.machineModel_ = _device.machineModel_;
    model.machineName_ = _device.machineName_;
    model.systemVersion_ = _device.systemVersion_;
    return model;
}

@end

@implementation DiskModel_APM

+ (instancetype)customCreate {
    DiskModel_APM *model = [[DiskModel_APM alloc] init];
    model.diskSpace = _device.diskSpace;
    model.diskSpaceFree = _device.diskSpaceFree;
    model.diskSpaceUsed = _device.diskSpaceUsed;
    return model;
}

@end

@implementation MemoryModel_APM

+ (instancetype)customCreate {
    MemoryModel_APM *model = [[MemoryModel_APM alloc] init];
    model.memoryTotal = _device.memoryTotal;
    model.memoryUsed = _device.memoryUsed;
    model.memoryFree = _device.memoryFree;
    model.memoryActive = _device.memoryActive;
    model.memoryInactive = _device.memoryInactive;
    model.memoryWired = _device.memoryWired;
    model.memoryPurgable = _device.memoryPurgable;
    return model;
}

@end

@implementation CPUModel_APM

+ (instancetype)customCreate {
    CPUModel_APM *model = [[CPUModel_APM alloc] init];
    model.cpuCount = _device.cpuCount;
    model.cpuUsage = _device.cpuUsage;
    model.cpuUsagePerProcessor = _device.cpuUsagePerProcessor;
    return model;
}

@end
