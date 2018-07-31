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
 [self.navigationController pushViewController:[NSClassFromString(@"DebugController") new] animated:YES];
 }
 
 */

#import <UIKit/UIKit.h>

@interface DebugController : UIViewController

@end

@interface DebugCell : UITableViewCell

@property (nonatomic, strong) NSString *title;

@property (nonatomic, strong) UISwitch *debugSwitch;

@property (nonatomic, assign) NSInteger index;//触发事件的cell_index


@end
