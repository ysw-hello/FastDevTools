//
//  APMDataModel.m
//  FastDevTools
//
//  Created by TimmyYan on 2019/12/10.
//

#import "APMDataModel.h"
#import "UIDevice+APMLog.h"

static UIDevice *_device = nil;

static inline int64_t getCurInterval() {
    return (int64_t)([[NSDate date] timeIntervalSince1970] * 1000);
}

@implementation APMDataModel
+ (APMDataModel *)createAPMDataWithName:(NSString *)name param:(NSDictionary *)param fps:(NSUInteger)fps {
    if (!name || ![param isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    _device = [UIDevice currentDevice];
    int64_t curInterval = getCurInterval();
    
    APMDataModel *model = [[APMDataModel alloc] init];
    
    //业务植入
    model.name = name;
    model.busiParam = param;
    
    //device
    DeviceModel_APM *deviceModel = [DeviceModel_APM customCreate];
    deviceModel.curInterval = curInterval;
    model.device = deviceModel;
    
    //disk
    DiskModel_APM *diskModel = [DiskModel_APM customCreate];
    diskModel.curInterval = curInterval;
    model.disk = diskModel;
    
    //memory
    MemoryModel_APM *memoryModel = [MemoryModel_APM customCreate];
    memoryModel.curInterval = curInterval;
    model.memory = memoryModel;
    
    //cpu
    CPUModel_APM *cpuModel = [CPUModel_APM customCreate];
    cpuModel.curInterval = curInterval;
    model.cpu = cpuModel;
    
    //app
    APPModel_APM *appModel = [APPModel_APM customCreate];
    appModel.curInterval = curInterval;
    model.app = appModel;
    
    //page
    PageModel_APM *pageModel = [PageModel_APM yy_modelWithJSON:param];
    pageModel.fps = fps;
    pageModel.entryInterval = curInterval;
    model.page = pageModel; //无痕埋点调用

    return model;
}

@end

@implementation PageModel_APM

@end

@implementation APPModel_APM

+ (instancetype)customCreate {
    APPModel_APM *appInfo = [[APPModel_APM alloc] init];
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    appInfo.appVersion = [infoDictionary objectForKey:@"CFBundleShortVersionString"] ? : @"--";
    appInfo.appName = [infoDictionary objectForKey:@"CFBundleDisplayName"] ? : @"--";
    appInfo.appBuildNum = [infoDictionary objectForKey:@"CFBundleVersion"] ? : @"--";
    appInfo.appBundleID = [infoDictionary objectForKey:@"CFBundleIdentifier"] ? : @"--";
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
