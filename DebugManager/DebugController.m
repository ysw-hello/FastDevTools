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
#import "SandBox_Web_Debug.h"
#import "SystemState_Debug.h"
#import "NetStatus/NetStatus_Debug.h"
#import "UIView+Debug_Additions.h"

///主标题
static NSString *const kDebugControl_MainTitle         =    @"PandoraBox";

//子标题 数据源
//业务定制
static NSString *const kDebugControl_UIDPaste          =    @"UID(点击复制)";
static NSString *const kDebugControl_HostChange        =    @"环境设置(点击输入)";
static NSString *const kDebugControl_TipsOnline        =    @"线上tips开关";

//调试工具
static NSString *const kDebugControl_SystemState       =    @"系统状态开关";
static NSString *const kDebugControl_SandBox           =    @"本地沙盒目录";
static NSString *const kDebugControl_SandBox_Web       =    @"本地沙盒Web调试";
static NSString *const kDebugControl_DataFetch         =    @"请求抓包开关";
static NSString *const kDebugControl_NetStatus         =    @"网络状态监测";
static NSString *const kDebugControl_FlexTools         =    @"FLEX工具集";

//可插拔组件
static NSString *const Class_FLEXManager               =    @"FLEXManager";
static NSString *const SEL_SharedManager_FLEXManager   =    @"sharedManager";
static NSString *const SEL_ShowExplorer_FLEXManager    =    @"showExplorer";
static NSString *const SEL_HideExplorer_FLEXManager    =    @"hideExplorer";

@interface DebugController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *titleArray;
@property (nonatomic, strong) NSMutableArray *sectionTitleArray;

@end

@implementation DebugController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController.navigationBar setShadowImage:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController.navigationBar setShadowImage:[UIImage new]];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor lightGrayColor];
    self.title =  kDebugControl_MainTitle;
    NSArray *busiArr = @[
                         kDebugControl_UIDPaste,             //UID点击复制
                         kDebugControl_HostChange,           //环境配置
                         kDebugControl_TipsOnline,           //预上线tip服务器
                         ];
    NSArray *toolArr = @[
                         kDebugControl_SystemState,          //系统状态开关
                         kDebugControl_SandBox,              //本地沙盒目录
                         kDebugControl_SandBox_Web,          //本地沙盒文件Web调试
                         kDebugControl_DataFetch,            //请求抓包开关
                         kDebugControl_NetStatus             //网络监测
                         ];
    self.titleArray = [NSMutableArray arrayWithObjects:busiArr, toolArr, nil];
    self.sectionTitleArray = [NSMutableArray arrayWithObjects:@"业务定制", @"调试工具", nil];
    //flex调试工具
    if (NSClassFromString(Class_FLEXManager)) {
        [self.titleArray addObject:@[kDebugControl_FlexTools]];
        [self.sectionTitleArray addObject:@"FLEX<提审前，移除>"];
    }
    [self initTableView];
}

#pragma mark - setters or getters
- (void)setHostName:(NSString *)hostName {
    _hostName = hostName ? : @"环境设置(点击输入)";
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:4 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
}

- (UIViewController *)rootViewController {
    if (!_rootViewController) {
        _rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    }
    return _rootViewController;
}

#pragma mark - private SEL

- (void)initTableView {
    
    CGFloat top = self.view.height == kDebug_ScreenHeight ? kDebug_NavBarBottom : 0;
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, top, kDebug_ScreenWidth, kDebug_ScreenHeight - kDebug_NavBarBottom) style:UITableViewStylePlain];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.tableFooterView = [UIView new];
    [self.view addSubview:_tableView];
    
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat top = self.view.height == kDebug_ScreenHeight ? kDebug_NavBarBottom : 0;
    _tableView.top = top;
}

#pragma mark - tableView Deleagate & DataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[_titleArray objectAtIndex:section] count];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return _titleArray.count;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, kDebug_ScreenWidth, 25)];
    title.text = [NSString stringWithFormat:@"  %@", [_sectionTitleArray objectAtIndex:section]];
    title.font = [UIFont systemFontOfSize:15];
    title.textColor = [UIColor greenColor];
    title.backgroundColor = [UIColor blackColor];
    return title;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 25;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellID = @"DebugCell";
    DebugCell *cell = (DebugCell *)[tableView dequeueReusableCellWithIdentifier:cellID];
    if (!cell) {
        cell = [[DebugCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
    }
    
    cell.title = [[_titleArray objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    
    NSInteger curRow = indexPath.row;
    NSArray *curArr = [_titleArray objectAtIndex:indexPath.section];
    
    if (curRow == [curArr indexOfObject:kDebugControl_SystemState]) {
        cell.debugSwitch.on = [[NSUserDefaults standardUserDefaults] boolForKey:kUserDefaults_SystemStateKey_DebugSwitch];
        cell.moduleType = kDebug_ModuleType_SystemState;
        
    } else if (curRow == [curArr indexOfObject:kDebugControl_SandBox]) {
        cell.debugSwitch.on = [[NSUserDefaults standardUserDefaults] boolForKey:kUserDefaults_SandBoxKey_DebugSwitch];
        cell.moduleType = kDebug_ModuleType_SandBox;
        
    } else if (curRow == [curArr indexOfObject:kDebugControl_SandBox_Web]) {
        cell.debugSwitch.on = [[NSUserDefaults standardUserDefaults] boolForKey:kUserDefaults_SandBoxForWebKey_DebugSwitch];
        cell.moduleType = kDebug_ModuleType_SandBox_Web;

    } else if (curRow == [curArr indexOfObject:kDebugControl_DataFetch]) {
        cell.debugSwitch.on = [[NSUserDefaults standardUserDefaults] boolForKey:kUserDefaults_DataFetchKey_DebugSwitch];
        cell.moduleType = kDebug_ModuleType_DataFetch;

    } else if (curRow == [curArr indexOfObject:kDebugControl_HostChange]) {
        cell.debugSwitch.hidden = YES;
        cell.moduleType = kDebug_ModuleType_HostChange;
        cell.title = _hostName.length > 1 ? [NSString stringWithFormat:@"当前Host：%@", _hostName] : [[_titleArray objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];

    } else if (curRow == [curArr indexOfObject:kDebugControl_TipsOnline]) {
        cell.debugSwitch.on = [[NSUserDefaults standardUserDefaults] boolForKey:kUserDefaults_OnlineTipsKey_DebugSwitch];
        cell.moduleType = kDebug_ModuleType_TipsOnline;

    } else if (curRow == [curArr indexOfObject:kDebugControl_UIDPaste]) {
        cell.debugSwitch.hidden = YES;
        cell.moduleType = kDebug_ModuleType_UIDPaste;
        cell.title = [NSString stringWithFormat:@"UID(点击复制)：%@", self.UIDStr];

    } else if (curRow == [curArr indexOfObject:kDebugControl_NetStatus]) {
        cell.debugSwitch.on = [[NSUserDefaults standardUserDefaults] boolForKey:KUserDefaults_NetMonitorKey_DebugSwitch];
        cell.moduleType = kDebug_ModuleType_NetStatus;

    } else if (curRow == [curArr indexOfObject:kDebugControl_FlexTools]) {
        cell.debugSwitch.on = [[NSUserDefaults standardUserDefaults] boolForKey:KUserDefaults_FlexToolsKey_DebugSwitch];
        cell.moduleType = kDebug_ModuleType_FlexTools;

    }

    //action 响应 (需要依赖于当前控制器)
    __weak typeof(self) weakSelf = self;
    cell.debugSwithAction = ^(BOOL isOn, Debug_ModuleType moduleType) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (moduleType == kDebug_ModuleType_SandBox_Web) {//沙盒web调试
            [tableView reloadData];
            
        } else if (moduleType == kDebug_ModuleType_TipsOnline) {//Tips服务器
            [[NSUserDefaults standardUserDefaults] setBool:isOn forKey:kUserDefaults_OnlineTipsKey_DebugSwitch];
            //tips预上线服务器 action
            if (strongSelf.tipsStateChangeBlock) {
                strongSelf.tipsStateChangeBlock(isOn);
            }
            
        } else if (moduleType == kDebug_ModuleType_NetStatus) {//网络状态分析
            [[NSUserDefaults standardUserDefaults] setBool:isOn forKey:KUserDefaults_NetMonitorKey_DebugSwitch];
            if (isOn) {
                [[NetStatus_Debug sharedInstance] showNetMonitorViewWithRootViewController:self.rootViewController uid:strongSelf.UIDStr ? : @""];
            } else {
                [[NetStatus_Debug sharedInstance] hideNetMonitorView];
            }
            
        } else if (moduleType == kDebug_ModuleType_FlexTools) {//Flex 工具集调试
            Class flexManagerClass = NSClassFromString(Class_FLEXManager);
            if (flexManagerClass && [flexManagerClass respondsToSelector:NSSelectorFromString(SEL_SharedManager_FLEXManager)]) {
                
                [[NSUserDefaults standardUserDefaults] setBool:isOn forKey:KUserDefaults_FlexToolsKey_DebugSwitch];
                
                id flexManager = [flexManagerClass performSelector:NSSelectorFromString(SEL_SharedManager_FLEXManager)];
                if (isOn && [flexManager respondsToSelector:NSSelectorFromString(SEL_ShowExplorer_FLEXManager)]) {
                    [flexManager performSelector:NSSelectorFromString(SEL_ShowExplorer_FLEXManager)];
                } else if ([flexManager respondsToSelector:NSSelectorFromString(SEL_HideExplorer_FLEXManager)]) {
                    [flexManager performSelector:NSSelectorFromString(SEL_HideExplorer_FLEXManager)];
                }
                
            }
            
        }
        
    };
    
    cell.rootViewController = self.rootViewController;
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == [[_titleArray objectAtIndex:indexPath.section] indexOfObject:kDebugControl_SandBox_Web] && [[NSUserDefaults standardUserDefaults] boolForKey:kUserDefaults_SandBoxForWebKey_DebugSwitch]) {
        return 50 + 40*3;
    }
    return 50;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    //无switch，直接点击cell的action
    NSArray *curArr = [_titleArray objectAtIndex:indexPath.section];
    if (indexPath.row == [curArr indexOfObject:kDebugControl_HostChange] && self.hostChangeBlock) {
        self.hostChangeBlock();
    } else if (indexPath.row == [curArr indexOfObject:kDebugControl_UIDPaste] && self.UIDStr.length > 0) {
        UIPasteboard *pasteBoard = [UIPasteboard generalPasteboard];
        [pasteBoard setString:self.UIDStr];
        [self.view showAlertWithMessage:@"UID复制成功!"];
    }
}

@end




/*************************************  DebugCell  *******************************************/
@interface DebugCell ()
@property (nonatomic, strong) UILabel *titleLabel;

@property (nonatomic, strong) UIView *webServerView;
@property (nonatomic, strong) UILabel *webServerURL;
@property (nonatomic, strong) UILabel *webUploaderServerURL;
@property (nonatomic, strong) UILabel *webDavServerURL;

@property (nonatomic, strong) UILabel *tipsLabel;


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
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(netStatusContentRemoved) name:kNotif_Name_NetStatusContentRemoved object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(flexToolsContentRemoved) name:kNotif_Name_FlexToolsContentRemoved object:nil];

    }
    return self;
}

- (void)setTitle:(NSString *)title {
    _title = title;
    _titleLabel.text = _title;
    [_titleLabel sizeToFit];
    [self layoutIfNeeded];
}

- (void)setModuleType:(Debug_ModuleType)moduleType {
    _moduleType = moduleType;
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kUserDefaults_SandBoxForWebKey_DebugSwitch] && _moduleType == kDebug_ModuleType_SandBox_Web) {
        if ([SandBox_Web_Debug sharedInstance].webServerURL_Array.count == 3) {
            [self customWebServerViewWithUrls:[SandBox_Web_Debug sharedInstance].webServerURL_Array];
        } else {
            [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kUserDefaults_SandBoxForWebKey_DebugSwitch];
            self.debugSwitch.on = NO;
        }
        
    }

}

- (void)layoutSubviews {
    [super layoutSubviews];
    _titleLabel.left = 10;
    _titleLabel.centerY = _moduleType == kDebug_ModuleType_SandBox_Web ? 50/2 : self.height/2;
    
    _debugSwitch.left = self.width - _debugSwitch.width - 10;
    _debugSwitch.centerY = _titleLabel.centerY;
    
    _webServerView.frame = CGRectMake(0, self.debugSwitch.bottom + 5, self.width, self.height - self.debugSwitch.bottom - 10);
    _tipsLabel.width = _webServerView.width;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - private SEL
- (void)customWebServerViewWithUrls:(NSArray *)urlArr {
    if (urlArr.count < 3) {
        return;
    }
    [self.webServerView removeFromSuperview];
    self.webServerView = [[UIView alloc] initWithFrame:CGRectZero];
    _webServerView.backgroundColor = [UIColor blackColor];
    [self addSubview:_webServerView];
    
    self.webServerURL = [self createLabelWithFrame:CGRectMake(10, 5, 100, 20)];
    NSString *str = @"浏览器访问地址为: ";
    NSMutableAttributedString *att = [[NSMutableAttributedString alloc] initWithString:[str stringByAppendingString:urlArr[0]]];
    [att addAttribute:NSForegroundColorAttributeName value:[UIColor cyanColor] range:NSMakeRange(str.length, [urlArr[0] length])];
    _webServerURL.attributedText = att;
    [_webServerURL sizeToFit];
    
    self.webUploaderServerURL = [self createLabelWithFrame:CGRectMake(_webServerURL.left, _webServerURL.bottom + 5, 100, 20)];
    NSString *str1 = @"WebUploader访问地址为: ";
    NSMutableAttributedString *att1 = [[NSMutableAttributedString alloc] initWithString:[str1 stringByAppendingString:urlArr[1]]];
    [att1 addAttribute:NSForegroundColorAttributeName value:[UIColor cyanColor] range:NSMakeRange(str1.length, [urlArr[1] length])];
    _webUploaderServerURL.attributedText = att1;
    [_webUploaderServerURL sizeToFit];
    
    self.webDavServerURL = [self createLabelWithFrame:CGRectMake(_webServerURL.left, _webUploaderServerURL.bottom + 5, 100, 20)];
    NSString *str2 = @"WebDav服务器地址为: ";
    NSMutableAttributedString *att2 = [[NSMutableAttributedString alloc] initWithString:[str2 stringByAppendingString:urlArr[2]]];
    [att2 addAttribute:NSForegroundColorAttributeName value:[UIColor cyanColor] range:NSMakeRange(str2.length, [urlArr[2] length])];
    _webDavServerURL.attributedText = att2;
    [_webDavServerURL sizeToFit];
    
    UILabel *tipsLabel = [self createLabelWithFrame:CGRectMake(_webServerURL.left, _webDavServerURL.bottom + 5, 100, 20)];
    tipsLabel.text = @"温馨提示：WebDav Mac客户端建议使用'Transmit' \n<xclient.info有破解版下载> ";
    tipsLabel.textColor = [UIColor redColor];
    tipsLabel.numberOfLines = 2;
    [tipsLabel sizeToFit];
    [_webServerView addSubview:tipsLabel];
    self.tipsLabel = tipsLabel;
}

- (UILabel *)createLabelWithFrame:(CGRect)frame {
    UILabel *label = [[UILabel alloc] initWithFrame:frame];
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont systemFontOfSize:15];
    label.textAlignment = NSTextAlignmentLeft;
    [_webServerView addSubview:label];
    return label;
}

- (void)flexToolsContentRemoved {
    if (self.moduleType == kDebug_ModuleType_FlexTools) {
        self.debugSwitch.on = NO;
    }
}

- (void)netStatusContentRemoved {
    if (self.moduleType == kDebug_ModuleType_NetStatus) {
        self.debugSwitch.on = NO;
    }
}

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
    if (self.debugSwithAction) {
        self.debugSwithAction(_debugSwitch.isOn, _moduleType);
    }
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
          
        case kDebug_ModuleType_SandBox_Web://本地沙盒Web调试
            [self sandBoxForWeb_actionWithState:switchState];
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
- (void)sandBoxForWeb_actionWithState:(BOOL)state {
    [[NSUserDefaults standardUserDefaults] setBool:state forKey:kUserDefaults_SandBoxForWebKey_DebugSwitch];
    if (state) {
        NSArray *urlArr = [[SandBox_Web_Debug sharedInstance] run];
        [self customWebServerViewWithUrls:urlArr];
    } else {
        [[SandBox_Web_Debug sharedInstance] stop];
        [self.webServerView removeFromSuperview];
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

