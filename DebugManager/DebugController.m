//
//  DebugController.m
//  DebugController
//
//  Created by 闫士伟 on 2018/7/30.
//  Copyright © 2018年 com.ysw. All rights reserved.
//

#import "DebugController.h"
#import "DataFetch_Debug.h"
#import "SandBox_Debug.h"
#import "SystemState_Debug.h"
#import "UIView+Additions.h"

@interface DebugController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray *titleArray;

@end

@implementation DebugController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor lightGrayColor];
    self.title =  @"调试控制器";
    self.titleArray = @[@"系统状态开关", @"本地沙盒目录", @"请求抓包开关"];
    [self initTableView];
}

- (void)initTableView {
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, kNavBarBottom, kScreenWidth, kScreenHeight - kNavBarBottom) style:UITableViewStylePlain];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.tableFooterView = [UIView new];
    [self.view addSubview:_tableView];
    
}

#pragma mark - tableView Deleagate & DataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _titleArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellID = @"DebugCell";
    DebugCell *cell = (DebugCell *)[tableView dequeueReusableCellWithIdentifier:cellID];
    if (!cell) {
        cell = [[DebugCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
    }
    switch (indexPath.row) {
        case 0:
            cell.debugSwitch.on = [[NSUserDefaults standardUserDefaults] boolForKey:kUserDefaults_SystemStateKey_DebugSwitch];
            cell.moduleType = kDebug_ModuleType_SystemState;
            break;

        case 1:
            cell.debugSwitch.on = [[NSUserDefaults standardUserDefaults] boolForKey:kUserDefaults_SandBoxKey_DebugSwitch];
            cell.moduleType = kDebug_ModuleType_SandBox;
            break;
            
        case 2:
            cell.debugSwitch.on = [[NSUserDefaults standardUserDefaults] boolForKey:kUserDefaults_DataFetchKey_DebugSwitch];
            cell.moduleType = kDebug_ModuleType_DataFetch;
            break;

        default:
            cell.debugSwitch.on = NO;
            break;
    }
    cell.title = [_titleArray objectAtIndex:indexPath.row];
    cell.rootViewController = self.rootViewController;
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 50;
}

@end




/*************************************  DebugCell  *******************************************/
@interface DebugCell ()
@property (nonatomic, strong) UILabel *titleLabel;

@end

@implementation DebugCell

#pragma mark - system SEL
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        [self customSubviews];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sandBoxListRemoved) name:kNotif_Name_SandBoxListRemoved object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dataFetchContentRemoved) name:kNotif_Name_DataFetchContentRemoved object:nil];
    }
    return self;
}

- (void)setTitle:(NSString *)title {
    _title = title;
    _titleLabel.text = _title;
    [_titleLabel sizeToFit];
    [self layoutIfNeeded];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _titleLabel.left = 10;
    _titleLabel.centerY = self.height / 2;
    
    _debugSwitch.left = self.width - _debugSwitch.width - 10;
    _debugSwitch.centerY = _titleLabel.centerY;
    
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - private SEL
- (void)dataFetchContentRemoved {
    if ((self.moduleType == kDebug_ModuleType_DataFetch)) {
        self.debugSwitch.on = NO;
    }
}

- (void)sandBoxListRemoved {
    if (self.moduleType == kDebug_ModuleType_SandBox) {
     self.debugSwitch.on = NO;
    }
}

- (void)customSubviews {
    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, 60, 30)];
    [self addSubview:_titleLabel];
    
    self.debugSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(100, 10, 50, 34)];
    [_debugSwitch addTarget:self action:@selector(changeState) forControlEvents:UIControlEventValueChanged];
    [self addSubview:_debugSwitch];
}

- (void)changeState {
    [self actionProcessWithSwitchState:_debugSwitch.isOn];
}

#pragma mark - action 处理
- (void)actionProcessWithSwitchState:(BOOL)switchState {
    switch (self.moduleType) {
        case kDebug_ModuleType_SystemState://系统状态展示
            [self systemState_actionWithState:switchState];
            break;
            
        case kDebug_ModuleType_SandBox://本地沙盒目录
            [self sandBox_actionWithState:switchState];
            break;
            
        case kDebug_ModuleType_DataFetch://请求抓包展示
            [self fetchData_actionWithState:switchState];
            break;
            
        default:
            break;
    }
}
- (void)fetchData_actionWithState:(BOOL)state {
    [[NSUserDefaults standardUserDefaults] setBool:state forKey:kUserDefaults_DataFetchKey_DebugSwitch];
    if (state) {
        [[DataFetch_Debug sharedInstance] showDataFetchViewWithRootViewController:self.rootViewController];
    } else {
        [[DataFetch_Debug sharedInstance] hideDataFetchView];
    }
    
}
- (void)sandBox_actionWithState:(BOOL)state {
    [[NSUserDefaults standardUserDefaults] setBool:state forKey:kUserDefaults_SandBoxKey_DebugSwitch];
    if (state) {
        [[SandBox_Debug sharedInstance] showSandBoxListViewWithRootViewController:self.rootViewController];
    } else {
        [[SandBox_Debug sharedInstance] removeSandBoxListView];
    }
    
}
- (void)systemState_actionWithState:(BOOL)state {
    [[NSUserDefaults standardUserDefaults] setBool:state forKey:kUserDefaults_SystemStateKey_DebugSwitch];
    if (state) {
        [[SystemState_Debug sharedInstance] run];
    } else {
        [[SystemState_Debug sharedInstance] stop];
    }
}

@end

