//
//  SandBox_Web_Debug.h
//  DebugController
//
//  Created by 闫士伟 on 2018/8/4.
//  Copyright © 2018年 com.ysw. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SandBox_Web_Debug : NSObject

+ (instancetype)sharedInstance;

- (NSArray *)run;

- (void)stop;

@end
