//
//  NSObject+Util.h
//  FastDevTools
//
//  Created by TimmyYan on 2019/11/20.
//

#import <Foundation/Foundation.h>

@class WKWebView;

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (Util)

+ (__kindof UIViewController *)getCurrentVC;
+ (__kindof UIViewController *)viewControllerForVeryView:(__kindof UIView *)veryView;
+ (__kindof WKWebView *)topVCIncludeVeryWebViewClass:(Class)webviewClass;
+ (NSDictionary *)ws_dictionaryWithJSON:(id)json;

@end

NS_ASSUME_NONNULL_END
