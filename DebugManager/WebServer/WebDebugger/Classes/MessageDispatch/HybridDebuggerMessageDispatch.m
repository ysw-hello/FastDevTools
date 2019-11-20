//
//  HybridDebuggerMessageDispatch.m
//  ZYBHybrid
//
//  Created by TimmyYan on 2019/9/19.
//

#import "HybridDebuggerMessageDispatch.h"
#import "HybridDebuggerDefine.h"
#import "ZYBBaseWebViewController+Scripts.h"
#import "ZYBBaseWebViewController+Utils.h"

#import <ZYBHybrid/ZYBHybridUtil.h>
#import <ZYBHybrid/ZYBBaseWebViewController.h>
#import <ZYBHybrid/ZYBBaseWebViewController+LocalFile.h>

#import <YYModel/YYModel.h>

@interface HybridDebuggerMessageDispatch ()

@end

@implementation HybridDebuggerMessageDispatch

#pragma mark - Public SEL
+ (instancetype)sharedInstance {
    static HybridDebuggerMessageDispatch *msgDispatcher = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        msgDispatcher = [[HybridDebuggerMessageDispatch alloc] init];
    });
    return msgDispatcher;
}

- (void)setupDebugger {
    NSMutableArray *scripts = [NSMutableArray arrayWithObjects:
                               @{// 记录 window.DocumentEnd 的时间
                                 @"code": @"window.DocumentEnd =(new Date()).getTime()",
                                 @"when": @(WKUserScriptInjectionTimeAtDocumentEnd),
                                 @"key": @"documentEndTime.js"
                                 },
                               @{// 记录 DocumentStart 的时间
                                 @"code": @"window.DocumentStart = (new Date()).getTime()",
                                 @"when": @(WKUserScriptInjectionTimeAtDocumentStart),
                                 @"key": @"documentStartTime.js"
                                 },
                               @{// 记录 readystatechange 的时间
                                 @"code": @"document.addEventListener('readystatechange', function (event) {window['readystate_' + document.readyState] = (new Date()).getTime();});",
                                 @"when": @(WKUserScriptInjectionTimeAtDocumentStart),
                                 @"key": @"readystatechange.js"
                                 },nil
                               ];
    
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 10.0) {
        [scripts addObject:@{// 重写 console.log 方法
                             @"code": @"window.__debugger_consolelog = console.log; console.log = function(_msg){window.__debugger_consolelog(_msg);debuggerBridge.invoke('console.log', {'text':_msg})}",
                             @"when": @(WKUserScriptInjectionTimeAtDocumentStart),
                             @"key": @"console.log.js"
                             }];
    }
    NSBundle *debuggerBundle = [NSBundle bundleWithURL:[[NSBundle mainBundle] URLForResource:kHybridDebuggerBundleName withExtension:@"bundle"]];
    NSURL *profile = [[debuggerBundle bundleURL] URLByAppendingPathComponent:@"/debugger_profile/profiler.js"];
    NSString *profileTxt = [NSString stringWithContentsOfURL:profile encoding:NSUTF8StringEncoding error:nil];
    // profile
    [scripts addObject:@{
                         @"code": profileTxt?:@"",
                         @"when": @(WKUserScriptInjectionTimeAtDocumentEnd),
                         @"key": @"profile.js"
                         }];
    
    NSURL *timing = [[debuggerBundle bundleURL] URLByAppendingPathComponent:@"/debugger_profile/pageTiming.js"];
    NSString *timingTxt = [NSString stringWithContentsOfURL:timing encoding:NSUTF8StringEncoding error:nil];
    // timing
    [scripts addObject:@{
                         @"code": timingTxt?:@"",
                         @"when": @(WKUserScriptInjectionTimeAtDocumentEnd),
                         @"key": @"timing.js"
                         }];
    
    [scripts enumerateObjectsUsingBlock:^(NSDictionary  * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [ZYBBaseWebViewController prepareJavaScript:[obj objectForKey:@"code"] when:[[obj objectForKey:@"when"] integerValue] key:[obj objectForKey:@"key"]];
    }];
}

- (void)debugCommand:(NSString *)action param:(NSDictionary *)param {
    if (action.length > 0) {
        // 检查当前是否有 ZYBBaseWebViewController 正在展示，如果有则使用此界面，如果没有新开一个页面
        UIViewController *topViewController = [ZYBHybridUtil getCurrentVC];
        if (![topViewController isKindOfClass:ZYBBaseWebViewController.class]) {
            ZYBWebFeatureManager *config = [[ZYBWebFeatureManager alloc] init];
            config.hideNavBar = NO;
            config.hideStatusBar = NO;
            config.staBarStyle = 0;
            
            BOOL is_Core_OpenWindow = NO;
            id codeStr = [param objectForKey:@"code"];
            id urlStr = [param objectForKey:@"pageUrl"];
            if ([codeStr isKindOfClass:[NSString class]] || [urlStr isKindOfClass:[NSString class]]) {
                is_Core_OpenWindow = ([codeStr containsString:@"core_openWindow"] && [codeStr containsString:@"pageUrl"]) || ([action isEqualToString:@"core_openWindow"] && [urlStr hasPrefix:@"http"]);
            }
            if (is_Core_OpenWindow) {
                if ([action isEqualToString:@"core_openWindow"]) {
                    config = [ZYBWebFeatureManager yy_modelWithDictionary:param];
                    NSMutableDictionary *shareDic = [NSMutableDictionary dictionary];
                    [shareDic setValue:@"core_share" forKey:@"action"];
                    [shareDic setValue:[param objectForKey:@"shareData"] forKey:@"param"];
                    config.shareData = [shareDic yy_modelToJSONString];
                }
                
            }
            
            ZYBBaseWebViewController *sam = [[ZYBBaseWebViewController alloc] initWithFeatureConfig:config];
            if (is_Core_OpenWindow) {
               
                if ([action isEqualToString:@"eval"]) { // 切割字符串取 pageURL 的值
                    NSString *str1 = [codeStr componentsSeparatedByString:@"pageUrl"][1];
                    if ([str1 containsString:@"\""]) {
                        urlStr = [str1 componentsSeparatedByString:@"\""][1];
                    }
                }
                
                sam.urlString = [urlStr hasPrefix:@"http"] ? urlStr : @"https://www.baidu.com";
            } else {
                sam.urlString = @"https://www.baidu.com";
            }
            if (!topViewController.navigationController) {
                UIWindow *win = [UIApplication sharedApplication].keyWindow;
                win.rootViewController = sam;
                NSLog(@"Warning, 连 navigation 都没有？");
            } else {
                [topViewController.navigationController pushViewController:sam animated:YES];
            }
            topViewController = sam;
        }
        [self dispathMessageWithWebViewVC:(ZYBBaseWebViewController *)topViewController action:action param:param?:@{}];
    } else {
        NSLog(@"irregular param %@",param);
    }
}

#pragma mark - Private SEL
// 保存 weinre 注入脚本的地址，方便在加载其它页面时也能自动注入。
static NSString *kLastWeinreScript = nil;

- (void)dispathMessageWithWebViewVC:(ZYBBaseWebViewController *)webviewVC action:(NSString *)action param:(NSDictionary *)param {
    if ([action isEqualToString:@"eval"]) {
        [webviewVC evalExpression:[param objectForKey:@"code"] completion:^(id  _Nonnull result, NSString * _Nonnull err) {
            NSDictionary *res = nil;
            if (result) {
                res = @{@"result" : [NSString stringWithFormat:@"%@", result]};
            } else {
                res = @{@"error" : [NSString stringWithFormat:@"%@", err]};
            }
            [webviewVC fire:@"eval" param:res];
        }];
        
    } else if ([action isEqualToString:@"list"]) { // 列出所有支持的action列表
        [webviewVC fire:@"list" param:[webviewVC getPluginAndActionsList]];
        
    } else if ([action isEqualToString:@"about"]) { 
        NSString *signature = [param objectForKey:@"signature"];
        Class pluginCls = [webviewVC getClassForSignature:signature];
        SEL targetMethod = debugger_doc_selector(signature);
        NSString *funcName = [@"about." stringByAppendingString:signature];
        if (pluginCls && [pluginCls respondsToSelector:targetMethod]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            NSDictionary *doc = [pluginCls performSelector:targetMethod withObject:nil];
#pragma clang diagnostic pop
            [webviewVC fire:funcName param:doc];
        } else {
            NSString *errMsg = nil;
            if (pluginCls) {
                errMsg = [NSString stringWithFormat:@"The doc of method (%@) is not found!", signature];
            } else {
                errMsg = [NSString stringWithFormat:@"The method (%@) does not exsit!", signature];
            }
            [webviewVC fire:funcName param:@{@"errMsg" : errMsg}];
        }
        
    } else if ([action isEqualToString:@"timing"]) {
        BOOL mobile = [[param objectForKey:@"mobile"] boolValue];
        if (mobile) {
            [webviewVC fire:@"requestToTiming" param:@{}];
        } else {
            [webviewVC.webView evaluateJavaScript:@"window.performance.timing.toJSON()" completionHandler:^(NSDictionary *_Nullable res, NSError * _Nullable error) {
                [webviewVC fire:@"requestToTiming_on_mac" param:res];
            }];
        }

    } else if ([action isEqualToString:@"clearCookie"]) {
        // 清理 WKWebview 的 Cookie，和 NSHTTPCookieStorage 是独立的
        WKHTTPCookieStore * _Nonnull cookieStorage = [WKWebsiteDataStore defaultDataStore].httpCookieStore;
        [cookieStorage getAllCookies:^(NSArray<NSHTTPCookie *> * _Nonnull cookies) {
            [cookies enumerateObjectsUsingBlock:^(NSHTTPCookie * _Nonnull cookie, NSUInteger idx, BOOL * _Nonnull stop) {
                [cookieStorage deleteCookie:cookie completionHandler:nil];
            }];
            [webviewVC fire:@"clearCookieDone" param:@{@"count":@(cookies.count)}];
        }];

    } else if ([action isEqualToString:@"console.log"]) {
        // 正常的日志输出时，不需要做特殊处理。
        // 因为在 invoke 的时候，已经向 debugger Server 发送过日志数据，已经打印过了
        ZYBHybridLog(@"Browser Command is console.log");
    } else if ([action isEqualToString:@"weinre"]) {
        // $ weinre --boundHost 10.242.24.59 --httpPort 9090
        BOOL disabled = [[param objectForKey:@"disabled"] boolValue];
        if (disabled) {
            kLastWeinreScript = nil;
            [ZYBBaseWebViewController removeJavaScriptForKey:@"weinre.js"];
        } else {
            kLastWeinreScript = [param objectForKey:@"url"];
            if (kLastWeinreScript.length > 0) {
                [ZYBBaseWebViewController prepareJavaScript:[NSURL URLWithString:kLastWeinreScript] when:WKUserScriptInjectionTimeAtDocumentEnd key:@"weinre.js"];
                [webviewVC fire:@"weinre.enable" param:@{@"jsURL": kLastWeinreScript}];
            }
        }

    } else if ([action isEqualToString:@"testcase"]) {
        // 检查是否有文件生成，如果没有则遍历
        NSString *docsdir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
        NSString *file = [docsdir stringByAppendingPathComponent:kHybridAutoTestCaseFileName];
        if (![[NSFileManager defaultManager] fileExistsAtPath:file]) {
            [self generatorHtmlWithWebVC:webviewVC];
        }
        [webviewVC loadLocalFile:[NSURL fileURLWithPath:file] domain:kHybridAutoTestDomain];

    } else {
        ZYBHybridLog(@"Command is not yet supported!!!");
    }
}


#pragma mark - generate html file
/**
 <fieldset>
 <legend>杂项</legend>
 <ol>
 <li id="funcRow_f_1">
 <script type="text/javascript">
 function f_1(){
 var eleId = 'funcRow_f_1'
 NEJsbridge.call('LocalStorage.setItem', '{"key":"BIA_LS_act_bosslike_num","value":"123"}');
 window.report(true, 'funcRow_f_1')
 }
 </script>
 <a href="javascript:void(0);" onclick="f_1();return false;">LocalStorage.setItem, 将 BIA_LS_act_bosslike_num 的值保存为 123</a>
 <span>无</span><label class="passed">✅</label><label class="failed">❌</label>
 </li>
 </ol>
 </fieldset>
 
 */
- (void)generatorHtmlWithWebVC:(ZYBBaseWebViewController *)webVC {
    NSBundle *bundle = [NSBundle bundleWithURL:[[NSBundle mainBundle] URLForResource:kHybridDebuggerBundleName withExtension:@"bundle"]];
    NSURL *url = [bundle URLForResource:@"testcase" withExtension:@"tmpl"];
    // 获取模板
    NSError *err = nil;
    NSString *template = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:&err];
    if (template.length > 0 && err == nil) {
        // 解析
        ZYBHybridLog(@"正在解析");
        int funcAutoTestBaseIdx = 0;
        int funcNonAutoTestBaseIdx = 0; // 不支持自动化测试的函数
        NSArray *allClazz = [webVC getAllPlugins];
        NSMutableArray *docsHtml = [NSMutableArray arrayWithCapacity:4];
        for (Class clazz in allClazz) {
            NSDictionary* supportFunc = [clazz supportActionList];
            NSMutableString *html = [NSMutableString stringWithFormat:@"<fieldset><legend>%@</legend><ol>", NSStringFromClass(clazz)];
            
            for (NSString *func in supportFunc.allKeys) {
                NSInteger ver =  [[supportFunc objectForKey:func] integerValue];
                if (ver > 0) {
                    SEL targetMethod = debugger_doc_selector(func);
                    if ([clazz respondsToSelector:targetMethod]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                        NSDictionary *doc = [clazz performSelector:targetMethod withObject:nil];
#pragma clang diagnostic pop
                        if (doc) {
                            // 这段代码来自 ruby 工程；
                            // js 函数的前缀，f_ 开通的为自动化测试函数， nf_ 开通的为手动验证函数
                            NSString *funcName = @"f_";
                            NSString *descPrefix = @"";
                            int funcBaseIdx = 0;
                            BOOL autoTest = [doc objectForKey:@"autoTest"];
                            if (autoTest) {
                                descPrefix = @"<label class=\"f-manual\">[手动]</label>";
                                funcName = @"nf_";
                                funcNonAutoTestBaseIdx += 1;
                                funcBaseIdx = funcNonAutoTestBaseIdx;
                            } else {
                                funcAutoTestBaseIdx += 1;
                                funcBaseIdx = funcAutoTestBaseIdx;
                            }
                            NSString *fullFunctionName = [funcName stringByAppendingFormat:@"%ld", (long)funcBaseIdx];
                            NSString *itemEleId = [@"funcRow_" stringByAppendingString:fullFunctionName];
                            
                            NSString *alertOrNot = @"";
                            if (![doc objectForKey:@"expectFunc"]) {// 如果没有 expectFunc 默认成功
                                alertOrNot = [NSString stringWithFormat:@"window.report(true, '%@')", itemEleId];
                            }
                            // 缺少插值运算的字符串拼接，让人头大
                            [html appendFormat:@"<li id=\"%@\">\
                             <script type=\"text/javascript\">\
                             function %@(){\
                             var eleId = '%@';%@; %@;\
                             }\
                             </script>\
                             <a href=\"javascript:void(0);\" onclick=\"%@();return false;\">%@%@, 执行后，%@</a>\
                             <span>%@</span><label class=\"passed\">✅</label><label class=\"failed\">❌</label>\
                             </li>",itemEleId, fullFunctionName, itemEleId,[doc objectForKey:@"code"],alertOrNot, fullFunctionName, descPrefix, [doc objectForKey:@"name"], [doc objectForKey:@"expect"], [doc objectForKey:@"discuss"]];
                        }
                    }
                } else {
                    ZYBHybridLog(@"The '%@' not activiated", func);
                }
            }
            [html appendString:@"</ol></fieldset>"];
            [docsHtml addObject:html];
        }
        ZYBHybridLog(@"解析完毕");
        if (docsHtml.count > 0) {
            template = [template stringByReplacingOccurrencesOfString:@"{{ALL_DOCS}}" withString:[docsHtml componentsJoinedByString:@""]];
        }
        
        NSString *docsdir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
        NSString *file = [docsdir stringByAppendingPathComponent:kHybridAutoTestCaseFileName];
        NSError *err = nil;
        [template writeToFile:file atomically:YES encoding:NSUTF8StringEncoding error:&err];
        if (err) {
            ZYBHybridLog(@"解析文件有错误吗，%@", err);
        } else {
            ZYBHybridLog(@"测试文件生成完毕，%@", file);
        }
        
    }
}

@end
