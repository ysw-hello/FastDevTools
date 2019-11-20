//
//  ZYBBaseWebViewController+Utils.h
//  ZYBHybrid
//
//  Created by TimmyYan on 2019/9/26.
//

#import "ZYBBaseWebViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZYBBaseWebViewController (Utils)

/**
 当前支持的Action列表<包含：1.debugger维护的action列表；2.自动/手动注册的插件支持的action列表; 3.额外参数>

 {
 appInfo =     {
 };

 supportFunctionType =     {
    "core_audioDisplay" =         {
        method = "core_audioDisplay:callBack:";
        module = ZYBWebAVideoPlayerPlugin;
    };
    "core_commonData" =         {
        method = "core_commonData:callBack:";
        module = ZYBPluginCommonInfoPlugin;
    };
 }
}
 */
- (NSDictionary *)supportListByNow;

/**
 获取所有插件及其对应的action
 {
 "ZYBWebAVideoPlayerPlugin" = ["core_audioDisplay"];
 "ZYBPluginCommonInfoPlugin" = ["core_commonData"];
 "ZYBWebOpenWindowPlugin" = ["core_openWindow", "core_windowConfig", "core_exit"];
 }
 */
- (NSDictionary <__kindof NSString *, __kindof NSArray <__kindof NSString *> *>*)getPluginAndActionsList;

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
- (NSArray <__kindof Class> *)getAllPlugins;

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
- (NSDictionary <__kindof NSString *, __kindof NSDictionary *> *)getAllSupportedActionsDic;

/**
 根据signature（如：core_commonData），获取相应插件类名（如：ZYBPluginCommonInfoPlugin）
 */
- (Class)getClassForSignature:(NSString *)signature;

@end

NS_ASSUME_NONNULL_END
