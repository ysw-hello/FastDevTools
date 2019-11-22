//
//  WKWebView+ScriptsInject.m
//  FastDevTools
//
//  Created by TimmyYan on 2019/11/20.
//

#import "WKWebView+ScriptsInject.h"
#import "HybridDebuggerDefine.h"

@implementation WKWebView (ScriptsInject)

#pragma mark - WKUserScript 脚本注入 <WKWebView 初始化之前>
static NSMutableArray *kHybridCustomJavscripts = nil;
+ (void)prepareJavaScript:(id)script when:(WKUserScriptInjectionTime)injectTime key:(NSString *)key {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kHybridCustomJavscripts = [NSMutableArray arrayWithCapacity:4];
    });
    
    if ([script isKindOfClass:NSString.class]) {
        [self _addJavaScript:script when:injectTime forKey:key];
    } else if ([script isKindOfClass:NSURL.class]){
        NSString * result = NULL;
        NSURL * urlToRequest = (NSURL*)script;
        if(urlToRequest){
            // 这里使用异步下载的方式，也可以使用 stringWithContentOfURL 的方法，同步获取字符串
            // 注意1：http 的资源不会被 https 的网站加载 // upgrade-insecure-requests
            // 注意2：stringWithContentOfURL 获取的 weinre文件，需要设置 ServerURL blabla 的东西
            result = [NSString stringWithFormat:HybridDebugger_ML((function(e){
                e.setAttribute("src",'%@');
                document.getElementsByTagName('body')[0].appendChild(e);
            })(document.createElement('script'));), urlToRequest.absoluteString];
            [self _addJavaScript:result when:injectTime forKey:key];
        }
    } else {
        WSLog(@"fail to inject javascript");
    }
}

+ (void)_addJavaScript:(NSString *)script when:(WKUserScriptInjectionTime)injectTime forKey:(NSString *)key {
    @synchronized (kHybridCustomJavscripts) {
        if (script && key) {
            [kHybridCustomJavscripts addObject:@{
                                                 @"script": script,
                                                 @"when": @(injectTime),
                                                 @"key":key
                                                 }];
        }
    }
}

+ (void)removeJavaScriptForKey:(NSString *)key {
    @synchronized (kHybridCustomJavscripts) {
        [kHybridCustomJavscripts enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj objectForKey:key]) {
                [kHybridCustomJavscripts removeObject:obj];
                *stop = YES;
            }
        }];
    }
}

static NSString *kDebugBridgeSource = nil, *kDebugEvalSource = nil;
+ (void)injectScriptsToUserContent:(WKUserContentController *)userContentController {
    NSBundle *debuggerBundle = [NSBundle bundleWithURL:[[NSBundle mainBundle] URLForResource:kHybridDebuggerBundleName withExtension:@"bundle"]];
    if (kDebugBridgeSource.length < 1) {
        NSURL *jsLibURL = [[debuggerBundle bundleURL] URLByAppendingPathComponent:@"hybrid_debugger_bridge.js"];
        kDebugBridgeSource = [NSString stringWithContentsOfURL:jsLibURL encoding:NSUTF8StringEncoding error:nil];
    }
    [self _addJavaScript:kDebugBridgeSource when:WKUserScriptInjectionTimeAtDocumentStart forKey:@"debuggerBridge.js"];
    
    if (kDebugEvalSource.length < 1) {
        NSURL *evalLibURL = [[debuggerBundle bundleURL] URLByAppendingPathComponent:@"eval.js"];
        kDebugEvalSource = [NSString stringWithContentsOfURL:evalLibURL encoding:NSUTF8StringEncoding error:nil];
    }
    [self _addJavaScript:kDebugEvalSource when:WKUserScriptInjectionTimeAtDocumentEnd forKey:@"eval.js"];
    
    // 注入脚本，用来代替 selfevaluateJavaScript:javaScriptString completionHandler:nil
    // 因为 evaluateJavaScript 的返回值不支持那么多的序列化结构的数据结构，还有内存泄漏的问题
    [kHybridCustomJavscripts enumerateObjectsUsingBlock:^(NSDictionary *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        WKUserScript *cookieScript = [[WKUserScript alloc] initWithSource:[obj objectForKey:@"script"] injectionTime:[[obj objectForKey:@"when"] integerValue] forMainFrameOnly:YES];
        [userContentController addUserScript:cookieScript];
    }];
    
}

#pragma mark - evaluateJavaScript 脚本注入 <WKWebView 初始化之后>
- (void)insertData:(NSDictionary *)json intoPageWithVarName:(NSString *)appProperty {
    NSData *objectOfJSON = nil;
    NSError *contentParseError = nil;
    
    objectOfJSON = [NSJSONSerialization dataWithJSONObject:json options:NSJSONWritingPrettyPrinted error:&contentParseError];
    if (contentParseError == nil && objectOfJSON) {
        NSString *str = [[NSString alloc] initWithData:objectOfJSON encoding:NSUTF8StringEncoding];
        [self executeJavaScriptString:[NSString stringWithFormat:@"if(window.debuggerBridge){window.debuggerBridge.%@ = %@;}", appProperty, str] completionHandler:^(id _Nullable data, NSError * _Nullable error) {
            
        }];
    }
}

- (void)executeJavaScriptString:(NSString *)javaScriptString completionHandler:(void (^ _Nullable)(_Nullable id data, NSError * _Nullable error))completionHandler {
    [self evaluateJavaScript:javaScriptString completionHandler:[completionHandler copy]];
}

- (void)evalExpression:(NSString *)jsCode completion:(void (^)(id result, NSString *err))completion {
    [self evaluateJavaScript:[NSString stringWithFormat:@"window.debugger_eval(%@)", jsCode] completionHandler:^(NSDictionary *data, NSError * _Nullable error) {
        if (completion) {
            completion([data objectForKey:@"result"], [data objectForKey:@"err"]);
        } else {
            NSLog(@"evalExpression result = %@", data);
        }
    }];
}

- (void)fireCallback:(NSString *)callbackKey param:(NSDictionary *)paramDict {
    [self __execScript:callbackKey funcName:@"__callback" param:paramDict];
}

- (void)fire:(NSString *)actionName param:(NSDictionary *)paramDict {
    [self __execScript:actionName funcName:@"__fire" param:paramDict];
}

- (void)__execScript:(NSString *)actionName funcName:(NSString *)funcName param:(NSDictionary *)paramDict {
    if (![paramDict isKindOfClass:[NSDictionary class]]) {
        return;
    }
    
    NSData *objectOfJSON = nil;
    NSError *contentParseError;
    
    objectOfJSON = [NSJSONSerialization dataWithJSONObject:paramDict options:NSJSONWritingPrettyPrinted error:&contentParseError];
    NSString *jsCode = [NSString stringWithFormat:@"window.debuggerBridge.%@('%@',%@);", funcName, actionName, [[NSString alloc] initWithData:objectOfJSON encoding:NSUTF8StringEncoding]];
    jsCode = [jsCode stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    [self executeJavaScriptString:jsCode completionHandler:^(id _Nullable data, NSError * _Nullable error) {
        
    }];
    
    // 通知server 执行的action及param
    [[NSNotificationCenter defaultCenter] postNotificationName:kHybridDebuggerInvokeResponseEvent
                                                        object:@{
                                                                 kHybridDebuggerActionKey: actionName,
                                                                 kHybridDebuggerParamKey: paramDict
                                                                 }];
}

@end
