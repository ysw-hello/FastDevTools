//
//  APM_LogTraceless.m
//  FastDevTools
//
//  Created by TimmyYan on 2019/12/13.
//

#import "APM_LogTraceless.h"
#import "APM_LogRecorder.h"
#import "APMDataModel.h"

#import <objc/runtime.h>
#import <WebKit/WebKit.h>

#import <YYModel/YYModel.h>

@interface APM_LogTraceless ()

@property (nonatomic, assign) BOOL isRunning;
@property (nonatomic, strong) dispatch_queue_t safeQueue;
@property (nonatomic, strong) PageModel_APM *pageModel;

@end

@implementation APM_LogTraceless

#pragma mark - swizzle
static inline void apm_swizzleSelector(Class theClass, SEL originalSelector, SEL swizzledSelector) {
    Method originalMethod = class_getInstanceMethod(theClass, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(theClass, swizzledSelector);
    method_exchangeImplementations(originalMethod, swizzledMethod);
}

static inline BOOL apm_addMethod(Class theClass, SEL selector, Method method) {
    return class_addMethod(theClass, selector,  method_getImplementation(method),  method_getTypeEncoding(method));
}

#pragma mark - init
+ (void)initialize {
    [super initialize];
    
    Method apm_viewDidAppearMethod = class_getInstanceMethod([self class], @selector(apm_viewDidAppear:));
    if (apm_addMethod(UIViewController.class, @selector(apm_viewDidAppear:), apm_viewDidAppearMethod)) {
        apm_swizzleSelector(UIViewController.class, @selector(viewDidAppear:), @selector(apm_viewDidAppear:));
    }
    
    Method apm_viewDidDisappearMethod = class_getInstanceMethod([self class], @selector(apm_viewDidDisappear:));
    if (apm_addMethod(UIViewController.class, @selector(apm_viewDidDisappear:), apm_viewDidDisappearMethod)) {
        apm_swizzleSelector(UIViewController.class, @selector(viewDidDisappear:), @selector(apm_viewDidDisappear:));
    }
}

#pragma mark - public SEL
+ (instancetype)sharedInstance {
    static APM_LogTraceless *apmLogger_ = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        apmLogger_ = [[APM_LogTraceless alloc] init];
        apmLogger_.safeQueue = dispatch_queue_create("com.apm.traceless", DISPATCH_QUEUE_SERIAL);
        apmLogger_.pageModel = [PageModel_APM new];
    });
    return apmLogger_;
}

- (void)startAPMLogTraceless {
    self.isRunning = YES;
}

- (void)stopAPMLogTraceless {
    self.isRunning = NO;
}

+ (NSDictionary *)getDemoDataStructure {
    return @{
             @"描述" : @"主要分为app、cpu、device、disk、memory、page六大块数据。\n其中app与device数据，在应用生命周期内只会上传第一次采集。时间戳单位为毫秒(ms),大小单位均为字节(byte)。\n可根据时间戳进行表关联。",
             @"app" : @{
                     @"appBuildNum" : @"1.0.0",
                     @"appBundleID" : @"com.timmy.apm",
                     @"appName" : @"APMTest",
                     @"appVersion" : @"1.0.2",
                     @"curInterval" : @(1577336961404)
                     },
             @"cpu" : @{
                     @"cpuCount" : @(6),
                     @"cpuUsage" : @"0.7080432772636414",
                     @"cpuUsagePerProcessor" : @[
                                            @(0.1878475695848465),
                                            @(0.1516067683696747),
                                            @(0.031938750296831131),
                                            @(0.02829425036907196),
                                            @(0.1725597530603409),
                                            @(0.1357961744070053)
                                            ],
                     @"curInterval" : @(1577336961404),
                     },
             @"device" : @{
                     @"curInterval" : @(1577336961404),
                     @"machineModel_" : @"iPhone10,2",
                     @"machineName_" : @"iPhone 8 Plus",
                     @"systemVersion_" : @"12.1.4"
                     },
             @"disk" : @{
                     @"curInterval" : @(1577336961404),
                     @"diskSpace" : @(255989469184),
                     @"diskSpaceFree" : @(178838278144),
                     @"diskSpaceUsed" : @(77151191040)
                     },
             @"memory" : @{
                     @"curInterval" : @(1577336961404),
                     @"memoryActive" : @(1041809408),
                     @"memoryFree" : @(52871168),
                     @"memoryInactive" : @(1029193728),
                     @"memoryPurgable" : @(146423808),
                     @"memoryTotal" : @(3134406656),
                     @"memoryUsed" : @(2466660352),
                     @"memoryWired" : @(395657216)
                     },
             @"page" : @{
                     @"entryInterval" : @(1577336961404),
                     @"fps" : @(60),
                     @"naFunc" : @"viewDidAppear",
                     @"pageName" : @"APMTestViewController",
                     @"webUrl" : @"https://www.baidu.com",
                     @"viewClass" : @"APMWKWebView",
                     @"webCoreType" : @"WKWebView"
            }
        };

}

#pragma mark - private SEL
- (void)apm_viewDidAppear:(BOOL)animated {
    APM_LogTraceless *apmTraceless = [APM_LogTraceless sharedInstance];
    if (apmTraceless.isRunning) {
        NSString *className = NSStringFromClass([self class]);
        
        if ([apmTraceless shouldTrackWithController:(UIViewController *)self]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"apm_viewDidAppear：%@", className);
               
                UIViewController *vc = (UIViewController *)self;
                //递归subviews获取webview的url
                [apmTraceless fetchURLStrWithView:vc.view];
                
                apmTraceless.pageModel.naFunc = @"viewDidAppear";
                apmTraceless.pageModel.pageName = NSStringFromClass([self class]);
                apmTraceless.pageModel.pageTitle = [vc title]?:@"";
                
                [[APM_LogRecorder sharedInstance] tracelessRecordWithPageModel:apmTraceless.pageModel interval:RecordInterval_APM dataHandler:^(APMDataModel *apmData) { //Native回调
//                    NSLog(@"Native回调APM数据:\n%@", [apmData yy_modelToJSONString]);

                }];
            });
        }
        
    }
    
    [self apm_viewDidAppear:animated];
}

// 递归获取子视图
- (void)fetchURLStrWithView:(UIView *)view{
    NSArray *subviews = [view subviews];
    PageModel_APM *page = [APM_LogTraceless sharedInstance].pageModel;
    page.webUrl = @"";
    page.webCoreType = @"";
    page.viewClass = @"";
    page.webTitle = @"";
    
    if (subviews.count == 0) {
        if ([view isKindOfClass:[WKWebView class]] && [view respondsToSelector:@selector(URL)]) {
            page.webUrl = [(NSURL *)[view performSelector:@selector(URL)] absoluteString];
            page.viewClass = NSStringFromClass([view class]);
            page.webCoreType = @"WKWebView";
            page.webTitle = [(WKWebView *)view title];
            return;
        }
        
        if ([view isKindOfClass:[UIWebView class]] && [view respondsToSelector:@selector(request)]) {
            page.webUrl = [(NSURL *)[(NSURLRequest *)[view performSelector:@selector(request)] URL] absoluteString];
            page.viewClass = NSStringFromClass([view class]);
            page.webCoreType = @"UIWebView";
            page.webTitle = [(UIWebView *)view stringByEvaluatingJavaScriptFromString:@"document.title"];
            return;
        }
        
        return;
    }

    for (UIView *subview in subviews) {
        if ([subview isKindOfClass:[WKWebView class]] && [subview respondsToSelector:@selector(URL)]) {
            page.webUrl = [(NSURL *)[subview performSelector:@selector(URL)] absoluteString];
            page.viewClass = NSStringFromClass([subview class]);
            page.webCoreType = @"WKWebView";
            [(WKWebView *)subview evaluateJavaScript:@"document.title" completionHandler:^(id _Nullable title, NSError * _Nullable error) {
                page.webTitle = title;
            }];
            return;
        }
        
        if ([subview isKindOfClass:[UIWebView class]] && [subview respondsToSelector:@selector(request)]) {
            page.webUrl = [(NSURL *)[(NSURLRequest *)[subview performSelector:@selector(request)] URL] absoluteString];
            page.viewClass = NSStringFromClass([subview class]);
            page.webCoreType = @"UIWebView";
            page.webTitle = [(UIWebView *)subview stringByEvaluatingJavaScriptFromString:@"document.title"];
            return;
        }
        
        [[APM_LogTraceless sharedInstance] fetchURLStrWithView:subview];
    }
    
}

+ (NSDictionary *)dictionaryWithJsonString:(NSString *)jsonString {
    if (!jsonString) {
        return nil;
    }
    
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *err;
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData
                                                        options:NSJSONReadingMutableContainers
                                                          error:&err];
    if(err) {
        NSLog(@"json解析失败：%@",err);
        return nil;
    }
    return dic;
}

- (void)apm_viewDidDisappear:(BOOL)animated {
    if ([APM_LogTraceless sharedInstance].isRunning) {
        NSString *className = NSStringFromClass([self class]);
        if ([[APM_LogTraceless sharedInstance] shouldTrackWithController:(UIViewController *)self]) {
            dispatch_async([APM_LogTraceless sharedInstance].safeQueue, ^{
                NSLog(@"apm_viewDidDisappear：%@", className);
                APM_RecordStop();
            });
            
        }

    }
    
    [self apm_viewDidDisappear:animated];
}

- (BOOL)shouldTrackWithController:(UIViewController *)controller {
    static NSSet *blacklistedClasses = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURL *associateBundleURL = [[NSBundle mainBundle] URLForResource:@"APM_VCBlackList" withExtension:@"bundle"];
        NSAssert(associateBundleURL, @"取不到关联bundle");
        NSBundle *settingsBundle = [NSBundle bundleWithURL:associateBundleURL];
        //文件路径
        NSString *jsonPath = [settingsBundle pathForResource:@"apm_autotrack_viewcontroller_blacklist.json" ofType:nil];
        NSData *jsonData = [NSData dataWithContentsOfFile:jsonPath];
        @try {
            NSArray *blacklistedViewControllerClassNames = [NSJSONSerialization JSONObjectWithData:jsonData  options:NSJSONReadingAllowFragments  error:nil];
            blacklistedClasses = [NSSet setWithArray:blacklistedViewControllerClassNames];
        } @catch(NSException *exception) {  // json加载和解析可能失败
            NSLog(@"%@ error: %@", self, exception);
        }
    });
    
    __block BOOL shouldTrack = YES;
    [blacklistedClasses enumerateObjectsUsingBlock:^(id  _Nonnull obj, BOOL * _Nonnull stop) {
        NSString *blackClassName = (NSString *)obj;
        Class blackClass = NSClassFromString(blackClassName);
        if (blackClass && [controller isKindOfClass:blackClass]) {
            shouldTrack = NO;
            *stop = YES;
        }
    }];
    return shouldTrack;
}


@end
