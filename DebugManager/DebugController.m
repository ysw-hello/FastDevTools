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
#import "UIView+Additions.h"

@interface DebugController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray *titleArray;

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
    self.title =  @"调试控制器";
    self.titleArray = @[@"系统状态开关", @"本地沙盒目录", @"本地沙盒Web调试", @"请求抓包开关", @"环境设置(点击输入)"];
    [self initTableView];
}

#pragma mark - setters or getters
- (void)setHostName:(NSString *)hostName {
    _hostName = hostName;
    
}

#pragma mark - private SEL

- (void)initTableView {
    
    CGFloat top = self.view.height == kScreenHeight ? kNavBarBottom : 0;
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, top, kScreenWidth, kScreenHeight - kNavBarBottom) style:UITableViewStylePlain];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.tableFooterView = [UIView new];
    [self.view addSubview:_tableView];
    
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat top = self.view.height == kScreenHeight ? kNavBarBottom : 0;
    _tableView.top = top;
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
            cell.debugSwitch.on = [[NSUserDefaults standardUserDefaults] boolForKey:kUserDefaults_SandBoxForWebKey_DebugSwitch];
            cell.moduleType = kDebug_ModuleType_SandBox_Web;
            break;
            
        case 3:
            cell.debugSwitch.on = [[NSUserDefaults standardUserDefaults] boolForKey:kUserDefaults_DataFetchKey_DebugSwitch];
            cell.moduleType = kDebug_ModuleType_DataFetch;
            break;
            
        case 4:
            cell.debugSwitch.hidden = YES;
            cell.moduleType = kDebug_ModuleType_HostChange;
            cell.title = _hostName.length > 1 ? [NSString stringWithFormat:@"当前Host:%@", _hostName] : [_titleArray objectAtIndex:indexPath.row];
            break;
            
        default:
            cell.debugSwitch.on = NO;
            break;
    }
    cell.debugSwithAction = ^(BOOL isOn, Debug_ModuleType moduleType) {
        if (moduleType == kDebug_ModuleType_SandBox_Web) {
            [tableView reloadData];
        }
    };

    
    if (cell.moduleType != kDebug_ModuleType_HostChange) {
        cell.title = [_titleArray objectAtIndex:indexPath.row];
    }
    
    cell.rootViewController = self.rootViewController;
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 2 && [[NSUserDefaults standardUserDefaults] boolForKey:kUserDefaults_SandBoxForWebKey_DebugSwitch]) {
        return 50 + 40*3;
    }
    return 50;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 4 && self.hostChangeBlock) {
        self.hostChangeBlock();
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
    [att addAttribute:NSForegroundColorAttributeName value:[UIColor blueColor] range:NSMakeRange(str.length, [urlArr[0] length])];
    _webServerURL.attributedText = att;
    [_webServerURL sizeToFit];
    
    self.webUploaderServerURL = [self createLabelWithFrame:CGRectMake(_webServerURL.left, _webServerURL.bottom + 5, 100, 20)];
    NSString *str1 = @"WebUploader访问地址为: ";
    NSMutableAttributedString *att1 = [[NSMutableAttributedString alloc] initWithString:[str1 stringByAppendingString:urlArr[1]]];
    [att1 addAttribute:NSForegroundColorAttributeName value:[UIColor blueColor] range:NSMakeRange(str1.length, [urlArr[1] length])];
    _webUploaderServerURL.attributedText = att1;
    [_webUploaderServerURL sizeToFit];
    
    self.webDavServerURL = [self createLabelWithFrame:CGRectMake(_webServerURL.left, _webUploaderServerURL.bottom + 5, 100, 20)];
    NSString *str2 = @"WebDav服务器地址为: ";
    NSMutableAttributedString *att2 = [[NSMutableAttributedString alloc] initWithString:[str2 stringByAppendingString:urlArr[2]]];
    [att2 addAttribute:NSForegroundColorAttributeName value:[UIColor blueColor] range:NSMakeRange(str2.length, [urlArr[2] length])];
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

