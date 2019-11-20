//
//  HybridDebuggerViewController.h
//  ZYBHybrid
//
//  Created by TimmyYan on 2019/8/16.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class HybridDebuggerViewController;

@protocol HybridDebuggerViewDelegate <NSObject>
@optional
- (void)onCloseWindow:(HybridDebuggerViewController *)viewController;
- (void)fetchData:(HybridDebuggerViewController *)viewController completion:(void (^)(NSArray<NSString *> *))completion;

@end

@interface HybridDebuggerViewController : UIViewController

@property (nonatomic, weak) id<HybridDebuggerViewDelegate> debugViewDelegate;

- (void)showNewLine:(NSArray<NSString *> *)line;

- (void)onWindowHide;
- (void)onWindowShow;

@end

NS_ASSUME_NONNULL_END
