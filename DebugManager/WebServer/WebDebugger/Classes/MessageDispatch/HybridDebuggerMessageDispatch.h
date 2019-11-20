//
//  HybridDebuggerMessageDispatch.h
//  ZYBHybrid
//
//  Created by TimmyYan on 2019/9/19.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HybridDebuggerMessageDispatch : NSObject

+ (instancetype)sharedInstance;

- (void)setupDebugger;

- (void)debugCommand:(NSString *)action param:(NSDictionary *)param;

@end

NS_ASSUME_NONNULL_END
