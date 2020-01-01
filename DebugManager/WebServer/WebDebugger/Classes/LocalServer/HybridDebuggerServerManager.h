//
//  HybridDebuggerServerManager.h
//  FastDevTools
//
//  Created by TimmyYan on 2019/8/16.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class GCDWebServer;

static NSString *const APM_WritePath = @"chart/apm_write";
static NSString *const APM_ReadPath = @"chart/apm_read";

@interface HybridDebuggerServerManager : NSObject

/**
 初始化 DebugServer 单例对象
 */
+ (instancetype)sharedInstance;

/**
 展示调试器入口
 */
- (void)showDebugWindow;

/**
 隐藏调试器入口
 */
- (void)hideDebugWindow;

/**
 开启DebugServer
 返回server地址
 */
- (__kindof NSString *)startDebugServer;

/**
 获取webServer
 */
- (GCDWebServer *)getLocalServer;

/**
 停止DebugServer
 */
- (void)stopDebugServer;

@end

NS_ASSUME_NONNULL_END
