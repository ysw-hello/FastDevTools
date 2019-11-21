//
//  HybridDebuggerMessageDispatch.m
//  FastDevTools
//
//  Created by TimmyYan on 2019/9/19.
//

#import "HybridDebuggerMessageDispatch.h"
#import "HybridDebuggerDefine.h"
#import "WKWebView+ScriptsInject.h"

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
        [WKWebView prepareJavaScript:[obj objectForKey:@"code"] when:[[obj objectForKey:@"when"] integerValue] key:[obj objectForKey:@"key"]];
    }];
}

- (void)debugCommand:(NSString *)action param:(NSDictionary *)param {
    if (action.length > 0) {
        // 检查当前是否有 ZYBBaseWKWebView 正在展示，如果有则使用此界面，如果没有新开一个页面
        WKWebView *veryWebView = [[self class] topVCIncludeVeryWebViewClass:NSClassFromString(@"ZYBBaseWKWebView")];
        if (!veryWebView && self.block) {
            veryWebView = self.block(action, param);
        }
        
        [self dispathMessageWithVeryWebView:veryWebView action:action param:param?:@{}];
    }
}

#pragma mark - Private SEL
// 保存 weinre 注入脚本的地址，方便在加载其它页面时也能自动注入。
static NSString *kLastWeinreScript = nil;

- (void)dispathMessageWithVeryWebView:(__kindof WKWebView *)veryWebView action:(NSString *)action param:(NSDictionary *)param {
    if ([action isEqualToString:@"eval"]) {
        [veryWebView evalExpression:[param objectForKey:@"code"] completion:^(id  _Nonnull result, NSString * _Nonnull err) {
            NSDictionary *res = nil;
            if (result) {
                res = @{@"result" : [NSString stringWithFormat:@"%@", result]};
            } else {
                res = @{@"error" : [NSString stringWithFormat:@"%@", err]};
            }
            [veryWebView fire:@"eval" param:res];
        }];
        
    } else if ([action isEqualToString:@"list"] && self.listBlock) { // 列出所有支持的action列表
        [veryWebView fire:@"list" param:self.listBlock(veryWebView)];
        
    } else if ([action isEqualToString:@"about"] && self.aboutBlock) {
        NSString *signature = [param objectForKey:@"signature"];
        Class pluginCls = self.aboutBlock(veryWebView, signature);
        SEL targetMethod = debugger_doc_selector(signature);
        NSString *funcName = [@"about." stringByAppendingString:signature];
        if (pluginCls && [pluginCls respondsToSelector:targetMethod]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            NSDictionary *doc = [pluginCls performSelector:targetMethod withObject:nil];
#pragma clang diagnostic pop
            [veryWebView fire:funcName param:doc];
        } else {
            NSString *errMsg = nil;
            if (pluginCls) {
                errMsg = [NSString stringWithFormat:@"The doc of method (%@) is not found!", signature];
            } else {
                errMsg = [NSString stringWithFormat:@"The method (%@) does not exsit!", signature];
            }
            [veryWebView fire:funcName param:@{@"errMsg" : errMsg}];
        }
        
    } else if ([action isEqualToString:@"timing"]) {
        BOOL mobile = [[param objectForKey:@"mobile"] boolValue];
        if (mobile) {
            [veryWebView fire:@"requestToTiming" param:@{}];
        } else {
            [veryWebView evaluateJavaScript:@"window.performance.timing.toJSON()" completionHandler:^(NSDictionary *_Nullable res, NSError * _Nullable error) {
                [veryWebView fire:@"requestToTiming_on_mac" param:res];
            }];
        }

    } else if ([action isEqualToString:@"clearCookie"]) {
        // 清理 WKWebview 的 Cookie，和 NSHTTPCookieStorage 是独立的
        WKHTTPCookieStore * _Nonnull cookieStorage = [WKWebsiteDataStore defaultDataStore].httpCookieStore;
        [cookieStorage getAllCookies:^(NSArray<NSHTTPCookie *> * _Nonnull cookies) {
            [cookies enumerateObjectsUsingBlock:^(NSHTTPCookie * _Nonnull cookie, NSUInteger idx, BOOL * _Nonnull stop) {
                [cookieStorage deleteCookie:cookie completionHandler:nil];
            }];
            [veryWebView fire:@"clearCookieDone" param:@{@"count":@(cookies.count)}];
        }];

    } else if ([action isEqualToString:@"console.log"]) {
        // 正常的日志输出时，不需要做特殊处理。
        // 因为在 invoke 的时候，已经向 debugger Server 发送过日志数据，已经打印过了
        WSLog(@"Browser Command is console.log");
    } else if ([action isEqualToString:@"weinre"]) {
        // $ weinre --boundHost 10.242.24.59 --httpPort 9090
        BOOL disabled = [[param objectForKey:@"disabled"] boolValue];
        if (disabled) {
            kLastWeinreScript = nil;
            [WKWebView removeJavaScriptForKey:@"weinre.js"];
        } else {
            kLastWeinreScript = [param objectForKey:@"url"];
            if (kLastWeinreScript.length > 0) {
                [WKWebView prepareJavaScript:[NSURL URLWithString:kLastWeinreScript] when:WKUserScriptInjectionTimeAtDocumentEnd key:@"weinre.js"];
                [veryWebView fire:@"weinre.enable" param:@{@"jsURL": kLastWeinreScript}];
            }
        }

    } else if ([action isEqualToString:@"testcase"]) {
        // 检查是否有文件生成，如果没有则遍历
//        NSString *docsdir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
//        NSString *file = [docsdir stringByAppendingPathComponent:kHybridAutoTestCaseFileName];
//        if (![[NSFileManager defaultManager] fileExistsAtPath:file]) {
//            [self generatorHtmlWithWebVC:webviewVC];
//        }
//        [webviewVC loadLocalFile:[NSURL fileURLWithPath:file] domain:kHybridAutoTestDomain];

    } else {
        WSLog(@"Command is not yet supported!!!");
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
//- (void)generatorHtmlWithWebView:(__kindof WKWebView *)webView {
//    NSBundle *bundle = [NSBundle bundleWithURL:[[NSBundle mainBundle] URLForResource:kHybridDebuggerBundleName withExtension:@"bundle"]];
//    NSURL *url = [bundle URLForResource:@"testcase" withExtension:@"tmpl"];
//    // 获取模板
//    NSError *err = nil;
//    NSString *template = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:&err];
//    if (template.length > 0 && err == nil) {
//        // 解析
//        WSLog(@"正在解析");
//        int funcAutoTestBaseIdx = 0;
//        int funcNonAutoTestBaseIdx = 0; // 不支持自动化测试的函数
//        NSArray *allClazz = [webView getAllPlugins];
//        NSMutableArray *docsHtml = [NSMutableArray arrayWithCapacity:4];
//        for (Class clazz in allClazz) {
//            NSDictionary* supportFunc = [clazz supportActionList];
//            NSMutableString *html = [NSMutableString stringWithFormat:@"<fieldset><legend>%@</legend><ol>", NSStringFromClass(clazz)];
//
//            for (NSString *func in supportFunc.allKeys) {
//                NSInteger ver =  [[supportFunc objectForKey:func] integerValue];
//                if (ver > 0) {
//                    SEL targetMethod = debugger_doc_selector(func);
//                    if ([clazz respondsToSelector:targetMethod]) {
//#pragma clang diagnostic push
//#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
//                        NSDictionary *doc = [clazz performSelector:targetMethod withObject:nil];
//#pragma clang diagnostic pop
//                        if (doc) {
//                            // 这段代码来自 ruby 工程；
//                            // js 函数的前缀，f_ 开通的为自动化测试函数， nf_ 开通的为手动验证函数
//                            NSString *funcName = @"f_";
//                            NSString *descPrefix = @"";
//                            int funcBaseIdx = 0;
//                            BOOL autoTest = [doc objectForKey:@"autoTest"];
//                            if (autoTest) {
//                                descPrefix = @"<label class=\"f-manual\">[手动]</label>";
//                                funcName = @"nf_";
//                                funcNonAutoTestBaseIdx += 1;
//                                funcBaseIdx = funcNonAutoTestBaseIdx;
//                            } else {
//                                funcAutoTestBaseIdx += 1;
//                                funcBaseIdx = funcAutoTestBaseIdx;
//                            }
//                            NSString *fullFunctionName = [funcName stringByAppendingFormat:@"%ld", (long)funcBaseIdx];
//                            NSString *itemEleId = [@"funcRow_" stringByAppendingString:fullFunctionName];
//
//                            NSString *alertOrNot = @"";
//                            if (![doc objectForKey:@"expectFunc"]) {// 如果没有 expectFunc 默认成功
//                                alertOrNot = [NSString stringWithFormat:@"window.report(true, '%@')", itemEleId];
//                            }
//                            // 缺少插值运算的字符串拼接，让人头大
//                            [html appendFormat:@"<li id=\"%@\">\
//                             <script type=\"text/javascript\">\
//                             function %@(){\
//                             var eleId = '%@';%@; %@;\
//                             }\
//                             </script>\
//                             <a href=\"javascript:void(0);\" onclick=\"%@();return false;\">%@%@, 执行后，%@</a>\
//                             <span>%@</span><label class=\"passed\">✅</label><label class=\"failed\">❌</label>\
//                             </li>",itemEleId, fullFunctionName, itemEleId,[doc objectForKey:@"code"],alertOrNot, fullFunctionName, descPrefix, [doc objectForKey:@"name"], [doc objectForKey:@"expect"], [doc objectForKey:@"discuss"]];
//                        }
//                    }
//                } else {
//                    WSLog(@"The '%@' not activiated", func);
//                }
//            }
//            [html appendString:@"</ol></fieldset>"];
//            [docsHtml addObject:html];
//        }
//        WSLog(@"解析完毕");
//        if (docsHtml.count > 0) {
//            template = [template stringByReplacingOccurrencesOfString:@"{{ALL_DOCS}}" withString:[docsHtml componentsJoinedByString:@""]];
//        }
//
//        NSString *docsdir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
//        NSString *file = [docsdir stringByAppendingPathComponent:kHybridAutoTestCaseFileName];
//        NSError *err = nil;
//        [template writeToFile:file atomically:YES encoding:NSUTF8StringEncoding error:&err];
//        if (err) {
//            WSLog(@"解析文件有错误吗，%@", err);
//        } else {
//            WSLog(@"测试文件生成完毕，%@", file);
//        }
//
//    }
//}

@end
