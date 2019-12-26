//
//  DebugAlertView.h
//  DebugController
//
//  Created by TimmyYan on 2018/11/14.
//  Copyright © 2018年 com.ysw. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, DebugAlertType) {
    kDebugAlertType_Default = 0, //默认普通弹窗
    kDebugAlertType_Host = 1 //切换域名弹窗
};

typedef void(^BottomBtnTouchedBlock)(NSInteger index ,NSString *inputStr);
typedef void(^MidBottomBtnTouchedBlock)(NSInteger index);

@interface DebugAlertView : UIView

/**
 二级域名按钮<或底部content>点击block
 */
@property (nonatomic, copy) MidBottomBtnTouchedBlock midBottomBtnBlock;

/**
 切换域名弹窗

 @param title 顶部标题
 @param content 描述文字
 @param textFieldPlaceorder 输入框占位文字
 @param hostPrefixBtnStrArr 环境类型,如qatest，test，线上 <最多传入三种类型>
 @param hostNameBtnStrArr   域名后缀类型,如.baidu.com，线上 <最多传入两种种类型>
 @param bottomBtnStrArr 底部按钮，如取消，确定<最多传入四种类型>
 @param bottomBtnTouchedHandler 传出所点击按钮在bottomBtnStrArr的索引（左->右）以及输入框的内容<底部所有按钮的点击都会移除弹窗>
 @return 带透明背景的全屏view <单击黑色蒙层，弹窗移除>
 */
+ (DebugAlertView *)createAlertWithTitle:(NSString *)title content:(NSString *)content textFieldPlaceorder:(NSString *)textFieldPlaceorder hostPrefixBtnStrArr:(NSArray<__kindof NSString *> *)hostPrefixBtnStrArr hostNameBtnStrArr:(NSArray<__kindof NSString *> *)hostNameBtnStrArr bottomBtnStrArr:(NSArray<__kindof NSString *> *)bottomBtnStrArr bottomBtnTouchedHandler:(BottomBtnTouchedBlock)bottomBtnTouchedHandler;

- (void)customAlertWithTitle:(NSString *)title content:(NSString *)content textFieldPlaceorder:(NSString *)textFieldPlaceorder hostPrefixBtnStrArr:(NSArray<__kindof NSString *> *)hostPrefixBtnStrArr hostNameBtnStrArr:(NSArray<__kindof NSString *> *)hostNameBtnStrArr bottomBtnStrArr:(NSArray<__kindof NSString *> *)bottomBtnStrArr bottomBtnTouchedHandler:(BottomBtnTouchedBlock)bottomBtnTouchedHandler;



- (void)dismissDebugAlert;

@end
