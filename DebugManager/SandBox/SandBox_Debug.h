//
//  SandBox_Debug.h
//  DebugController
//
//  Created by 闫士伟 on 2018/7/30.
//  Copyright © 2018年 com.ysw. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#define SandBox_ListView_Tag 10001

static NSString *const kNotif_Name_SandBoxListRemoved = @"kNotif_Name_SandBoxListRemoved";

static NSString *const kUserDefaults_SandBoxKey_DebugSwitch = @"kUserDefaults_SandBoxKey_DebugSwitch";
static NSString *const kUserDefaults_SystemStateKey_DebugSwitch = @"kUserDefaults_SystemStateKey_DebugSwitch";

@interface SandBox_Debug : NSObject

+ (instancetype)sharedInstance;

- (void)showSandBoxListViewWithRootViewController:(UIViewController *)rootViewController;//从APPDelegate 传入 rootViewController 即可
- (void)removeSandBoxListView;

@end

@interface SandBox_ListView : UIView
@property (nonatomic, strong) UIViewController *rootViewController;
@end
