//
//  SystemState_Config.h
//  DebugController
//
//  Created by TimmyYan on 2018/7/31.
//  Copyright © 2018年 com.ysw. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SystemState_Types.h"
#import <UIKit/UIKit.h>

@interface SystemState_Config : NSObject

@property (nonatomic, assign) CGFloat goodThreshold;
@property (nonatomic, assign) CGFloat warningthreshold;


@property (nonatomic, assign) BOOL lessIsBetter;

+ (instancetype)configWithGood:(CGFloat)good warning:(CGFloat)warning lessIsBetter:(BOOL)lessIsBetter;

+ (instancetype)defaultConfigForType:(SystemState_LabelType)type;

@end
