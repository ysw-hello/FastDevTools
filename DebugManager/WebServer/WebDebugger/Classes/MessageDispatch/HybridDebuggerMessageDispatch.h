//
//  HybridDebuggerMessageDispatch.h
//  FastDevTools
//
//  Created by TimmyYan on 2019/9/19.
//

#import <Foundation/Foundation.h>
#import "NSObject+Util.h"

@class WKWebView;

NS_ASSUME_NONNULL_BEGIN

typedef WKWebView * (^CurrentVCNotIncludeVeryWebView_EvalCommand)(NSString *action, NSDictionary *param);
typedef NSDictionary * (^List_EvalCommand_GetPluginAndActionsList)(WKWebView *veryWebView);
typedef Class (^About_EvalCommand_GetPluginClassName)(WKWebView *veryWebView, NSString *actionName)
;
@interface HybridDebuggerMessageDispatch : NSObject

@property (nonatomic, copy) CurrentVCNotIncludeVeryWebView_EvalCommand block;
@property (nonatomic, copy) List_EvalCommand_GetPluginAndActionsList listBlock;
@property (nonatomic, copy) About_EvalCommand_GetPluginClassName aboutBlock;



+ (instancetype)sharedInstance;

- (void)setupDebugger;

- (void)debugCommand:(NSString *)action param:(NSDictionary *)param;

@end

NS_ASSUME_NONNULL_END
