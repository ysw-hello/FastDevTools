//
//  YSW_WaterWave.h
//  testDemo
//
//  Created by 闫士伟 on 2018/6/1.
//  Copyright © 2018年 闫士伟. All rights reserved.
//  水波工具，核心原理是创建波浪形Path，通过添加遮盖形成波浪效果


#import <Foundation/Foundation.h>

@interface YSW_WaterWave : NSObject

/** 水深占比，0 to 1;  默认为 0.5f*/
@property(nonatomic, assign)CGFloat waterDepth;

/** 波浪速度，默认 0.05f */
@property (nonatomic, assign) CGFloat speed;

/** 波浪幅度 默认为 5.f*/
@property (nonatomic, assign) CGFloat amplitude;

/** 波浪紧凑程度，默认 1.0(正弦曲线个数) */
@property (nonatomic, assign) CGFloat angularVelocity;

/** 自动开启动画 默认为YES*/
@property (nonatomic, assign) BOOL autoAnimation;

/**
 初始化 方法
 */
- (instancetype)initWithView:(UIView *)view;
- (instancetype)initWithView:(UIView *)view withWaterDepth:(CGFloat)waterDepth speed:(CGFloat)speed amlitude:(CGFloat)amplitude angularVelocaty:(CGFloat)angularVelocity autoAnimation:(BOOL)autoAnimation;

+ (instancetype)createWithView:(UIView *)view;
+ (instancetype)createWithView:(UIView *)view withWaterDepth:(CGFloat)waterDepth speed:(CGFloat)speed amlitude:(CGFloat)amplitude angularVelocaty:(CGFloat)angularVelocity autoAnimation:(BOOL)autoAnimation;

/**
 开始波动
 */
- (void)startAnimation;

/**
 停止波动
 */
- (void)stopAnimation;


@end
