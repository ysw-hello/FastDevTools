//
//  SystemState_Config.m
//  DebugController
//
//  Created by 闫士伟 on 2018/7/31.
//  Copyright © 2018年 com.ysw. All rights reserved.
//

#import "SystemState_Config.h"

@interface SystemState_Config ()

@end

@implementation SystemState_Config

+ (instancetype)defaultConfigForType:(SystemState_LabelType)type {
    if (type == kSystemState_LabelType_Memory) {
        return [self configWithGood:150.0 warning:200.0 lessIsBetter:YES];//内存200M为warning阈值，150M为good阈值
    }
    if (type == kSystemState_LabelType_FPS) {
        return [self configWithGood:55.0 warning:40.0 lessIsBetter:NO];//帧率55fps为good阈值，44fps为warning阈值
    }
    if (type == kSystemState_LabelType_CPU) {
        return [self configWithGood:70.0 warning:90.0 lessIsBetter:YES];//CPU占有率70%为good阈值，90%为warning阈值
    }
    return nil;
}

+ (instancetype)configWithGood:(CGFloat)good warning:(CGFloat)warning lessIsBetter:(BOOL)lessIsBetter {
    SystemState_Config *config = [SystemState_Config new];
    config.lessIsBetter = lessIsBetter;
    config.goodThreshold = good;
    config.warningthreshold = warning;
    return config;
}

@end
