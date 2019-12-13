//
//  APM_LogTraceless.m
//  FastDevTools
//
//  Created by TimmyYan on 2019/12/13.
//

#import "APM_LogTraceless.h"
#import "APM_LogRecorder.h"
#import <objc/runtime.h>
#import <WebKit/WebKit.h>

#import <YYModel/YYModel.h>

@interface APM_LogTraceless ()

@property (nonatomic, assign) BOOL isRunning;
@property (nonatomic, strong) dispatch_queue_t safeQueue;

@end

@implementation APM_LogTraceless

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
    
    Method apm_viewWillAppearMethod = class_getInstanceMethod([self class], @selector(apm_viewWillAppear:));
    if (apm_addMethod(UIViewController.class, @selector(apm_viewWillAppear:), apm_viewWillAppearMethod)) {
        apm_swizzleSelector(UIViewController.class, @selector(viewWillAppear:), @selector(apm_viewWillAppear:));
    }
    
    Method apm_viewWillDisappearMethod = class_getInstanceMethod([self class], @selector(apm_viewWillDisappear:));
    if (apm_addMethod(UIViewController.class, @selector(apm_viewWillDisappear:), apm_viewWillDisappearMethod)) {
        apm_swizzleSelector(UIViewController.class, @selector(viewWillDisappear:), @selector(apm_viewWillDisappear:));
    }
}

#pragma mark - public SEL
+ (instancetype)sharedInstance {
    static APM_LogTraceless *apmLogger_ = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        apmLogger_ = [[APM_LogTraceless alloc] init];
        apmLogger_.safeQueue = dispatch_queue_create("com.apm.traceless", DISPATCH_QUEUE_SERIAL);
    });
    return apmLogger_;
}

- (void)startAPMLogTraceless {
    self.isRunning = YES;
}

- (void)stopAPMLogTraceless {
    self.isRunning = NO;
}

#pragma mark - private SEL
- (void)apm_viewWillAppear:(BOOL)animated {
    if ([APM_LogTraceless sharedInstance].isRunning) {
        NSString *className = NSStringFromClass([self class]);
        
        if ([[APM_LogTraceless sharedInstance] shouldTrackWithController:(UIViewController *)self]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"apm_viewDidAppear：%@", className);
               
                NSDictionary *param = nil;
                UIViewController *vc = (UIViewController *)self;
                for (UIView *view in vc.view.subviews) {
                    if ([view isKindOfClass:[WKWebView class]] ) {
                        param = @{@"webUrl":[(WKWebView *)view URL].absoluteString, @"viewClass":NSStringFromClass([view class]), @"webCoreTyepe" : @"WKWebView"};
                        break;
                    }
                    
                    if ([view isKindOfClass:[UIWebView class]]) {
                        param = @{@"webUrl":[(UIWebView *)view request].URL.absoluteString, @"viewClass":NSStringFromClass([view class]), @"webCoreTyepe" : @"UIWebView"};
                        break;
                    }
                }
                [[APM_LogRecorder sharedInstance] logRecordWithName:NSStringFromClass([self class]) param:@{@"func" : @"viewWillAppear"} interval:5 dataHandler:^(APMDataModel *apmData) { //TODO：实时绘制性能图表
                    NSLog(@"%@", [APM_LogTraceless dictionaryWithJsonString:[apmData yy_modelToJSONString]]);
                }];
            });
        }
        
    }
    
    [self apm_viewWillAppear:animated];
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

- (void)apm_viewWillDisappear:(BOOL)animated {
    if ([APM_LogTraceless sharedInstance].isRunning) {
        NSString *className = NSStringFromClass([self class]);
        if ([[APM_LogTraceless sharedInstance] shouldTrackWithController:(UIViewController *)self]) {
            dispatch_async([APM_LogTraceless sharedInstance].safeQueue, ^{
                NSLog(@"apm_viewDidDisappear：%@", className);
                APM_RecordStop();
            });
            
        }

    }
    
    [self apm_viewWillDisappear:animated];
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
