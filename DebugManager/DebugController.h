//
//  DebugController.h
//  DebugController
//
//  Created by 闫士伟 on 2018/7/30.
//  Copyright © 2018年 com.ysw. All rights reserved.
//
/**
 eg:
 - (void)viewDidLoad {
 [super viewDidLoad];
 self.view.backgroundColor = [UIColor brownColor];
 
 UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(10, self.view.bounds.size.height - 65, self.view.bounds.size.width - 20, 50)];
 [button setTitle:@"调试控制器" forState:UIControlStateNormal];
 [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
 [button addTarget:self action:@selector(pushDebuger) forControlEvents:UIControlEventTouchUpInside];
 button.backgroundColor = [UIColor blackColor];
 button.layer.borderColor = [UIColor cyanColor].CGColor;
 button.layer.borderWidth = 2;
 button.layer.masksToBounds = YES;
 button.layer.cornerRadius = 5;
 [self.view addSubview:button];
 }
 
 - (void)pushDebuger {
 DebugController *debugVC = [DebugController new];
 debugVC.rootViewController = [(AppDelegate *)[UIApplication sharedApplication].delegate window].rootViewController;//需传入承载的rootViewController
 [self.navigationController pushViewController:debugVC animated:YES];
 }
 
 */


#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, Debug_ModuleType) {
    kDebug_ModuleType_SystemState = 1, //系统状态开关
    kDebug_ModuleType_SandBox, //本地沙盒目录
    kDebug_ModuleType_SandBox_Web,//本地沙盒文件Web调试
    kDebug_ModuleType_DataFetch, //请求抓包开关
    kDebug_ModuleType_HostChange, //环境配置
};

typedef void(^ActionHandler)(void);

@interface DebugController : UIViewController
@property (nonatomic, strong) UIViewController *rootViewController;

/**
 环境切换 action
 */
@property (nonatomic, weak) ActionHandler hostChangeBlock;

/**
 当前环境为：
 */
@property (nonatomic, strong) NSString *hostName;


@end


@interface DebugCell : UITableViewCell

@property (nonatomic, copy) void(^debugSwithAction) (BOOL isOn, Debug_ModuleType moduleType);

@property (nonatomic, strong) NSString *title;

@property (nonatomic, assign) Debug_ModuleType moduleType;

@property (nonatomic, strong) UISwitch *debugSwitch;

@property (nonatomic, strong) UIViewController *rootViewController;


@end


