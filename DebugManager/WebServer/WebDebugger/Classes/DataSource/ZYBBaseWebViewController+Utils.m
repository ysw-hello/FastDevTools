//
//  ZYBBaseWebViewController+Utils.m
//  ZYBHybrid
//
//  Created by TimmyYan on 2019/9/26.
//

#import "ZYBBaseWebViewController+Utils.h"
#import "ZYBHybridDefine.h"

@implementation ZYBBaseWebViewController (Utils)

- (NSDictionary *)supportListByNow {
    NSMutableDictionary *supportedFunctions = [NSMutableDictionary dictionary];
#if ZYBHybrid_Debug
    //debugger维护支持列表；
     NSDictionary *debugActions = [@{
                                                 //增加debuggerBridge的supportTypeFunction
                                                 @"pageshow" : @"0",
                                                 @"pagehide" : @"0"
                                                 } mutableCopy];
    [supportedFunctions addEntriesFromDictionary:debugActions];
#endif
                                   
    NSDictionary *supportedActions_Auto = [self.webView.bridge getAllHYRemoteMothods];
    if (supportedActions_Auto) {
        [supportedFunctions addEntriesFromDictionary:supportedActions_Auto];
    }
    NSDictionary *supportdActions_Self = [self.webView.bridge getAllHYLazyMothods];
    if (supportdActions_Self) {
        [supportedFunctions addEntriesFromDictionary:supportdActions_Self];
    }
    
    NSMutableDictionary *lst = [NSMutableDictionary dictionaryWithCapacity:10];
    [lst setObject:supportedFunctions forKey:@"supportFunctionType"];
    
#if ZYBHybrid_Debug
    // 添加额外参数
    NSMutableDictionary *appInfo = [NSMutableDictionary dictionaryWithCapacity:10];
    if (ZYBHybrid_IS_iPhoneX) {
        [appInfo setObject:@{ @"iPhoneXVersion" : @"1" } forKey:@"iPhoneXInfo"];
    }
    [lst setObject:appInfo forKey:@"appInfo"];
#endif
    return lst;
}

/**
 获取所有插件及其对应的action
 {
 "ZYBWebAVideoPlayerPlugin" = ["core_audioDisplay"];
 "ZYBPluginCommonInfoPlugin" = ["core_commonData"];
 "ZYBWebOpenWindowPlugin" = ["core_openWindow", "core_windowConfig", "core_exit"];
 }
 */
- (NSDictionary <__kindof NSString *, __kindof NSArray <__kindof NSString *> *>*)getPluginAndActionsList {
    NSMutableDictionary *finalDic = [NSMutableDictionary dictionary];
    @synchronized (finalDic) {
        // 自动注册相关
        NSDictionary *plugins_Auto = [self.webView.bridge getAllHYRemoteModules];
        NSArray *arr_Auto = [plugins_Auto allKeys];
        if (arr_Auto.count > 0) {
            for (NSString *pluginName in [plugins_Auto allKeys]) {
                NSDictionary *dic = [plugins_Auto objectForKey:pluginName];
                if ([[dic allKeys] containsObject:@"methods"]) {
                    NSDictionary *dic_methods = [dic objectForKey:@"methods"];
                    if ([dic_methods isKindOfClass:[NSDictionary class]] && [dic_methods allKeys] && pluginName) {
                        [finalDic setObject:[dic_methods allKeys] forKey:pluginName];
                    }
                }
            }
        }
        
        // 手动注册相关
        NSDictionary *plugins_Self = [self.webView.bridge getAllHYLazyModules];
        NSArray *arr_Self = [plugins_Self allKeys];
        if (arr_Self.count > 0) {
            for (NSString *pluginName_Self in [plugins_Self allKeys]) {
                NSDictionary *dic_Self = [plugins_Self objectForKey:pluginName_Self];
                if ([[dic_Self allKeys] containsObject:@"methods"]) {
                    NSDictionary *dic_Self_methods = [dic_Self objectForKey:@"methods"];
                    if ([dic_Self_methods isKindOfClass:[NSDictionary class]] && [dic_Self_methods allKeys] && pluginName_Self) {
                        [finalDic setObject:[dic_Self_methods allKeys] forKey:pluginName_Self];
                    }
                }
            }
        }
        
    }
    return finalDic;
}

/**
 根据
 {
 ZYBWebPicBrowserPlugin = {
 methods = {
 core_showImgBrowser = {
 method = "core_showImgBrowser:callBack:";
 module = ZYBWebPicBrowserPlugin;
 };
 };
 };
 }
 获取所有插件的Class数组 [ZYBWebAVideoPlayerPlugin,ZYBPluginCommonInfoPlugin]
 */
- (NSArray <__kindof Class> *)getAllPlugins {
    NSMutableArray *allPlugins = [NSMutableArray array];
    @synchronized (allPlugins) {
        NSArray *plugins_Auto = [[self.webView.bridge getAllHYRemoteModules] allKeys];
        if (plugins_Auto) {
            [allPlugins addObjectsFromArray:plugins_Auto];
        }
        NSArray *plugins_Self = [[self.webView.bridge getAllHYLazyModules] allKeys];
        if (plugins_Self) {
            [allPlugins addObjectsFromArray:plugins_Self];
        }
        
        NSMutableArray *allPluginClasses = [NSMutableArray arrayWithCapacity:allPlugins.count];
        @synchronized (allPluginClasses) {
            for (NSString *classStr in allPlugins) {
                if (classStr.length > 0) {
                    [allPluginClasses addObject:NSClassFromString(classStr)];
                }
            }
            return allPluginClasses;
        }
    }
}

/**
 {
 "core_audioDisplay" =         {
 method = "core_audioDisplay:callBack:";
 module = ZYBWebAVideoPlayerPlugin;
 };
 "core_commonData" =         {
 method = "core_commonData:callBack:";
 module = ZYBPluginCommonInfoPlugin;
 };
 }
 */
- (NSDictionary <__kindof NSString *, __kindof NSDictionary *> *)getAllSupportedActionsDic {
    NSMutableDictionary *supportedFunctions = [NSMutableDictionary dictionary];
    
    @synchronized (supportedFunctions) {
        NSDictionary *supportedActions_Auto = [self.webView.bridge getAllHYRemoteMothods];
        if (supportedActions_Auto) {
            [supportedFunctions addEntriesFromDictionary:supportedActions_Auto];
        }
        
        NSDictionary *supportdActions_Self = [self.webView.bridge getAllHYLazyMothods];
        if (supportdActions_Self) {
            [supportedFunctions addEntriesFromDictionary:supportdActions_Self];
        }
    }
    
    return supportedFunctions;
}

/**
 根据signature（如：core_commonData），获取相应插件类名（如：ZYBPluginCommonInfoPlugin）
 */
- (Class)getClassForSignature:(NSString *)signature {
    if (signature.length < 1) {
        return nil;
    }
    
    NSDictionary *supportedActions = [self getAllSupportedActionsDic];
    NSDictionary *valueDic = [supportedActions objectForKey:signature];
    if (valueDic && [valueDic isKindOfClass:[NSDictionary class]]) {
        NSString *module = [valueDic objectForKey:@"module"];
        if (module.length > 0) {
            return NSClassFromString(module);
        }
    }
    
    return nil;
}

@end
