//
//  HybridDebuggerLogger.h
//  ZYBHybrid
//
//  Created by TimmyYan on 2019/10/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HybridDebuggerLogger : NSObject
/**
 初始化 DebugServer 单例对象
 */
+ (instancetype)sharedInstance;

/**
 开启日志
 */
- (void)startLogger;

/**
 以DebugServer为载体，记录日志，存入日志文件
 
 @param format 可变参数，传入message
 */
- (void)recordLogWithMessage:(NSString*)format, ...;

- (void)clearOffset;

- (void)parseLog:(void (^)(NSArray<NSString *> *))completion;

@end

NS_ASSUME_NONNULL_END
