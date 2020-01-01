//
//  APM_LogTraceless.h
//  FastDevTools
//
//  Created by TimmyYan on 2019/12/13.
//
/** <APM无痕埋点采集数据结构>
{
    app =     {
        appBuildNum = "1.0.0";
        appBundleID = "com.timmy.apm";
        appName = "APMTest";
        appVersion = "1.0.2";
        curInterval = 1577336961;
    };
    cpu =     {
        cpuCount = 6;
        cpuUsage = "0.7080432772636414";
        cpuUsagePerProcessor =         (
                                        "0.1878475695848465",
                                        "0.1516067683696747",
                                        "0.031938750296831131",
                                        "0.02829425036907196",
                                        "0.1725597530603409",
                                        "0.1357961744070053"
                                        );
        curInterval = 1577336961;
    };
    device =     {
        curInterval = 1577336961;
        "machineModel_" = "iPhone10,2";
        "machineName_" = "iPhone 8 Plus";
        "systemVersion_" = "12.1.4";
    };
    disk =     {
        curInterval = 1577336961;
        diskSpace = 255989469184;
        diskSpaceFree = 178838278144;
        diskSpaceUsed = 77151191040;
    };
    memory =     {
        curInterval = 1577336961;
        memoryActive = 1041809408;
        memoryFree = 52871168;
        memoryInactive = 1029193728;
        memoryPurgable = 146423808;
        memoryTotal = 3134406656;
        memoryUsed = 2466660352;
        memoryWired = 395657216;
    };
    page =     {
        entryInterval = 1577336961;
        fps = 60;
        naFunc = viewWillAppear;
        pageName = APMTestViewController;
    };
}

*/

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

///APM数据无痕采集时间间隔(s)
static NSUInteger const RecordInterval_APM = 2;

@interface APM_LogTraceless : NSObject

+ (instancetype)sharedInstance;

/**
 开启APM 无痕埋点
 */
- (void)startAPMLogTraceless;

/**
 关闭APM 无痕埋点
 */
- (void)stopAPMLogTraceless;

+ (NSDictionary *)getDemoDataStructure;

@end

NS_ASSUME_NONNULL_END
