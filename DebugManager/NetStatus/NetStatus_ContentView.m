//
//  NetStatus_ContentView.m
//  FastDevTools
//
//  Created by TimmyYan on 2018/12/12.
//

#import "NetStatus_ContentView.h"
#import "NetStatus_Debug.h"
#import "UIView+Debug_Additions.h"

@interface NetStatus_ContentView () <UITextFieldDelegate>

/**
 要诊断的域名 输入框
 */
@property (nonatomic, strong) UITextField *txtfield_dormain;

/**
 开始诊断 按钮
 */
@property (nonatomic, strong) UIButton *btn;

/**
 诊断结果
 */
@property (nonatomic, strong) UITextView *txtView_log;

/**
 网络状态
 */
@property (nonatomic, strong) UILabel *netStatusLabel;

/**
 上传速度
 */
@property (nonatomic, strong) UILabel *uploadSpeedLabel;
/**
 下载速度
 */
@property (nonatomic, strong) UILabel *downloadSpeedLabel;

@end

@implementation NetStatus_ContentView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        UIPanGestureRecognizer *panGes = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
        [self addGestureRecognizer:panGes];
        [self customTitle];
        [self customButtonWithFrame:CGRectMake(self.width - 60, 15, 50, 28) selector:@selector(close) title:@"关闭" superView:self];
        
        //网络状态相关
        [self monitorNetStatus];
        
        //网速相关
        [self monitorNetSpeed];
        
        //网络诊断分析
        [self monitorNetService];

    }
    return self;
}

#pragma mark - private SEL
- (void)customTitle {
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 15, 100, 30)];
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.text = @"网络分析监测";
    titleLabel.font = [UIFont systemFontOfSize:25];
    [titleLabel sizeToFit];
    titleLabel.centerX = self.centerX;
    [self addSubview:titleLabel];
}

- (UIButton *)customButtonWithFrame:(CGRect)frame selector:(SEL)selector title:(NSString *)title superView:(UIView *)superView{
    UIButton *button = [[UIButton alloc] initWithFrame:frame];
    button.backgroundColor = [UIColor clearColor];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [button setTitle:title forState:UIControlStateNormal];
    [button addTarget:self action:selector forControlEvents:UIControlEventTouchUpInside];
    button.titleLabel.font = [UIFont systemFontOfSize:15];
    button.layer.borderColor = [UIColor whiteColor].CGColor;
    button.layer.borderWidth = 1;
    button.layer.masksToBounds = YES;
    button.layer.cornerRadius = 5;
    [superView addSubview:button];
    return button;
}

- (void)close {
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:KUserDefaults_NetMonitorKey_DebugSwitch];
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotif_Name_NetStatusContentRemoved object:nil];
    [self removeFromSuperview];
    
}
- (void)pan:(UIPanGestureRecognizer *)panGes {
    CGPoint translation = [panGes translationInView:self];
    panGes.view.center = CGPointMake(panGes.view.center.x + translation.x, panGes.view.center.y + translation.y);
    [panGes setTranslation:CGPointZero inView:self];
}

- (void)monitorNetStatus {
    //UI处理
    _netStatusLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 64 + 10, self.width - 20, 20)];
    _netStatusLabel.textColor = [UIColor whiteColor];
    _netStatusLabel.text = @"当前联网状态为：--";
    _netStatusLabel.font = [UIFont systemFontOfSize:16];
    _netStatusLabel.textAlignment = NSTextAlignmentLeft;
    [self addSubview:_netStatusLabel];
    
    //数据逻辑处理
    __weak typeof(self) weakSelf = self;
    [[NetStatus_Debug sharedInstance] startMonitorNetStateWithBlock:^(NSReachabilityStatus status, NSWWANAccessType wwanType, BOOL isVpnOn) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        NSString *netStatus = @"";
        if (status == NetStatusViaWWAN) {
            switch (wwanType) {
                case NSWWANType4G:
                    netStatus = @"4G";
                    break;
                    
                case NSWWANType3G:
                    netStatus = @"3G";
                    break;
                    
                case NSWWANType2G:
                    netStatus = @"2G";
                    break;
                    
                default:
                    netStatus = @"未知蜂窝网类型";
                    break;
            }
        } else if (status == NetStatusViaWiFi) {
            netStatus = @"WiFi";
        } else {
            netStatus = @"网络连接异常";
        }
        if (isVpnOn) {
            netStatus = [netStatus stringByAppendingString:@"(VPN已开启)"];
        }
        
        strongSelf.netStatusLabel.text = [NSString stringWithFormat:@"当前联网状态为: %@", netStatus];
    }];
}

- (void)monitorNetSpeed {
    //UI处理
    CGFloat margin = 10;
    CGFloat width = (self.width - margin*3) / 2;
    CGFloat height = 30;
    CGFloat top = 64 + 40;
    
    _downloadSpeedLabel = [[UILabel alloc] initWithFrame:CGRectMake(margin, top, width, height)];
    _downloadSpeedLabel.textColor = [UIColor whiteColor];
    _downloadSpeedLabel.text = @"下载速度:0.00KB/s";
    _downloadSpeedLabel.font = [UIFont systemFontOfSize:16];
    _downloadSpeedLabel.textAlignment = NSTextAlignmentLeft;
    [self addSubview:_downloadSpeedLabel];
    
    _uploadSpeedLabel = [[UILabel alloc] initWithFrame:CGRectMake(margin + width + margin, top, width, height)];
    _uploadSpeedLabel.textColor = [UIColor whiteColor];
    _uploadSpeedLabel.text = @"上传速度:0.00KB/s";
    _uploadSpeedLabel.font = [UIFont systemFontOfSize:16];
    _uploadSpeedLabel.textAlignment = NSTextAlignmentLeft;
    [self addSubview:_uploadSpeedLabel];
    
    //数据逻辑处理
    __weak typeof(self) weakSelf = self;
    [[NetStatus_Debug sharedInstance] startMonitorNetSpeedWithBlock:^(CGFloat dSpeed, CGFloat uSpeed) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        strongSelf.downloadSpeedLabel.text = [NSString stringWithFormat:@"下载速度:%.2fKB/s", dSpeed];
        strongSelf.uploadSpeedLabel.text = [NSString stringWithFormat:@"上传速度:%.2fKB/s", uSpeed];
    }];
}

- (void)monitorNetService {
    //UI处理
    _btn = [UIButton buttonWithType:UIButtonTypeCustom];
    _btn.frame = CGRectMake(10.0f, 150.0f, 100.0f, 50.0f);
    [_btn setBackgroundColor:[UIColor lightGrayColor]];
    [_btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [_btn.titleLabel setTextAlignment:NSTextAlignmentCenter];
    [_btn.titleLabel setNumberOfLines:2];
    [_btn setTitle:@"开始诊断" forState:UIControlStateNormal];
    [_btn addTarget:self action:@selector(startNetDiagnosis) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_btn];
    
    _txtfield_dormain = [[UITextField alloc] initWithFrame:CGRectMake(130.0f, 150.0f, 180.0f, 50.0f)];
    _txtfield_dormain.layer.borderColor = [UIColor lightGrayColor].CGColor;
    _txtfield_dormain.textColor = [UIColor whiteColor];
    _txtfield_dormain.layer.borderWidth = 1.f;
    _txtfield_dormain.delegate = self;
    _txtfield_dormain.returnKeyType = UIReturnKeyDone;
    _txtfield_dormain.text = @"www.zybang.com";
    [self addSubview:_txtfield_dormain];
    
    _txtView_log = [[UITextView alloc] initWithFrame:CGRectZero];
    _txtView_log.layer.borderWidth = 1.f;
    _txtView_log.layer.borderColor = [UIColor lightGrayColor].CGColor;
    _txtView_log.backgroundColor = [UIColor blackColor];
    _txtView_log.textColor = [UIColor whiteColor];
    _txtView_log.font = [UIFont systemFontOfSize:10.f];
    _txtView_log.textAlignment = NSTextAlignmentLeft;
    _txtView_log.scrollEnabled = YES;
    _txtView_log.editable = NO;
    _txtView_log.frame = CGRectMake(2, 210, self.width - 4, self.height - 210 - 2);
    [self addSubview:_txtView_log];
    
}

- (void)startNetDiagnosis {
    [_txtfield_dormain resignFirstResponder];
    
    //数据逻辑处理
    __weak typeof(self) weakSelf = self;
    NetStatus_Debug *netManager = [NetStatus_Debug sharedInstance];
    [netManager startAnalyzeNetServiceWithDormain:_txtfield_dormain.text uid:@"12345678" logStepInfoBlock:^(NSString *logInfo, BOOL isRunning) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        strongSelf.txtView_log.text = logInfo;
        
        if (isRunning) {
            [strongSelf.btn setTitle:@"停止诊断" forState:UIControlStateNormal];
            [strongSelf.btn setBackgroundColor:[UIColor colorWithWhite:0.3 alpha:1.0]];
            [strongSelf.btn setUserInteractionEnabled:NO];
            
        } else {
            [strongSelf.btn setTitle:@"开始诊断" forState:UIControlStateNormal];
            [strongSelf.btn setBackgroundColor:[UIColor lightGrayColor]];
            [strongSelf.btn setUserInteractionEnabled:YES];
            [netManager stopAnalyzeNetService];
        }
        
        
    }];
    
}

#pragma mark - textFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

@end
