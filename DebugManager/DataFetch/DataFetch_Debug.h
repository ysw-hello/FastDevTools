//
//  DataFetch_Debug.h
//  DebugController
//
//  Created by 闫士伟 on 2018/8/1.
//  Copyright © 2018年 com.ysw. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface DataFetch_Model : NSObject
@property (nonatomic, strong) NSString *method;
@property (nonatomic, strong) NSString *URL;
@property (nonatomic, strong) NSString *requestHeader;
@property (nonatomic, strong) NSString *requestBody;
@property (nonatomic, strong) NSString *responseBody;
@property (nonatomic, strong) NSError  *error;

@end


@interface DataFetch_Debug : NSObject

@property (nonatomic, strong) NSMutableArray <__kindof DataFetch_Model *> *dataArr;

+ (instancetype)sharedInstance;

- (void)showDataFetchViewWithRootViewController:(UIViewController *)rootViewController;
- (void)hideDataFetchView;

@end

