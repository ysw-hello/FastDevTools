//
//  WebServerManager_Debug.m
//  FastDevTools
//
//  Created by TimmyYan on 2019/11/18.
//

#import "WebServerManager_Debug.h"
#import "UIView+Debug_Additions.h"
#import "SandBox_Web_Debug.h"
#import <GCDWebServer/GCDWebServerPrivate.h>

@interface WebServerManager_Debug ()

@property (nonatomic, strong) SandBox_Web_Debug *sb_Obj;

@end

@implementation WebServerManager_Debug

+ (instancetype)sharedInstance {
    static WebServerManager_Debug *webServer = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        webServer = [[WebServerManager_Debug alloc] init];
    });
    return webServer;
}

- (NSArray *)run {
    self.webServerURL_Array = [[NSMutableArray alloc] init];
    self.sb_Obj = [[SandBox_Web_Debug alloc] init];
    NSArray *sb_arr = [_sb_Obj sb_run];
    if (sb_arr.count > 0) {
        [_webServerURL_Array addObject:@"本地沙盒Web调试:"];
        [_webServerURL_Array addObjectsFromArray:sb_arr];
    }
    return _webServerURL_Array;
}

- (void)stop {
    [_sb_Obj sb_stop]; //关闭本地沙盒调试
    
    [self.webServerURL_Array removeAllObjects];
    self.webServerURL_Array = nil;
    
}

#pragma mark - private SEL
- (UIView *)customWebServerView {
    if (_webServerURL_Array.count < 1) {
        return nil;
    }
    [self.webServerView removeFromSuperview];
    self.webServerView = [[UIView alloc] initWithFrame:CGRectZero];
    _webServerView.backgroundColor = [UIColor blackColor];
    
    UILabel *sb_title = [self createLabelWithFrame:CGRectMake(10, 10, 100, 20)];
    sb_title.text = [_webServerURL_Array firstObject];
    sb_title.textColor = [UIColor greenColor];
    sb_title.font = [UIFont systemFontOfSize:18];
    [sb_title sizeToFit];
    
    UILabel *webServerURL = [self createLabelWithFrame:CGRectMake(10, sb_title.bottom + 10, 100, 20)];
    NSString *str = @"浏览器访问地址为: ";
    NSMutableAttributedString *att = [[NSMutableAttributedString alloc] initWithString:[str stringByAppendingString:_webServerURL_Array[1]]];
    [att addAttribute:NSForegroundColorAttributeName value:[UIColor cyanColor] range:NSMakeRange(str.length, [_webServerURL_Array[1] length])];
    webServerURL.attributedText = att;
    [webServerURL sizeToFit];
    
    UILabel *webUploaderServerURL = [self createLabelWithFrame:CGRectMake(webServerURL.left, webServerURL.bottom + 5, 100, 20)];
    NSString *str1 = @"WebUploader访问地址为: ";
    NSMutableAttributedString *att1 = [[NSMutableAttributedString alloc] initWithString:[str1 stringByAppendingString:_webServerURL_Array[2]]];
    [att1 addAttribute:NSForegroundColorAttributeName value:[UIColor cyanColor] range:NSMakeRange(str1.length, [_webServerURL_Array[2] length])];
    webUploaderServerURL.attributedText = att1;
    [webUploaderServerURL sizeToFit];
    
    UILabel *webDavServerURL = [self createLabelWithFrame:CGRectMake(webServerURL.left, webUploaderServerURL.bottom + 5, 100, 20)];
    NSString *str2 = @"WebDav服务器地址为: ";
    NSMutableAttributedString *att2 = [[NSMutableAttributedString alloc] initWithString:[str2 stringByAppendingString:_webServerURL_Array[3]]];
    [att2 addAttribute:NSForegroundColorAttributeName value:[UIColor cyanColor] range:NSMakeRange(str2.length, [_webServerURL_Array[3] length])];
    webDavServerURL.attributedText = att2;
    [webDavServerURL sizeToFit];
    
    UILabel *tipsLabel = [self createLabelWithFrame:CGRectMake(webServerURL.left, webDavServerURL.bottom + 5, [UIScreen mainScreen].bounds.size.width, 20)];
    tipsLabel.text = @"温馨提示：WebDav Mac客户端建议使用'Transmit' \n<xclient.info有破解版下载> ";
    tipsLabel.textColor = [UIColor redColor];
    tipsLabel.numberOfLines = 2;
    [tipsLabel sizeToFit];
    [_webServerView addSubview:tipsLabel];
    
    return _webServerView;
}

- (UILabel *)createLabelWithFrame:(CGRect)frame {
    UILabel *label = [[UILabel alloc] initWithFrame:frame];
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont systemFontOfSize:15];
    label.textAlignment = NSTextAlignmentLeft;
    [_webServerView addSubview:label];
    return label;
}



@end
