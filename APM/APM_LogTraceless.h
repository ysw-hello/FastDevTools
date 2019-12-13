//
//  APM_LogTraceless.h
//  FastDevTools
//
//  Created by TimmyYan on 2019/12/13.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

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
