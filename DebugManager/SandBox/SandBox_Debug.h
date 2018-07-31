//
//  SandBox_Debug.h
//  DebugController
//
//  Created by 闫士伟 on 2018/7/30.
//  Copyright © 2018年 com.ysw. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "AppDelegate.h"

#define AppDelegateInstance ((AppDelegate *)[UIApplication sharedApplication].delegate)
#define SandBox_ListView_Tag 10001

static NSString *const kNotif_Name_SandBoxListRemoved = @"kNotif_Name_SandBoxListRemoved";

static NSString *const kUserDefaults_SandBoxKey_DebugSwitch = @"kUserDefaults_SandBoxKey_DebugSwitch";
static NSString *const kUserDefaults_SystemStateKey_DebugSwitch = @"kUserDefaults_SystemStateKey_DebugSwitch";

@interface SandBox_Debug : NSObject

+ (instancetype)sharedInstance;

- (void)showSandBoxListView;
- (void)removeSandBoxListView;

@end

@interface SandBox_ListView : UIView

@end
