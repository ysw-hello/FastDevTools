//
//  DataFetch_ContentView.m
//  DebugController
//
//  Created by 闫士伟 on 2018/8/2.
//  Copyright © 2018年 com.ysw. All rights reserved.
//

#import "DataFetch_ContentView.h"
#import "UIView+Additions.h"
#import "DataFetch_Debug.h"

/******************************************************* DataFetchCell  *********************************************************************************/
@interface DataFetchCell ()

@property (nonatomic, strong) UILabel *urlLabel;

@property (nonatomic, strong) UITextView *textView;


@end

@implementation DataFetchCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor blackColor];
        [self configSubviews];
    }
    return self;
}

- (void)setModel:(DataFetch_Model *)model {
    _model = model;
    
    self.urlLabel.text = [NSString stringWithFormat:@"Method: %@, URL: %@", _model.method, _model.URL];
    
    NSString *contentStr = @"";
    if (_model.error) {
        contentStr = [NSString stringWithFormat:@"请求发生错误: %@", _model.error.description];
    } else {
        contentStr = [NSString stringWithFormat:@"短连接请求RequestHeader：\n %@ \n短连接请求RequestBody：\n %@ \n短连接请求ResponseBody：\n %@", _model.requestHeader, _model.requestBody, _model.responseBody];
    }
    self.textView.text = contentStr;
    [self layoutSubviews];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _urlLabel.frame = CGRectMake(10, 0, self.width - 20, 20);
    [_urlLabel sizeToFit];
    _urlLabel.centerY = 44/2;
    _textView.frame = CGRectMake(10, _urlLabel.bottom + 5, self.width - 20, self.height - _urlLabel.bottom - 10);
}

#pragma mark - private SEL
- (void)configSubviews {
    self.urlLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _urlLabel.textColor = [UIColor greenColor];
    _urlLabel.textAlignment = NSTextAlignmentLeft;
    _urlLabel.font = [UIFont systemFontOfSize:15];
    _urlLabel.numberOfLines = 2;
    [self addSubview:_urlLabel];
    
    self.textView = [[UITextView alloc] initWithFrame:CGRectZero];
    _textView.editable = NO;
    _textView.font = [UIFont systemFontOfSize:13];
    _textView.textColor = [UIColor greenColor];
    _textView.backgroundColor = [UIColor clearColor];
    _textView.layer.borderColor = [UIColor blueColor].CGColor;
    _textView.layer.borderWidth = 1;
    [self addSubview:_textView];
    
}

@end


/***************************************************** DataFetch_ContentView *************************************************************************/

@interface DataFetch_ContentView () <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray <__kindof NSIndexPath *> *selectedIndexPaths;

@end

@implementation DataFetch_ContentView

#pragma mark - init
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.selectedIndexPaths = [NSMutableArray array];
        [self configSubviews];
        
        UIPanGestureRecognizer *panGes = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
        [self addGestureRecognizer:panGes];
    }
    return self;
}

#pragma mark - public SEL
-(void)setDataArray:(NSArray *)dataArray {
    _dataArray = dataArray;
    
    [self.tableView reloadData];
}

#pragma mark - private SEL
- (void)pan:(UIPanGestureRecognizer *)panGes {
    CGPoint translation = [panGes translationInView:self];
    panGes.view.center = CGPointMake(panGes.view.center.x + translation.x, panGes.view.center.y + translation.y);
    [panGes setTranslation:CGPointZero inView:self];
}

- (void)configSubviews {
    //header
    UIView *topView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.width, 44)];
    topView.backgroundColor = [UIColor blueColor];
    [self addSubview:topView];
    
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = @"数据接口抓取";
    titleLabel.font = [UIFont systemFontOfSize:17];
    titleLabel.textColor = [UIColor whiteColor];
    [titleLabel sizeToFit];
    titleLabel.center = topView.center;
    [topView addSubview:titleLabel];

    [self customButtonWithFrame:CGRectMake(10, 8, 70, 28) selector:@selector(backTop) title:@"BackTop" superView:topView];
    [self customButtonWithFrame:CGRectMake(self.width - 60, 8, 50, 28) selector:@selector(close) title:@"关闭" superView:topView];
    [self customButtonWithFrame:CGRectMake(self.width - 60 - 55, 8, 50, 28) selector:@selector(clear) title:@"清空" superView:topView];
    
    //tableView
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, topView.height, self.width, self.height - topView.height) style:UITableViewStylePlain];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.tableFooterView = [UIView new];
    _tableView.backgroundColor = [UIColor clearColor];
    
    [self addSubview:_tableView];

}

- (UIButton *)customButtonWithFrame:(CGRect)frame selector:(SEL)selector title:(NSString *)title superView:(UIView *)superView{
    UIButton *button = [[UIButton alloc] initWithFrame:frame];
    button.backgroundColor = [UIColor clearColor];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [button setTitle:title forState:UIControlStateNormal];
    [button addTarget:self action:selector forControlEvents:UIControlEventTouchUpInside];
    button.titleLabel.font = [UIFont systemFontOfSize:15];
    button.layer.borderColor = [UIColor whiteColor].CGColor;
    button.layer.borderWidth = 1;
    button.layer.masksToBounds = YES;
    button.layer.cornerRadius = 5;
    [superView addSubview:button];
    return button;
}

- (void)clear {
    [[DataFetch_Debug sharedInstance].dataArr removeAllObjects];
    [self.tableView reloadData];
}

- (void)backTop {
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
}

- (void)close {
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kUserDefaults_DataFetchKey_DebugSwitch];
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotif_Name_DataFetchContentRemoved object:nil];
    [self removeFromSuperview];

}

#pragma mark - UITableViewDataSource & UITableViewDelegate
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([_selectedIndexPaths containsObject:indexPath]) {
        return tableView.height - 44;
    }
    return 44;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellId = @"DataFetchCell";
    DataFetchCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (!cell) {
        cell = [[DataFetchCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId];
    }
    cell.model = [_dataArray objectAtIndex:indexPath.row];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self.selectedIndexPaths containsObject:indexPath]) {
        [self.selectedIndexPaths removeObject:indexPath];
    } else {
        [tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
        [self.selectedIndexPaths addObject:indexPath];
    }
    [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

@end


