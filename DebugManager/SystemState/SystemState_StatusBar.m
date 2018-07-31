//
//  SystemState_StatusBar.m
//  DebugController
//
//  Created by 闫士伟 on 2018/7/31.
//  Copyright © 2018年 com.ysw. All rights reserved.
//

#import "SystemState_StatusBar.h"

/*************************************************************************************************************************************/

@interface SystemState_Label ()
@property (nonatomic, strong) NSMutableDictionary *configCache;

@end

@implementation SystemState_Label

#pragma mark - init
- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

#pragma mark - setter & getter
- (void)setLabelState:(SystemState_LabelState)labelState {
    _labelState = labelState;
    UIColor *color = [self textColorForLabelState:labelState];
    self.textColor = color;
}

- (NSMutableDictionary *)configCache {
    if (!_configCache) {
        _configCache = [NSMutableDictionary dictionary];
    }
    return _configCache;
}

#pragma mark - public SEL
-(void)setTextColor:(UIColor *)textColor forState:(SystemState_LabelState)labelState {
    if (textColor) {
        [self.configCache setObject:textColor forKey:@(labelState)];
    } else {
        [self.configCache removeObjectForKey:@(labelState)];
    }
}

- (UIColor *)textColorForLabelState:(SystemState_LabelState)labelState {
    return [self.configCache objectForKey:@(labelState)];
}

#pragma mark - private SEL
- (void)setup {
    [self setTextColor:[UIColor colorWithRed:244.0/255.0 green:66.0/255.0 blue:66.0/255.0 alpha:1.0] forState:kSystemState_LabelState_Bad];//红色
    [self setTextColor:[UIColor orangeColor] forState:kSystemState_LabelState_Warning];//橙色
    [self setTextColor:[UIColor colorWithRed:66.0/255.0 green:244.0/255.0 blue:89.0/255.0 alpha:1.0] forState:kSystemState_LabelState_Good];//绿色
    self.labelState = kSystemState_LabelState_Good;
}

@end

/*************************************************************************************************************************************/

@implementation SystemState_StatusBar

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (NSArray<SystemState_Label *> *)subLabels {
    return @[_fpsLabel, _memoryLabel, _cpuLabel];
}

- (void)setup {
    self.backgroundColor = [UIColor blackColor];
    self.fpsLabel = [self customLabelWithText:@"FPS: d-"];
    self.memoryLabel = [self customLabelWithText:@"Memory:-"];
    self.cpuLabel = [self customLabelWithText:@"CPU:-"];
    
    NSDictionary *subviews = NSDictionaryOfVariableBindings(_fpsLabel, _memoryLabel, _cpuLabel);
    //centerY
    for (UIView *label in subviews.allValues) {
        [self addConstraint:[NSLayoutConstraint constraintWithItem:label
                                                         attribute:NSLayoutAttributeCenterY
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self
                                                         attribute:NSLayoutAttributeCenterY
                                                        multiplier:1.0
                                                          constant:0]];
    }
    //centerX
    [self addConstraint:[NSLayoutConstraint constraintWithItem:_memoryLabel
                                                     attribute:NSLayoutAttributeCenterX
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeCenterX
                                                    multiplier:1.0
                                                      constant:0]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[_fpsLabel]-8-[_memoryLabel]-8-[_cpuLabel]"
                                                                options:0
                                                                metrics:nil
                                                                  views:subviews]];
    
    
}

- (SystemState_Label *)customLabelWithText:(NSString *)text {
    SystemState_Label *label = [[SystemState_Label alloc] initWithFrame:CGRectZero];
    label.font = [UIFont systemFontOfSize:10];
    label.textColor = [UIColor whiteColor];
    label.text = text;
    label.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:label];
    return label;
}

@end


