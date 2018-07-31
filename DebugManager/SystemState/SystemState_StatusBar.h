//
//  SystemState_StatusBar.h
//  DebugController
//
//  Created by 闫士伟 on 2018/7/31.
//  Copyright © 2018年 com.ysw. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SystemState_Types.h"

@interface SystemState_Label : UILabel

@property (nonatomic, assign) SystemState_LabelState labelState;

- (void)setTextColor:(UIColor *)textColor forState:(SystemState_LabelState)labelState;

- (UIColor *)textColorForLabelState:(SystemState_LabelState)labelState;

@end

@interface SystemState_StatusBar : UIView

@property (nonatomic, strong) SystemState_Label *fpsLabel;
@property (nonatomic, strong) SystemState_Label *memoryLabel;
@property (nonatomic, strong) SystemState_Label *cpuLabel;

- (NSArray <__kindof SystemState_Label *> *)subLabels;

@end


