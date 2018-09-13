//
//  YSW_TextField.m
//  homework
//
//  Created by 闫士伟 on 2018/6/13.
//  Copyright © 2018年 zyb. All rights reserved.
//

#import "YSW_TextField.h"

static CGFloat const LeftMargin = 15;
static CGFloat const CornerRadius = 5;

@implementation YSW_TextField

#pragma mark - init
- (instancetype)initWithFrame:(CGRect)frame delegate:(id)delegate {
    self = [super initWithFrame:frame];
    if (self) {
        self.delegate = delegate;
        [self customUI];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    return [self initWithFrame:frame delegate:nil];
}


#pragma mark - public Methods
- (void)customPlaceHolderWithFont:(UIFont *)font textColor:(UIColor *)textColor text:(NSString *)text {
    NSMutableAttributedString *attStr_ = [[NSMutableAttributedString alloc] initWithString:text attributes:@{NSFontAttributeName : font, NSForegroundColorAttributeName : textColor}];
    self.attributedPlaceholder = attStr_;
}

- (BOOL)formatPhoneNumberWithMarginStr:(NSString *)marginStr shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *text = self.text;
    
    //只能输入数字 ‘添加空格，是为了复制的157 1885 1111格式能ok‘
    NSCharacterSet *characterSet = [NSCharacterSet characterSetWithCharactersInString:@"0123456789 \\b"];
    if ([string rangeOfCharacterFromSet:[characterSet invertedSet]].location != NSNotFound) {
        return NO;
    }

    //去除空格
    string = [string stringByReplacingOccurrencesOfString:@" " withString:@""];
    text = [text stringByReplacingCharactersInRange:range withString:string];
    text = [text stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    NSString *newString = @"";
    
    //取前三位，添加空格
    NSString *subString = [text substringToIndex:MIN(text.length, 3)];
    newString = [newString stringByAppendingString:subString];
    if (subString.length == 3) {
        newString = [newString stringByAppendingString:marginStr];
    }
    
    //取前三位数字之后的数字
    text = [text substringFromIndex:MIN(text.length, 3)];
    if (text.length > 0) {
        //取中间四位，添加空格
        NSString *subString2 = [text substringToIndex:MIN(text.length, 4)];
        newString = [newString stringByAppendingString:subString2];
        if (subString2.length == 4) {
            newString = [newString stringByAppendingString:marginStr];
        }
        //取最后四位
        NSString *subString3 = [text substringFromIndex:MIN(text.length, 4)];
        newString = [newString stringByAppendingString:subString3];
    }
    
    //去除前后非数字 字符 ’去除空格，是为了删除的时候，能删除掉空格‘
    newString = [newString stringByTrimmingCharactersInSet:[[NSCharacterSet characterSetWithCharactersInString:@"0123456789\\b"] invertedSet]];
    
    //判断输入位数不能大于13位，11位手机号+两位空格
    if (newString.length > 13) {
        return NO;
    }
    
    [self setText:newString];
    return NO;
}

- (NSString *)getOriginInputNumStrWithMarginStr:(NSString *)marginStr {
    if ([self.text rangeOfString:marginStr].location != NSNotFound) {
        NSArray *arr = [self.text componentsSeparatedByString:marginStr];
        NSString *originStr = @"";
        for (NSString *subStr in arr) {
            originStr = [originStr stringByAppendingString:subStr];
        }
        return originStr;
    }
    return self.text;
}

- (NSString *)getFormatStrWithOriginStr:(NSString *)originStr marginStr:(NSString *)marginStr {
    NSString *subStr0, *subStr1, *subStr2;
    subStr0 = [[originStr substringToIndex:3] stringByAppendingString:marginStr];
    subStr1 = [[originStr substringWithRange:NSMakeRange(3, 4)] stringByAppendingString:marginStr];
    subStr2 = [originStr substringWithRange:NSMakeRange(originStr.length - 4, 4)];
    
    return [NSString stringWithFormat:@"%@%@%@", subStr0, subStr1, subStr2];
}

#pragma mark - private methods
- (void)customUI {
    self.layer.masksToBounds = YES;
    self.layer.cornerRadius = CornerRadius;
    self.backgroundColor = [UIColor colorWithRed:248/255.0 green:248/255.0 blue:248/255.0 alpha:1.0];
}

#pragma mark - reset super methods
//控制text的位置，右移15pt
- (CGRect)textRectForBounds:(CGRect)bounds {
    CGRect inset = CGRectMake(bounds.origin.x + LeftMargin, bounds.origin.y, bounds.size.width - LeftMargin, bounds.size.height);
    return inset;
}

//控制placeholder的位置， 右移15pt
- (CGRect)placeholderRectForBounds:(CGRect)bounds {
    CGRect inset = CGRectMake(bounds.origin.x + LeftMargin, bounds.origin.y, bounds.size.width - LeftMargin, bounds.size.height);
    return inset;
}

//控制光标（编辑区域）的位置， 右移15pt
- (CGRect)editingRectForBounds:(CGRect)bounds {
    CGRect inset = CGRectMake(bounds.origin.x + LeftMargin, bounds.origin.y, bounds.size.width - LeftMargin, bounds.size.height);
    return inset;
}

@end
