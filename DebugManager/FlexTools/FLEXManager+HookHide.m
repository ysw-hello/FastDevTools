//
//  FLEXManager+HookHide.m
//  FastDevTools
//
//  Created by TimmyYan on 2019/4/23.
//

#import "FLEXManager+HookHide.h"
#import <objc/runtime.h>

@implementation FLEXManager (HookHide)

+ (void)load {
    Class objClass = [FLEXManager class];
    if (objClass) {
        Method ori_Method = class_getInstanceMethod(objClass, @selector(hideExplorer));
        Method sw_Method = class_getInstanceMethod(objClass, @selector(debugLog_hideExplorer));
        method_exchangeImplementations(ori_Method, sw_Method);
    }
}

- (void)debugLog_hideExplorer {
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"KUserDefaults_FlexToolsKey_DebugSwitch"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"kNotif_Name_FlexToolsContentRemoved" object:nil];

    [[FLEXManager sharedManager] debugLog_hideExplorer];
}

@end
