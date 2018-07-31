//
//  SystemState_Debug.h
//  DebugController
//
//  Created by 闫士伟 on 2018/7/31.
//  Copyright © 2018年 com.ysw. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>

@interface SystemState_Debug : NSObject

+ (instancetype)sharedInstance;
/**
 Run this service will create a window above status to show FPS,CPU and Memory usage.
 */
- (void)run;

- (void)stop;

@end
