//
//  SystemState_Config.h
//  DebugController
//
//  Created by 闫士伟 on 2018/7/31.
//  Copyright © 2018年 com.ysw. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SystemState_Types.h"
#import <UIKit/UIKit.h>

@interface SystemState_Config : NSObject

@property (nonatomic, assign) CGFloat goodThreshold;
@property (nonatomic, assign) CGFloat warningthreshold;

/**
 Default is NO. So,if value is greater than goodThreshold,then it is good.Just like FPS，the higher,the better.
 */
@property (nonatomic, assign) BOOL lessIsBetter;

+ (instancetype)configWithGood:(CGFloat)good warning:(CGFloat)warning lessIsBetter:(BOOL)lessIsBetter;

+ (instancetype)defaultConfigForType:(SystemState_LabelType)type;

@end
