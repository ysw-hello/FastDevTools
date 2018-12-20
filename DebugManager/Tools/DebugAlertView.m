//
//  DebugAlertView.m
//  DebugController
//
//  Created by TimmyYan on 2018/11/14.
//  Copyright © 2018年 com.ysw. All rights reserved.
//

#import "DebugAlertView.h"
#import "UIView+Debug_Additions.h"
#import <FastDevTools/YSW_TextField.h>

static NSString *const DefaultStr = @"www.";

@interface DebugAlertView ()

/**
 切换host：hostPrefixBtn数组
 */
@property (nonatomic, strong) NSMutableArray<__kindof UIButton *> *hostPrefixBtnArr;
/**
 切换host：hostNameBtn数组
 */
@property (nonatomic, strong) NSMutableArray<__kindof UIButton *> *hostNameBtnArr;
/**
 域名定制输入框
 */
@property (nonatomic, strong) YSW_TextField *hostTF;
/**
 弹窗主体内容view
 */
@property (nonatomic, strong) UIView *contentAlertView;
/**
 弹窗底部按钮点击回调
 */
@property (nonatomic, copy) BottomBtnTouchedBlock bottomBtnblock;
/**
 底部按钮数组
 */
@property (nonatomic, strong) NSMutableArray<__kindof UIButton *> *bottomBtnArr;


@end

@implementation DebugAlertView

#pragma mark - system init
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        //注册观察键盘变化
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChangedFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];

    }
    return self;
}

#pragma mark - public SEL
- (void)dismissDebugAlert {
    if (self.superview) {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        [self removeFromSuperview];
    }
}

- (void)initAlertWithTitle:(NSString *)title content:(NSString *)content textFieldPlaceorder:(NSString *)textFieldPlaceorder hostPrefixBtnStrArr:(NSArray<__kindof NSString *> *)hostPrefixBtnStrArr hostNameBtnStrArr:(NSArray<__kindof NSString *> *)hostNameBtnStrArr bottomBtnStrArr:(NSArray<__kindof NSString *> *)bottomBtnStrArr bottomBtnTouchedHandler:(BottomBtnTouchedBlock)bottomBtnTouchedHandler{
    self.backgroundColor = [UIColor clearColor];
    [self addSubview:[self createCoverview]];
    self.bottomBtnblock = [bottomBtnTouchedHandler copy];
    //定制subViews
    UIView *contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 300, 250)];
    contentView.backgroundColor = [UIColor whiteColor];
    contentView.center = self.center;
    contentView.layer.cornerRadius = 8;
    [self addSubview:contentView];
    self.contentAlertView = contentView;
    //title
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 15, 100, 16)];
    titleLabel.font = [UIFont boldSystemFontOfSize:18];
    titleLabel.text = title;
    titleLabel.textColor = [UIColor blackColor];
    [titleLabel sizeToFit];
    titleLabel.centerX = contentView.width/2;
    [contentView addSubview:titleLabel];
    //hostPrefixButton
    if (hostPrefixBtnStrArr.count > 0) {
        hostPrefixBtnStrArr = [hostPrefixBtnStrArr arrayByAddingObject:DefaultStr];
    }
    NSInteger count = hostPrefixBtnStrArr.count > 4 ? 4 : hostPrefixBtnStrArr.count;
    NSInteger margin = 15;
    NSInteger btnWidth = (_contentAlertView.width - margin*(count + 1))/count;
    NSInteger btnHeight = 25;
    NSInteger btnTop = titleLabel.bottom + margin;

    self.hostPrefixBtnArr = [NSMutableArray array];
    [self configButtonsWithDataSource:hostPrefixBtnStrArr count:count btnTop:btnTop btnWidth:btnWidth btnHeight:btnHeight margin:margin saveArr:self.hostPrefixBtnArr sel:@selector(hostPrefixBtnClick:)];
    //textfield
    YSW_TextField *textField = [[YSW_TextField alloc] initWithFrame:CGRectMake(margin, btnTop+btnHeight+margin, contentView.width - margin*2, 35)];
    [textField customPlaceHolderWithFont:[UIFont systemFontOfSize:14] textColor:[UIColor lightGrayColor] text:textFieldPlaceorder];
    textField.needToolBar = YES;
    textField.keyboardType = UIKeyboardTypeURL;
    textField.font = [UIFont systemFontOfSize:15];
    textField.textColor = [UIColor blueColor];
    textField.backgroundColor = [UIColor whiteColor];
    textField.layer.cornerRadius = 6;
    textField.layer.borderColor = [UIColor blackColor].CGColor;
    textField.layer.borderWidth = 1;
    [textField addTarget:self action:@selector(hostTFChanged:) forControlEvents:UIControlEventEditingChanged];
    [contentView addSubview:textField];
    self.hostTF = textField;
    //hostNameButton
    self.hostNameBtnArr = [NSMutableArray array];
    count = hostNameBtnStrArr.count > 2 ? 2 :hostNameBtnStrArr.count;
    btnWidth = (_contentAlertView.width - margin*(count + 1))/count;
    btnTop = textField.bottom + margin;
    [self configButtonsWithDataSource:hostNameBtnStrArr count:count btnTop:btnTop btnWidth:btnWidth btnHeight:btnHeight margin:margin saveArr:self.hostNameBtnArr sel:@selector(hostNameBtnClick:)];
    //bottomButton
    self.bottomBtnArr = [NSMutableArray array];
    count = bottomBtnStrArr.count > 4 ? 4 : bottomBtnStrArr.count;
    btnTop = textField.bottom + margin + btnHeight + margin*2;
    btnWidth = (_contentAlertView.width - margin*(count + 1))/count;
    btnHeight = 35;
    [self configButtonsWithDataSource:bottomBtnStrArr count:count btnTop:btnTop btnWidth:btnWidth btnHeight:btnHeight margin:margin saveArr:self.bottomBtnArr sel:@selector(bottomBtnClick:)];
    
    [[UIApplication sharedApplication].keyWindow addSubview:self];
}

+ (DebugAlertView *)createAlertWithTitle:(NSString *)title content:(NSString *)content textFieldPlaceorder:(NSString *)textFieldPlaceorder hostPrefixBtnStrArr:(NSArray<__kindof NSString *> *)hostPrefixBtnStrArr hostNameBtnStrArr:(NSArray<__kindof NSString *> *)hostNameBtnStrArr bottomBtnStrArr:(NSArray<__kindof NSString *> *)bottomBtnStrArr bottomBtnTouchedHandler:(BottomBtnTouchedBlock)bottomBtnTouchedHandler{
    DebugAlertView *alertView = [[DebugAlertView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    [alertView dismissDebugAlert];
    [alertView initAlertWithTitle:title content:content textFieldPlaceorder:textFieldPlaceorder hostPrefixBtnStrArr:hostPrefixBtnStrArr hostNameBtnStrArr:hostNameBtnStrArr bottomBtnStrArr:bottomBtnStrArr bottomBtnTouchedHandler:bottomBtnTouchedHandler];
    return alertView;
}

#pragma mark - private SEL
- (void)configButtonsWithDataSource:(NSArray *)dataSource count:(NSInteger)count btnTop:(NSInteger)btnTop btnWidth:(NSInteger)btnWidth btnHeight:(NSInteger)btnHeight margin:(NSInteger)margin saveArr:(NSMutableArray *)saveArr sel:(SEL)sel{
    for (NSInteger i = 0; i < count ; i++) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = CGRectMake(margin + (btnWidth+margin)*i, btnTop, btnWidth, btnHeight);
        button.titleLabel.font = [UIFont systemFontOfSize:14];
        [button setTitle:dataSource[i] forState:UIControlStateNormal];
        [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [button setTitleColor:[UIColor redColor] forState:UIControlStateHighlighted];
        button.layer.cornerRadius = 4;
        button.layer.borderColor = [UIColor lightGrayColor].CGColor;
        button.layer.borderWidth = 1;
        button.tag = i + 100;
        [button setBackgroundColor:[UIColor whiteColor]];
        [button addTarget:self action:sel forControlEvents:UIControlEventTouchUpInside];
        [_contentAlertView addSubview:button];
        [saveArr addObject:button];
    }
}
- (UIControl *)createCoverview {
    UIControl *corverView = [[UIControl alloc] initWithFrame:[UIScreen mainScreen].bounds];
    corverView.backgroundColor = [UIColor blackColor];
    corverView.alpha = 0.5;
    [corverView addTarget:self action:@selector(dismissDebugAlert) forControlEvents:UIControlEventTouchUpInside];
    return corverView;
}

#pragma mark - actions
//host切换，输入框事件
- (void)hostTFChanged:(YSW_TextField *)textField {
    //TODO：
    
}
//host切换，hostPrefixBtn 点击事件
- (void)hostPrefixBtnClick:(UIButton *)btn {
    [self.hostTF resignFirstResponder];
    for (UIButton *button in self.hostPrefixBtnArr) {
        if (button.tag == btn.tag) {
            button.layer.borderColor = [UIColor redColor].CGColor;
            [button setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
        
            NSString *hostPrefix = button.titleLabel.text;
            self.hostTF.text = [NSString stringWithFormat:@"%@", hostPrefix];
            self.hostTF.keyboardType = [button.titleLabel.text isEqualToString:DefaultStr] ? UIKeyboardTypeURL : UIKeyboardTypeNumberPad;
            [self.hostTF becomeFirstResponder];
        } else {
            button.layer.borderColor = [UIColor lightGrayColor].CGColor;
            [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        }
    }
}
//host切换，hostNameBtn 点击事件
- (void)hostNameBtnClick:(UIButton *)btn {
    for (UIButton *button in self.hostNameBtnArr) {
        if (button.tag == btn.tag) {
            button.layer.borderColor = [UIColor redColor].CGColor;
            [button setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
            if ([_hostTF.text containsString:@"."]) {
                self.hostTF.text = [[[_hostTF.text componentsSeparatedByString:@"."] firstObject] stringByAppendingString:button.titleLabel.text];
            } else {
                self.hostTF.text = [_hostTF.text stringByAppendingString:button.titleLabel.text];
            }
        } else {
            button.layer.borderColor = [UIColor lightGrayColor].CGColor;
            [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        }
    }
    [self.hostTF resignFirstResponder];
}

//底部按钮点击事件
- (void)bottomBtnClick:(UIButton *)btn {
    for (UIButton *button in self.bottomBtnArr) {
        if (button.tag == btn.tag) {
            button.layer.borderColor = [UIColor redColor].CGColor;
            button.backgroundColor = [UIColor redColor];
            [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        } else {
            button.layer.borderColor = [UIColor lightGrayColor].CGColor;
            button.backgroundColor = [UIColor whiteColor];
            [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        }
    }
    
    self.bottomBtnblock(btn.tag-100, self.hostTF.text);
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self dismissDebugAlert];
    });
}

- (void)keyboardWillChangedFrame:(NSNotification *)noti {
    //UIKeyboardFrameEndUserInfoKey  键盘变化结束后的frame
    CGRect endFrame = [[noti.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    float keboardHeiht = endFrame.size.height;//键盘高度
    float duration = [[noti.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    
    CGFloat margin = (kDebug_ScreenHeight - self.contentAlertView.height) / 2;
    if (margin > keboardHeiht) {
        return;
    }
    [UIView animateWithDuration:duration animations:^{
        self.contentAlertView.transform = CGAffineTransformMakeTranslation(0, margin - keboardHeiht);
    }];
}

- (void)keyboardWillHide:(NSNotification *)noti {
    float duration = [[noti.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    [UIView animateWithDuration:duration animations:^{
        self.contentAlertView.transform = CGAffineTransformIdentity;
    }];
    
}


@end
