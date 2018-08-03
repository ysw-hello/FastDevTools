//
//  DataFetch_ContentView.h
//  DebugController
//
//  Created by 闫士伟 on 2018/8/2.
//  Copyright © 2018年 com.ysw. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DataFetch_Model;

@interface DataFetchCell : UITableViewCell
@property (nonatomic, strong) DataFetch_Model *model;

@end


@interface DataFetch_ContentView : UIView

@property (nonatomic, strong) NSArray *dataArray;

@end



