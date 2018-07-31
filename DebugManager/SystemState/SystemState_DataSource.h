//
//  SystemState_DataSource.h
//  DebugController
//
//  Created by 闫士伟 on 2018/7/31.
//  Copyright © 2018年 com.ysw. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface SystemState_DataSource : NSObject

+ (CGFloat)usedMemoryInMB;

+ (CGFloat)usedCPUPercent;

@end
