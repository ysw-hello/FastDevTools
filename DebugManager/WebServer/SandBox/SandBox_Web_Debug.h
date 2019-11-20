//
//  SandBox_Web_Debug.h
//  DebugController
//
//  Created by 闫士伟 on 2018/8/4.
//  Copyright © 2018年 com.ysw. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GCDWebServer, GCDWebUploader, GCDWebDAVServer;

@interface SandBox_Web_Debug : NSObject

- (NSArray *)sb_run;
- (void)sb_stop;

@end
