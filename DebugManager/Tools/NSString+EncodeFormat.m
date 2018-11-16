//
//  NSString+EncodeFormat.m
//  Pods
//
//  Created by TimmyYan on 2018/11/16.
//

#import "NSString+EncodeFormat.h"

@implementation NSString (EncodeFormat)

//格式化字符串及处理编码格式
- (NSString *)encodeFormat {
    if (@available(iOS 8.0, *)) {
        if ([self containsString:@"&"]) {
            NSArray *arr = [self componentsSeparatedByString:@"&"];
            NSMutableArray *mArr = [NSMutableArray array];
            for (NSString *str_ in arr) {
                if ([str_ containsString:@"="]) {
                    NSArray *arr_ = [str_ componentsSeparatedByString:@"="];
                    NSString *subStr = [@"  " stringByAppendingString:[arr_ componentsJoinedByString:@":"]];
                    [mArr addObject:[subStr stringByRemovingPercentEncoding]];
                }
            }
            return [[@"{\n" stringByAppendingString:[mArr componentsJoinedByString:@"\n"]] stringByAppendingString:@"\n}"];
        }
    }
    return self;
}


@end
