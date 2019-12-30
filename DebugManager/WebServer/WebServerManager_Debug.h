//
//  WebServerManager_Debug.h
//  FastDevTools
//
//  Created by TimmyYan on 2019/11/18.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WebServerManager_Debug : NSObject

@property (nonatomic, strong, nullable) UIView *webServerView;
@property (nonatomic, strong, nullable) NSMutableArray *webServerURL_Array;

+ (instancetype)sharedInstance;

- (UIView *)customWebServerView;
- (NSArray *)run;
- (void)stop;

@end

NS_ASSUME_NONNULL_END
