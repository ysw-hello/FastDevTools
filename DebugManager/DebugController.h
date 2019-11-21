//
//  DebugController.h
//  DebugController
//
//  Created by 闫士伟 on 2018/7/30.
//  Copyright © 2018年 com.ysw. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WKWebView;

typedef NS_ENUM(NSUInteger, Debug_ModuleType) {
    kDebug_ModuleType_UIDPaste      = 1,       //UID点击复制
    kDebug_ModuleType_HostChange    = 2,       //环境配置
    kDebug_ModuleType_TipsOnline    = 3,       //预上线tip服务器

    kDebug_ModuleType_SystemState   = 100,       //系统状态开关
    kDebug_ModuleType_SandBox       = 101,       //本地沙盒目录
    kDebug_ModuleType_WebServer     = 102,       //WebServer调试
    kDebug_ModuleType_DataFetch     = 103,       //请求抓包开关
    kDebug_ModuleType_NetStatus     = 104,       //网络监测
    
    kDebug_ModuleType_FlexTools     = 200,       //FLEX调试工具集
};

typedef void(^ActionHandler)(void);
typedef void(^ActionHandler_State)(BOOL state);

@interface DebugController : UIViewController
@property (nonatomic, strong) UIViewController *rootViewController;

/**
 环境切换 action
 */
@property (nonatomic, copy) ActionHandler hostChangeBlock;

/**
 当前环境为：
 */
@property (nonatomic, strong) NSString *hostName;

/**
 当前用户UID为：
 */
@property (nonatomic, strong) NSString *UIDStr;

//预上线tip服务器 开关action
@property (nonatomic, copy) ActionHandler_State tipsStateChangeBlock;



@end


@interface DebugCell : UITableViewCell

@property (nonatomic, copy) void(^debugSwithAction) (BOOL isOn, Debug_ModuleType moduleType);

@property (nonatomic, strong) NSString *title;

@property (nonatomic, assign) Debug_ModuleType moduleType;

@property (nonatomic, strong) UISwitch *debugSwitch;

@property (nonatomic, strong) UIViewController *rootViewController;


@end


