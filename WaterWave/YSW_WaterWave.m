//
//  YSW_WaterWave.m
//  testDemo
//
//  Created by 闫士伟 on 2018/6/1.
//  Copyright © 2018年 闫士伟. All rights reserved.
//

#import "YSW_WaterWave.h"

@interface YSW_WaterWave ()

@property (nonatomic, assign) CGRect  frame;
/** 相位 */
@property (nonatomic, assign) CGFloat phase;
@property (nonatomic, strong) CADisplayLink *displayLink;

@property (nonatomic, strong) UIView *view;

@end

@implementation YSW_WaterWave
#pragma mark - 初始化
+ (instancetype)createWithView:(UIView *)view {
    return [[YSW_WaterWave new] initWithView:view];
}

+ (instancetype)createWithView:(UIView *)view withWaterDepth:(CGFloat)waterDepth speed:(CGFloat)speed amlitude:(CGFloat)amplitude angularVelocaty:(CGFloat)angularVelocity autoAnimation:(BOOL)autoAnimation {
    return [[YSW_WaterWave new] initWithView:view withWaterDepth:waterDepth speed:speed amlitude:amplitude angularVelocaty:angularVelocity autoAnimation:autoAnimation];
}

- (instancetype)initWithView:(UIView *)view withWaterDepth:(CGFloat)waterDepth speed:(CGFloat)speed amlitude:(CGFloat)amplitude angularVelocaty:(CGFloat)angularVelocity autoAnimation:(BOOL)autoAnimation {
    self = [self initWithView:view];
    self.autoAnimation = autoAnimation;
    self.waterDepth = waterDepth;
    self.speed = speed;
    self.amplitude = amplitude;
    self.angularVelocity = angularVelocity;
    return self;
}


- (instancetype)initWithView:(UIView *)view {
    if (self = [super init]) {
        self.view = view;
        [self settingDefaultWithView:view];
    }
    return self;
}

#pragma mark - public
/**
 开始波动 每次0.05秒执行一次动画
 */
- (void)startAnimation {
    [self stopAnimation];
    CADisplayLink *link = [CADisplayLink displayLinkWithTarget:self selector:@selector(waving)];
    link.frameInterval = 0.05;
    [link addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];//防止scrollView滚动时，动画停止
    self.displayLink = link;
}

/**
 停止波动
 */
- (void)stopAnimation {
    self.displayLink.paused = YES;
    [self.displayLink invalidate];
    self.displayLink = nil;
}

- (void)setAutoAnimation:(BOOL)autoAnimation {
    _autoAnimation = autoAnimation;
    _autoAnimation ? [self startAnimation] : [self stopAnimation];
}

#pragma mark - private
- (void)settingDefaultWithView:(UIView *)view{
    self.frame = view.frame;
    self.waterDepth = 0.5;
    self.amplitude = 5;
    self.phase = 0;
    self.speed = 0.05f;
    self.angularVelocity = 1.0f;
    self.autoAnimation = YES;
    
}

/**
 *  开始起波浪~
 */
-(void)waving {
    self.phase += self.speed;
    [self createPath];
}

/**
 *  创建path回调给代理
 */
- (void)createPath {
    @autoreleasepool {
        UIBezierPath * path = [[UIBezierPath alloc] init];
        CGFloat  waterDepthY = (1 - (self.waterDepth > 1.f ? 1.f : self.waterDepth)) * self.frame.size.height;
        CGFloat y = waterDepthY;
        [path moveToPoint:CGPointMake(0, y)];
        path.lineWidth = 1;
        
        for (double x = 0; x <= self.frame.size.width; x++) {
            // y=Asin(ωx+φ)+k
            // A——振幅，当物体作轨迹符合正弦曲线的直线往复运动时，其值为行程的1/2。
            // (ωx+φ)——相位，反映变量y所处的状态。
            // φ——初相，x=0时的相位；反映在坐标系上则为图像的左右移动。
            // k——偏距，反映在坐标系上则为图像的上移或下移。
            // ω——角速度， 控制正弦周期(单位角度内震动的次数)。
            y = self.amplitude * sin(x / 180 * M_PI * self.angularVelocity + self.phase / M_PI * 4) + waterDepthY;
            [path addLineToPoint:CGPointMake(x, y)];
        }
        [path addLineToPoint:CGPointMake(self.frame.size.width, y)];
        [path addLineToPoint:CGPointMake(self.frame.size.width, self.frame.size.height)];
        [path addLineToPoint:CGPointMake(0, self.frame.size.height)];
        [path closePath];
        
        CAShapeLayer *layer = [CAShapeLayer layer];
        layer.path = path.CGPath;
        self.view.layer.mask = layer;
    }
    
}

@end
