//
//  DataFetch_Debug.m
//  DebugController
//
//  Created by 闫士伟 on 2018/8/1.
//  Copyright © 2018年 com.ysw. All rights reserved.
//

#import "DataFetch_Debug.h"
#import "AFURLSessionManager+LogAddtions.h"
#import "DataFetch_ContentView.h"
#import "UIView+Additions.h"

@implementation DataFetch_Model

@end


@interface DataFetch_Debug ()
@property (nonatomic, strong) DataFetch_ContentView *contentView;

@end

@implementation DataFetch_Debug

#pragma mark - public SEL
+ (instancetype)sharedInstance {
    static DataFetch_Debug *dataFetcher = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dataFetcher = [DataFetch_Debug new];
        dataFetcher.dataArr = [NSMutableArray array];
        [AFURLSessionManager swizzleTaskRequest];
    });
    return dataFetcher;
}

- (void)setDataArr:(NSMutableArray<__kindof DataFetch_Model *> *)dataArr {
    _dataArr = dataArr;
    if (_dataArr.count > 0) {
        self.contentView.dataArray = _dataArr;
    }
}

- (void)showDataFetchViewWithRootViewController:(UIViewController *)rootViewController {
    
    self.contentView = [[DataFetch_ContentView alloc] initWithFrame:CGRectMake(0, kStatusBarHeight, kScreenWidth, kScreenHeight - kStatusBarHeight)];
    _contentView.tag = DataFetch_ContentView_TAG;
    _contentView.alpha = 0.8;
    _contentView.backgroundColor = [UIColor yellowColor];
    _contentView.dataArray = self.dataArr;
    [rootViewController.view addSubview:_contentView];
}

- (void)hideDataFetchView {
    [self.contentView removeFromSuperview];
    self.contentView = nil;
    
}



@end
