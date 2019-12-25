//
//  NSObject+Util.m
//  FastDevTools
//
//  Created by TimmyYan on 2019/11/20.
//

#import "NSObject+Util.h"
#import <WebKit/WebKit.h>

@implementation NSObject (Util)

+ (UIViewController *)viewControllerForVeryView:(UIView *)veryView {
    for (UIView *view = veryView; view; view = view.superview) {
        UIResponder *nextResponder = [view nextResponder];
        if ([nextResponder isKindOfClass:[UIViewController class]]) {
            return (UIViewController *)nextResponder;
        }
    }
    return nil;
}

+ (UIViewController *)getCurrentVC {
    UIViewController *viewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    return [self findBestViewController:viewController];
}

+ (UIViewController *)findBestViewController:(UIViewController *)vc {
    if (vc.presentedViewController) {
        return [self findBestViewController:vc.presentedViewController];
    } else if ([vc isKindOfClass:[UISplitViewController class]]) {
        UISplitViewController *svc = (UISplitViewController*)vc;
        if (svc.viewControllers.count > 0) {
            return [self findBestViewController:svc.viewControllers.lastObject];
        } else {
            return vc;
        }
    } else if ([vc isKindOfClass:[UINavigationController class]]) {
        UINavigationController *nvc = (UINavigationController *)vc;
        if (nvc.viewControllers.count > 0) {
            return [self findBestViewController:nvc.topViewController];
        } else {
            return vc;
        }
    } else if ([vc isKindOfClass:[UITabBarController class]]) {
        UITabBarController *tvc = (UITabBarController*)vc;
        if (tvc.viewControllers.count > 0) {
            return [self findBestViewController:tvc.selectedViewController];
        } else {
            return vc;
        }
    } else {
        return vc;
    }
}


+ (WKWebView *)topVCIncludeVeryWebViewClass:(Class)webviewClass {
    UIViewController *vc = [self getCurrentVC];
    __block WKWebView *veryWebView = nil;
    [vc.view.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:webviewClass]) {
            veryWebView = (WKWebView *)obj;
            *stop = YES;
        }
    }];
    return veryWebView;
}

+ (NSDictionary *)ws_dictionaryWithJSON:(id)json {
    if (!json || json == (id)kCFNull) return nil;
    NSDictionary *dic = nil;
    NSData *jsonData = nil;
    if ([json isKindOfClass:[NSDictionary class]]) {
        dic = json;
    } else if ([json isKindOfClass:[NSString class]]) {
        jsonData = [(NSString *)json dataUsingEncoding : NSUTF8StringEncoding];
    } else if ([json isKindOfClass:[NSData class]]) {
        jsonData = json;
    }
    if (jsonData) {
        dic = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:NULL];
        if (![dic isKindOfClass:[NSDictionary class]]) dic = nil;
    }
    return dic;
}

@end
