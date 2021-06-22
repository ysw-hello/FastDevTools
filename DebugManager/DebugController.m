//
//  DebugController.m
//  DebugController
//
//  Created by TimmyYan on 2018/7/30.
//  Copyright © 2018年 com.ysw. All rights reserved.
//

#import "DebugController.h"
#import "DataFetch_Debug.h"
#import "SandBox_Debug.h"
#import "SandBox_Web_Debug.h"
#import "SystemState_Debug.h"
#import "NetStatus/NetStatus_Debug.h"
#import "UIView+Debug_Additions.h"
#import "WebServer/WebServerManager_Debug.h"
#import "NSString+EncodeFormat.h"

#import <FastDevTools/APM_LogRecorder.h>
#import <FastDevTools/APM_LogTraceless.h>
#import <FastDevTools/DebugAlertView.h>

#import <FastDevTools/HybridDebuggerServerManager.h>
#import <GCDWebServer/GCDWebServer.h>

#import <CoreLocation/CLLocationManager.h> // ios13 获取WiFi信息需要定位

///主标题
static NSString *const kDebugControl_MainTitle         =    @"PandoraBox";

//子标题 数据源
//业务定制
static NSString *const kDebugControl_UIDPaste          =    @"UID(点击复制)";
static NSString *const kDebugControl_HostChange        =    @"环境设置(点击输入)";
static NSString *const kDebugControl_TipsOnline        =    @"线上tips开关";

//技术日志
static NSString *const kDebugControl_APM               =    @"APM页面级无痕埋点(点击输入接收url)";

//调试工具
static NSString *const kDebugControl_SystemState       =    @"系统状态开关";
static NSString *const kDebugControl_SandBox           =    @"本地沙盒目录";
static NSString *const kDebugControl_WebServer         =    @"WebServer调试";
static NSString *const kDebugControl_DataFetch         =    @"请求抓包开关";
static NSString *const kDebugControl_NetStatus         =    @"网络状态监测";

//FLEX<提审前，移除>
static NSString *const kDebugControl_FlexTools         =    @"FLEX工具集";

//可插拔组件
static NSString *const Class_FLEXManager               =    @"FLEXManager";
static NSString *const SEL_SharedManager_FLEXManager   =    @"sharedManager";
static NSString *const SEL_ShowExplorer_FLEXManager    =    @"showExplorer";
static NSString *const SEL_HideExplorer_FLEXManager    =    @"hideExplorer";

@interface DebugController () <UITableViewDelegate, UITableViewDataSource, CLLocationManagerDelegate>

@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *titleArray;
@property (nonatomic, strong) NSMutableArray *sectionTitleArray;
@property (nonatomic, assign) BOOL preNavBarHidden;
@property (nonatomic, strong) UIViewController *rootViewController;

@property (nonatomic, strong) CLLocationManager *locManager;

@end

@implementation DebugController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.preNavBarHidden = self.navigationController.navigationBar.hidden;
    [self.navigationController setNavigationBarHidden:NO];
    [self.navigationController.navigationBar setShadowImage:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:self.preNavBarHidden];
    [self.navigationController.navigationBar setShadowImage:[UIImage new]];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (@available(iOS 13.0, *)) {
        [self getcurrentLocation];
    }
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate) name:UIApplicationWillTerminateNotification object:nil];
    });
    
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor lightGrayColor];
    self.title =  kDebugControl_MainTitle;
    NSArray *busiArr = @[
                         kDebugControl_UIDPaste,             //UID点击复制
                         kDebugControl_HostChange,           //环境配置
                         kDebugControl_TipsOnline,           //预上线tip服务器
                         ];
    
    NSArray *logArr  = @[
                         kDebugControl_APM                   //APM无痕埋点
                         ];
    
    NSArray *toolArr = @[
                         kDebugControl_SystemState,          //系统状态开关
                         kDebugControl_SandBox,              //本地沙盒目录
                         kDebugControl_WebServer,            //Web调试
                         kDebugControl_DataFetch,            //请求抓包开关
                         kDebugControl_NetStatus             //网络监测
                         ];
    
    self.titleArray = [NSMutableArray arrayWithObjects:busiArr, logArr, toolArr, nil];
    self.sectionTitleArray = [NSMutableArray arrayWithObjects:@"业务定制", @"无痕日志", @"调试工具", nil];
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
    NSUInteger row = [[self.titleArray firstObject] indexOfObject:kDebugControl_HostChange];
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:row inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
}

- (UIViewController *)rootViewController {
    if (!_rootViewController) {
        _rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    }
    return _rootViewController;
}

- (UIView *)headerView {
    if (!_headerView) {
        _headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 0)];
        _headerView.backgroundColor = [UIColor clearColor];
        
        NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
        NSString *iconName = [[infoDictionary valueForKeyPath:@"CFBundleIcons.CFBundlePrimaryIcon.CFBundleIconFiles"] lastObject];
        NSString *appName = [infoDictionary objectForKey:@"CFBundleDisplayName"];
        NSString *appVersion = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
        NSString *bundleID = [infoDictionary objectForKey:@"CFBundleIdentifier"];
        NSString *title = [NSString stringWithFormat:@"APP名称：%@\n版本号：%@\nBundleID：%@", appName, appVersion, bundleID];
        UIImage *image = [UIImage imageNamed:iconName];
        if (!image) {
            NSBundle *debuggerBundle = [NSBundle bundleWithURL:[[NSBundle mainBundle] URLForResource:@"HybridDebugger" withExtension:@"bundle"]];
            NSString *imagePath = [debuggerBundle.bundlePath stringByAppendingString:@"/images/debuggerLogo.png"];
            image = [UIImage imageWithContentsOfFile:imagePath];
        }
        UIView *iconView = [self createViewWithImage:image title:title iconSize:CGSizeMake(70, 70) space:20];
        iconView.top = 20;
        iconView.centerX = _headerView.centerX;
        [_headerView addSubview:iconView];
        for (UIView *view in iconView.subviews) {
            if ([view isKindOfClass:[UIImageView class]]) {
                view.layer.cornerRadius = 14;
                view.layer.masksToBounds = YES;
            } else if ([view isKindOfClass:[UILabel class]]) {
                [(UILabel *)view setTextColor:[UIColor colorWithRed:153/255.f green:153/255.f blue:153/255.f alpha:1.f]];
            }
        }
        
        _headerView.height = 20 + iconView.height + 20;
    }
    return _headerView;
}

#pragma mark - private SEL
- (void)getcurrentLocation {
    //用户明确拒绝，可以弹窗提示用户到设置中手动打开权限
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied) {
        //使用下面接口可以打开当前应用的设置页面
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
    }
    
    self.locManager = [[CLLocationManager alloc] init];
    self.locManager.delegate = self;
    if(![CLLocationManager locationServicesEnabled] || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined){
        //弹框提示用户是否开启位置权限
        [self.locManager requestWhenInUseAuthorization];
    }
}

-(void)appEnterBackground{
    [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:nil];
}

- (void)applicationWillTerminate {
    //APP退出
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kUserDefaults_SandBoxKey_DebugSwitch];
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kUserDefaults_WebServerKey_DebugSwitch];
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kUserDefaults_SystemStateKey_DebugSwitch];
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kUserDefaults_DataFetchKey_DebugSwitch];
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kUserDefaults_OnlineTipsKey_DebugSwitch];
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:KUserDefaults_NetMonitorKey_DebugSwitch];
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:KUserDefaults_FlexToolsKey_DebugSwitch];
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:KUserDefaults_APMRecordKey_DebugSwitch];
}

- (UIView *)createViewWithImage:(UIImage*)image title:(NSString *)title iconSize:(CGSize)iconSize space:(CGFloat)space {
    UIView *view = [[UIView alloc] init];
    
    //icon
    UIImageView *icon = [[UIImageView alloc] initWithImage:image];
    icon.size = iconSize;
    [view addSubview:icon];
    
    //label
    UILabel *label = [[UILabel alloc] init];
    label.top = icon.bottom + space;
    label.width = 320;
    label.textAlignment = NSTextAlignmentCenter;
    label.numberOfLines = 0;
    label.font = [UIFont systemFontOfSize:16];
    label.text = title;
    label.textColor = [UIColor colorWithRed:51/255.f green:51/255.f blue:51/255.f alpha:1.f];
    [label sizeToFit];
    [view addSubview:label];
    
    view.width = MAX(icon.width, label.width);
    view.height = icon.height + space +label.height;
    icon.centerX = view.centerX;
    label.centerX = view.centerX;
    
    return view;
}

- (void)initTableView {
    CGFloat top = self.view.height == kDebug_ScreenHeight ? kDebug_NavBarBottom : 0;
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, top, kDebug_ScreenWidth, kDebug_ScreenHeight - kDebug_NavBarBottom) style:UITableViewStylePlain];
    _tableView.backgroundColor = [UIColor whiteColor];
    _tableView.showsVerticalScrollIndicator = NO;
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.tableFooterView = [UIView new];
    _tableView.tableHeaderView = self.headerView;
    [self.view addSubview:_tableView];
    
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat top = self.view.height == kDebug_ScreenHeight ? kDebug_NavBarBottom : 0;
    _tableView.top = top;
}

#pragma mark - CLLocationManagerDelegate
- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    if (status == kCLAuthorizationStatusAuthorizedWhenInUse ||
        status == kCLAuthorizationStatusAuthorizedAlways) {
        // 可以获取WiFi info
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"__GetLocationAccess__Wifi"];
    } else {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"__GetLocationAccess__Wifi"];
    }
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
    
    cell.debugSwitch.hidden = NO;
    cell.title = [[_titleArray objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    
    NSInteger curRow = indexPath.row;
    NSArray *curArr = [_titleArray objectAtIndex:indexPath.section];
    
    if (curRow == [curArr indexOfObject:kDebugControl_SystemState]) {
        cell.debugSwitch.on = [[NSUserDefaults standardUserDefaults] boolForKey:kUserDefaults_SystemStateKey_DebugSwitch];
        cell.moduleType = kDebug_ModuleType_SystemState;
        
    } else if (curRow == [curArr indexOfObject:kDebugControl_SandBox]) {
        cell.debugSwitch.on = [[NSUserDefaults standardUserDefaults] boolForKey:kUserDefaults_SandBoxKey_DebugSwitch];
        cell.moduleType = kDebug_ModuleType_SandBox;
        
    } else if (curRow == [curArr indexOfObject:kDebugControl_WebServer]) {
        cell.debugSwitch.on = [[NSUserDefaults standardUserDefaults] boolForKey:kUserDefaults_WebServerKey_DebugSwitch];
        cell.moduleType = kDebug_ModuleType_WebServer;

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
        
    } else if (curRow == [curArr indexOfObject:kDebugControl_APM]) {
        cell.debugSwitch.on = [[NSUserDefaults standardUserDefaults] boolForKey:KUserDefaults_APMRecordKey_DebugSwitch];
        cell.moduleType = kDebug_ModuleType_APMRecord;
        cell.title = [APM_LogRecorder sharedInstance].receiveUrl.length > 3 ? [NSString stringWithFormat:@"APM-接收数据的URL为:\n%@", [APM_LogRecorder sharedInstance].receiveUrl] : [[_titleArray objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    }

    //action 响应 (需要依赖于当前控制器)
    __weak typeof(self) weakSelf = self;
    __weak typeof(tableView) weakTableView = tableView;
    cell.debugSwithAction = ^(BOOL isOn, Debug_ModuleType moduleType) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        __strong typeof(weakTableView) strongTableView = weakTableView;

        if (moduleType == kDebug_ModuleType_WebServer) {//web调试
            if ([APM_LogRecorder sharedInstance].receiveUrl.length < 3) {
                GCDWebServer *webServer = [[HybridDebuggerServerManager sharedInstance] getLocalServer];
                NSString *apmUrlStr = webServer.isRunning ? [webServer.serverURL.absoluteString stringByAppendingString:APM_WritePath] : @"";
                APM_RecorderSetURL(apmUrlStr);
            } else if (!isOn && [[APM_LogRecorder sharedInstance].receiveUrl containsString:[@":8181/" stringByAppendingString:APM_WritePath]]) {
                APM_RecorderSetURL(@"");
            }
            
            [strongTableView reloadData];
            
        } else if (moduleType == kDebug_ModuleType_TipsOnline) {//Tips服务器
            [[NSUserDefaults standardUserDefaults] setBool:isOn forKey:kUserDefaults_OnlineTipsKey_DebugSwitch];
            //tips预上线服务器 action
            if (strongSelf.tipsStateChangeBlock) {
                strongSelf.tipsStateChangeBlock(isOn);
            }
            
        } else if (moduleType == kDebug_ModuleType_NetStatus) {//网络状态分析
            [[NSUserDefaults standardUserDefaults] setBool:isOn forKey:KUserDefaults_NetMonitorKey_DebugSwitch];
            if (isOn) {
                [[NetStatus_Debug sharedInstance] showNetMonitorViewWithRootViewController:strongSelf.rootViewController uid:strongSelf.UIDStr ? : @""];
            } else {
                [[NetStatus_Debug sharedInstance] hideNetMonitorView];
            }
            
        } else if (moduleType == kDebug_ModuleType_FlexTools) {//Flex 工具集调试
            Class flexManagerClass = NSClassFromString(Class_FLEXManager);
            if (flexManagerClass && [flexManagerClass respondsToSelector:NSSelectorFromString(SEL_SharedManager_FLEXManager)]) {
                
                [[NSUserDefaults standardUserDefaults] setBool:isOn forKey:KUserDefaults_FlexToolsKey_DebugSwitch];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                id flexManager = [flexManagerClass performSelector:NSSelectorFromString(SEL_SharedManager_FLEXManager)];
                if (isOn && [flexManager respondsToSelector:NSSelectorFromString(SEL_ShowExplorer_FLEXManager)]) {
                    [flexManager performSelector:NSSelectorFromString(SEL_ShowExplorer_FLEXManager)];
                } else if ([flexManager respondsToSelector:NSSelectorFromString(SEL_HideExplorer_FLEXManager)]) {
                    [flexManager performSelector:NSSelectorFromString(SEL_HideExplorer_FLEXManager)];
                }
#pragma clang diagnostic pop
                
            }
            
        } else if (moduleType == kDebug_ModuleType_APMRecord) {//APM无痕埋点
            [[NSUserDefaults standardUserDefaults] setBool:isOn forKey:KUserDefaults_APMRecordKey_DebugSwitch];
            if (isOn) {
                [[APM_LogTraceless sharedInstance] startAPMLogTraceless];
            } else {
                [[APM_LogTraceless sharedInstance] stopAPMLogTraceless];
            }
            
        }
        
    };
    
    cell.rootViewController = self.rootViewController;
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == [[_titleArray objectAtIndex:indexPath.section] indexOfObject:kDebugControl_WebServer] && [[NSUserDefaults standardUserDefaults] boolForKey:kUserDefaults_WebServerKey_DebugSwitch]) {
        return 50 + [WebServerManager_Debug sharedInstance].webServerView.height;
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
    } else if (indexPath.row == [curArr indexOfObject:kDebugControl_APM]) {
        DebugAlertView *alert = [[DebugAlertView alloc] init];
        __weak typeof(self) weakSelf = self;
        [alert customAlertWithTitle:@"请输入接收APM数据的服务器url" content:nil textFieldPlaceorder:[APM_LogRecorder sharedInstance].receiveUrl? : @"例如：http://192.168.2.1:8808/ios" hostPrefixBtnStrArr:@[@"http://", @"https://", @"www.", @".com"] hostNameBtnStrArr:@[@"查看APM数据上传的数据结构"] bottomBtnStrArr:@[@"取消", @"确定"] bottomBtnTouchedHandler:^(NSInteger index, NSString *inputStr) {
            if (index == 1 && inputStr.length > 3) {
                if ([inputStr rangeOfString:@"://"].location == NSNotFound) {
                    inputStr = [@"http://" stringByAppendingString:inputStr];
                }
                APM_RecorderSetURL(inputStr);
                NSUInteger row = [self.titleArray[1] indexOfObject:kDebugControl_APM];
                [weakSelf.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:row inSection:1]] withRowAnimation:UITableViewRowAnimationNone];
            }

        }];
        
        alert.midBottomBtnBlock = ^(NSInteger index) {
            if (index == 0) { //展示APM上传的数据结构
                NSDictionary *dic = [APM_LogTraceless getDemoDataStructure];
                [[UIApplication sharedApplication].keyWindow showAlertWithMessage:[[dic yy_modelDescription] encodeFormat]];
            }
        };

    }
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
        self.backgroundColor = [UIColor whiteColor];
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
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kUserDefaults_WebServerKey_DebugSwitch] && _moduleType == kDebug_ModuleType_WebServer) {
        WebServerManager_Debug *ws_Obj = [WebServerManager_Debug sharedInstance];
        if (ws_Obj.webServerURL_Array.count > 0) {
            UIView *view = [ws_Obj customWebServerView];
            if(view.superview) [view removeFromSuperview];
            [self addSubview:view];
        } else {
            [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kUserDefaults_WebServerKey_DebugSwitch];
            self.debugSwitch.on = NO;
        }
        
    }

}

- (void)layoutSubviews {
    [super layoutSubviews];
    _titleLabel.left = 10;
    _titleLabel.centerY = _moduleType == kDebug_ModuleType_WebServer ? 50/2 : self.height/2;
    _titleLabel.width =  [UIScreen mainScreen].bounds.size.width - 20;
    
    _debugSwitch.left = self.width - _debugSwitch.width - 10;
    _debugSwitch.centerY = _titleLabel.centerY;
    
    [WebServerManager_Debug sharedInstance].webServerView.frame = CGRectMake(0, self.debugSwitch.bottom + 5, self.width, self.height - self.debugSwitch.bottom - 10);
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - private SEL
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
    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, 60, [UIScreen mainScreen].bounds.size.width - 20)];
    _titleLabel.numberOfLines = 2;
    _titleLabel.textColor = [UIColor blackColor];
    [self.contentView addSubview:_titleLabel];
    
    self.debugSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(100, 10, 50, 34)];
    [_debugSwitch addTarget:self action:@selector(changeState) forControlEvents:UIControlEventValueChanged];
    [self.contentView addSubview:_debugSwitch];
    
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
          
        case kDebug_ModuleType_WebServer://Web调试
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
    [[NSUserDefaults standardUserDefaults] setBool:state forKey:kUserDefaults_WebServerKey_DebugSwitch];
    WebServerManager_Debug *ws_Obj = [WebServerManager_Debug sharedInstance];
    if (state) {
        [ws_Obj run];
        [self addSubview:[ws_Obj customWebServerView]];
    } else {
        [ws_Obj stop];
        [ws_Obj.webServerView removeFromSuperview];
        ws_Obj.webServerView = nil;
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

