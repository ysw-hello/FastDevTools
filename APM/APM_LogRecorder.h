//
//  APM_LogRecorder.h
//  FastDevTools
//
//  Created by TimmyYan on 2019/12/9.
//

/* < APM 埋点数据结构 >
@{
  @"device" : @{ //字符串
          @"machineModel" : @"iPhone6,1", //机器型号
          @"machineName" : @"iPhone 5s", //机器名称
          @"systemVersion" : @"12.0.1" //系统版本号
          },
  
  @"disk" : @{ //长整型 单位(byte)
          @"diskSpace" : @(12345), //硬盘总大小
          @"diskSpaceFree" : @(111), //硬盘可用空间
          @"diskSpaceUsed" : @(11222) //硬盘已用空间
          },
  
  @"memory" : @{ //长整型 单位(byte)
          @"memoryTotal" : @(10000), //物理内存总大小
          @"memoryUsed" : @(9100), //占有内存大小
          @"memoryFree" : @(650), //可用内存大小
          @"memoryActive" : @(1000), //活跃内存大小
          @"memoryInactive" : @(2000), //最近被使用过，目前处于不活跃内存大小
          @"memoryWired" : @(6000), //内核服务占用内存大小
          @"memoryPurgable" : @(25), //大块内存大小 <内存警告时，优先释放>
          },
  
  @"cpu" : @{
          @"cpuCount" : @(2), //cpu核心数 <整型>
          @"cpuUsage" : @(0.85), //cpu占有率 <多核累加> <浮点型>
          @"cpuUsagePerProcessor" : @[@(0.25), @(0.6)] //cpu每个核心占有率 <数组>
          },
 
  @"app" : @{
          @"appVersion" : @"4.3.2", //app版本号 <字符串>
          @"appName" : @"ApmTest", //app名称 <字符串>
          @"appBuildNum" : @"4.3.3" //app构建版本号 <字符串>
          @"appBundleID" : @"com.apm.test" //app包签名ID <字符串>
          },
 
  @"param" : @{}, //外部植入
  @"fps" : @(60), //整型
  @"name" : @"" //字符串
  @"timeInterval" : @(1234567) //长整型 时间戳(毫秒)
  };
 
 **/

#import <Foundation/Foundation.h>
#import "APMDataModel.h"
#import "APMDefine.h"

NS_ASSUME_NONNULL_BEGIN

@interface APM_LogRecorder : NSObject

FOUNDATION_EXTERN  APM_RecorderSetURL(NSString *apmUrlStr);
FOUNDATION_EXTERN  APM_RecordLog(NSString *name, NSDictionary *param); //默认5s间隔
FOUNDATION_EXTERN  APM_RecordStop();
FOUNDATION_EXTERN  APM_SamplingRecordLog(NSString *name, NSDictionary *param); //默认0.8s间隔,采样18个点位

/**
 接收打点数据的服务器url
 */
@property (nonatomic, strong) NSString *receiveUrl;

+ (instancetype)sharedInstance;

/**
 APM数据采集 <不间断采集>

 @param name 点名称
 @param param 外部植入参数
 @param interval 采集时间间隔(s)
 @param dataHandler 单次采集APM数据回调
 */
- (void)logRecordWithName:(NSString *)name busiParam:(NSDictionary * __nullable)busiParam interval:(CGFloat)interval dataHandler:(DeviceAPM_Handler)dataHandler;

/**
 APM数据 无痕采集 <不间断采集>

 @param pageModel 页面相关数据模型
 @param interval 采集时间间隔(s)
 @param dataHandler 单次采集APM数据回调
 */
- (void)tracelessRecordWithPageModel:(PageModel_APM *)pageModel interval:(CGFloat)interval dataHandler:(DeviceAPM_Handler)dataHandler;

/**
 获取设备APM数据 <数据采样>
 
 @param name 点名称
 @param param 外部植入参数
 @param count 采样次数
 @param interval 采样时间间隔(s)
 @param dataHandler 单次采集APM数据
 
 */
- (void)fetchDeviceAPMWithName:(NSString *)name param:(NSDictionary * __nullable)param SamplingCount:(NSUInteger)count interval:(CGFloat)interval dataHandler:(DeviceAPM_Handler)dataHandler;

/**
 停止数据获取
 */
- (void)stopFetchData;

@end

NS_ASSUME_NONNULL_END
