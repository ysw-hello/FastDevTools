//
//  APM_LogTraceless.h
//  FastDevTools
//
//  Created by TimmyYan on 2019/12/13.
//
/** <APM无痕埋点采集数据结构>
{
    app =     {
        appBuildNum = "1.0.1";
        appBundleID = "com.timmy.apm";
        appName = "\U4f5c\U4e1a\U5e2e\U76f4\U64ad\U8bfe";
        appVersion = "1.0.0";
    };
    cpu =     {
        cpuCount = 6;
        cpuUsage = "0.721028208732605";
        cpuUsagePerProcessor =         (
                                        "0.1908515244722366",
                                        "0.1539614349603653",
                                        "0.033342491835355759",
                                        "0.029603132978081703",
                                        "0.1752402782440186",
                                        "0.1380293667316437"
                                        );
    };
    device =     {
        "machineModel_" = "iPhone10,2";
        "machineName_" = "iPhone 8 Plus";
        "systemVersion_" = "12.1.4";
    };
    disk =     {
        diskSpace = 255989469184;
        diskSpaceFree = 179183546368;
        diskSpaceUsed = 76805922816;
    };
    fps = 60;
    memory =     {
        memoryActive = 1102987264;
        memoryFree = 148324352;
        memoryInactive = 985432064;
        memoryPurgable = 152109056;
        memoryTotal = 3134406656;
        memoryUsed = 2563244032;
        memoryWired = 474824704;
    };
    name = APMTestWKWebViewController;
    param =     {
        func = viewWillAppear;
        viewClass = APMTestWKWebView;
        webCoreTyepe = WKWebView;
        webUrl = "https://github.com/ysw-hello/FastDevTools";
    };
    timeInterval = 1577254483125;
}
*/

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

///APM数据无痕采集时间间隔(s)
static NSUInteger const RecordInterval_APM = 5;

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

@end

NS_ASSUME_NONNULL_END
