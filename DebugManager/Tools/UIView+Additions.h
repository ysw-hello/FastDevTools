//
//  UIView+Additions.h
//  DebugController
//
//  Created by 闫士伟 on 2018/7/30.
//  Copyright © 2018年 com.ysw. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kScreenHeight                       [[UIScreen mainScreen] bounds].size.height
#define kScreenWidth                        [[UIScreen mainScreen] bounds].size.width

//适配iPhoneX
#define DeviceIsIphoneX     ((MIN(kScreenWidth,kScreenHeight) == 375 && MAX(kScreenWidth,kScreenHeight) == 812)?YES:NO)
#define kNavBarHeight       44
#define kStatusBarHeight    (DeviceIsIphoneX ? 44 : 20)
#define kNavBarBottom       (kStatusBarHeight + kNavBarHeight)


#define SandBox_ListView_Tag 10001
#define DataFetch_ContentView_TAG 10002

static NSString *const kNotif_Name_SandBoxListRemoved = @"kNotif_Name_SandBoxListRemoved";
static NSString *const kNotif_Name_DataFetchContentRemoved = @"kNotif_Name_DataFetchContentRemoved";

static NSString *const kUserDefaults_SandBoxKey_DebugSwitch = @"kUserDefaults_SandBoxKey_DebugSwitch";
static NSString *const kUserDefaults_SandBoxForWebKey_DebugSwitch = @"kUserDefaults_SandBoxForWebKey_DebugSwitch";
static NSString *const kUserDefaults_SystemStateKey_DebugSwitch = @"kUserDefaults_SystemStateKey_DebugSwitch";
static NSString *const kUserDefaults_DataFetchKey_DebugSwitch = @"kUserDefaults_DataFetchKey_DebugSwitch";


@interface UIView (Additions)
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

@end
