//
//  UIView+Debug_Additions.h
//  DebugController
//
//  Created by TimmyYan on 2018/7/30.
//  Copyright © 2018年 com.ysw. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kDebug_ScreenHeight                       [[UIScreen mainScreen] bounds].size.height
#define kDebug_ScreenWidth                        [[UIScreen mainScreen] bounds].size.width

//适配iPhoneX
#define Debug_DeviceIsIphoneX     ((MIN(kDebug_ScreenWidth,kDebug_ScreenHeight) == 375 && MAX(kDebug_ScreenWidth,kDebug_ScreenHeight) == 812)?YES:NO)
#define kDebug_NavBarHeight       44
#define kDebug_StatusBarHeight    (Debug_DeviceIsIphoneX ? 44 : 20)
#define kDebug_NavBarBottom       (kDebug_StatusBarHeight + kDebug_NavBarHeight)


#define SandBox_ListView_Tag 10001
#define DataFetch_ContentView_TAG 10002
#define NetStatus_ContentView_TAG 10003

static NSString *const kNotif_Name_SandBoxListRemoved = @"kNotif_Name_SandBoxListRemoved";
static NSString *const kNotif_Name_DataFetchContentRemoved = @"kNotif_Name_DataFetchContentRemoved";
static NSString *const kNotif_Name_NetStatusContentRemoved = @"kNotif_Name_NetStatusContentRemoved";
static NSString *const kNotif_Name_FlexToolsContentRemoved = @"kNotif_Name_FlexToolsContentRemoved";


static NSString *const kUserDefaults_SandBoxKey_DebugSwitch = @"kUserDefaults_SandBoxKey_DebugSwitch";
static NSString *const kUserDefaults_WebServerKey_DebugSwitch = @"kUserDefaults_WebServerKey_DebugSwitch";
static NSString *const kUserDefaults_SystemStateKey_DebugSwitch = @"kUserDefaults_SystemStateKey_DebugSwitch";
static NSString *const kUserDefaults_DataFetchKey_DebugSwitch = @"kUserDefaults_DataFetchKey_DebugSwitch";
static NSString *const kUserDefaults_OnlineTipsKey_DebugSwitch = @"kUserDefaults_OnlineTipsKey_DebugSwitch";
static NSString *const KUserDefaults_NetMonitorKey_DebugSwitch = @"KUserDefaults_NetMonitorKey_DebugSwitch";
static NSString *const KUserDefaults_FlexToolsKey_DebugSwitch = @"KUserDefaults_FlexToolsKey_DebugSwitch";
static NSString *const KUserDefaults_APMRecordKey_DebugSwitch = @"KUserDefaults_APMRecordKey_DebugSwitch";

@interface UIView (Debug_Additions)
/**
 * Shortcut for frame.origin.x.
 *
 * Sets frame.origin.x = left
 */
@property (nonatomic) CGFloat left;

/**
 * Shortcut for frame.origin.y
 *
 * Sets frame.origin.y = top
 */
@property (nonatomic) CGFloat top;

/**
 * Shortcut for frame.origin.x + frame.size.width
 *
 * Sets frame.origin.x = right - frame.size.width
 */
@property (nonatomic) CGFloat right;

/**
 * Shortcut for frame.origin.y + frame.size.height
 *
 * Sets frame.origin.y = bottom - frame.size.height
 */
@property (nonatomic) CGFloat bottom;

/**
 * Shortcut for frame.size.width
 *
 * Sets frame.size.width = width
 */
@property (nonatomic) CGFloat width;

/**
 * Shortcut for frame.size.height
 *
 * Sets frame.size.height = height
 */
@property (nonatomic) CGFloat height;

/**
 * Shortcut for center.x
 *
 * Sets center.x = centerX
 */
@property (nonatomic) CGFloat centerX;

/**
 * Shortcut for center.y
 *
 * Sets center.y = centerY
 */
@property (nonatomic) CGFloat centerY;

/**
 * custom button , safe for view layout
 */
@property (nonatomic,readonly) CGPoint boxCenter;

@property (nonatomic,readonly) CGFloat boxCenterX;

@property (nonatomic,readonly) CGFloat boxCenterY;
/**
 * Return the x coordinate on the screen.
 */
@property (nonatomic, readonly) CGFloat ttScreenX;

/**
 * Return the y coordinate on the screen.
 */
@property (nonatomic, readonly) CGFloat ttScreenY;

/**
 * Return the x coordinate on the screen, taking into account scroll views.
 */
@property (nonatomic, readonly) CGFloat screenViewX;

/**
 * Return the y coordinate on the screen, taking into account scroll views.
 */
@property (nonatomic, readonly) CGFloat screenViewY;

/**
 * Return the view frame on the screen, taking into account scroll views.
 */
@property (nonatomic, readonly) CGRect screenFrame;

/**
 * Shortcut for frame.origin
 */
@property (nonatomic) CGPoint origin;

/**
 * Shortcut for frame.size
 */
@property (nonatomic) CGSize size;

/**
 * Finds the first descendant view (including this view) that is a member of a particular class.
 */
- (UIView*)descendantOrSelfWithClass:(Class)cls;

/**
 * Finds the first ancestor view (including this view) that is a member of a particular class.
 */
- (UIView*)ancestorOrSelfWithClass:(Class)cls;

/**
 * Removes all subviews.
 */
- (void)removeAllSubviews;

+ (void)setViewClearColorFrom:(UIView *)topView exceptView:(UIView *)view;

/**
 * Calculates the offset of this view from another view in screen coordinates.
 *
 * otherView should be a parent view of this view.
 */
- (CGPoint)offsetFromView:(UIView*)otherView;

- (void)showAlertWithMessage:(NSString *)message;

@end
