//
//  YSW_TextField.h
//  homework
//
//  Created by TimmyYan on 2018/6/13.
//  Copyright © 2018年 Timmy. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface YSW_TextField : UITextField

/**
 是否添加“完成”ToolBar default:NO
 */
@property (nonatomic, assign) BOOL needToolBar;


- (instancetype)initWithFrame:(CGRect)frame delegate:(id)delegate;

//定制placeholder 颜色&字体
- (void)customPlaceHolderWithFont:(UIFont *)font textColor:(UIColor *)textColor text:(NSString *)text;

//格式化手机号输入字符 eg:157 1885 0000 在UITextFiled代理方法[- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string;]中调用
- (BOOL)formatPhoneNumberWithMarginStr:(NSString *)marginStr shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string;

//得到原始输入的数据 eg：15718850000
- (NSString *)getOriginInputNumStrWithMarginStr:(NSString *)marginStr;
//根据原始数据得到格式化的数据 eg：15718851421 -> 157 1885 1421
- (NSString *)getFormatStrWithOriginStr:(NSString *)originStr marginStr:(NSString *)marginStr;

@end
