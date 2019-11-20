//
//  HybridDebuggerViewController.m
//  ZYBHybrid
//
//  Created by TimmyYan on 2019/8/16.
//

#import "HybridDebuggerViewController.h"
#import <GCDWebServer/GCDWebServerPrivate.h>
#import "HybridDebuggerDefine.h"

@interface HybridDebuggerViewController () <UITableViewDelegate, UITableViewDataSource>

#pragma mark - Properties
@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong) UIButton *export;
@property (nonatomic, strong) UIButton *refresh;

@property (nonatomic, strong) NSArray<NSString *> *dataSource;

#pragma mark - SEL

@end

CGFloat kDebugHeadeHeight = 46.f;

@implementation HybridDebuggerViewController

#pragma mark - Life Cycle

- (instancetype)init {
    if (self = [super init]) {
        self.dataSource = [NSMutableArray array];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"控制台";
    self.view.backgroundColor = [UIColor blackColor];
    [self.navigationController.navigationBar setBackgroundImage:[[UIImage alloc] init] forBarMetrics:UIBarMetricsDefault];
    //去掉透明后导航栏下边的黑边
    [self.navigationController.navigationBar setShadowImage:[[UIImage alloc] init]];
    self.navigationController.navigationBar.translucent = YES;
    
    [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor],
                                                                      NSFontAttributeName : [UIFont fontWithName:@"Helvetica-Bold" size:17]}];
    [self.view addSubview:self.tableView];
    
    UIBarButtonItem *closeBar = [[UIBarButtonItem alloc] initWithTitle:@"关闭" style:UIBarButtonItemStylePlain target:self action:@selector(close:)];
    self.navigationItem.leftBarButtonItem = closeBar;
    
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    if (@available(iOS 9.0, *)) {
        [self.tableView.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:0].active = YES;
        [self.tableView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor].active = YES;
        [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:0].active = YES;
        [self.tableView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor].active = YES;

    }
    
    // 导出文件按钮在下面的右边
    UIBarButtonItem *exportBar = [[UIBarButtonItem alloc] initWithTitle:@"日志导出" style:UIBarButtonItemStylePlain target:self action:@selector(export:)];
    exportBar.tintColor = [UIColor redColor];
    // 刷新日志按钮在左边
    UIBarButtonItem *refreshBar = [[UIBarButtonItem alloc] initWithTitle:@"刷新" style:UIBarButtonItemStylePlain target:self action:@selector(refresh:)];
    refreshBar.tintColor = [UIColor redColor];
    self.navigationItem.rightBarButtonItems = @[exportBar, refreshBar];

    // 执行定时任务 刷新数据
    [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(refresh:) userInfo:nil repeats:YES];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.tableView.frame = CGRectMake(0, 44 + [[UIApplication sharedApplication] statusBarFrame].size.height, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
}

- (void)dealloc {
    
}

#pragma mark - Setters & Getters
- (UITableView *)tableView {
    if (_tableView == nil) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
        _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth| UIViewAutoresizingFlexibleHeight;
        _tableView.dataSource = self;
        _tableView.delegate = self;
        _tableView.backgroundColor = [UIColor clearColor];
        _tableView.rowHeight = UITableViewAutomaticDimension;
        _tableView.estimatedRowHeight = 50.f;
        _tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0.01)];
        _tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
        //
    }
    return _tableView;
}
#pragma mark - Public SEL
- (void)onWindowHide {
    self.navigationController.navigationBarHidden = YES;
    self.view.hidden = YES;
}

- (void)onWindowShow {
    self.navigationController.navigationBarHidden = NO;
    self.view.hidden = NO;
    if (self.dataSource.count == 0) {
        [self refresh:nil];
    }
}

- (void)showNewLine:(NSArray<NSString *> *)line {
    self.dataSource = [self.dataSource arrayByAddingObjectsFromArray:line];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

#pragma mark - Private SEL
- (void)close:(UIButton *)button {
    if ([self.debugViewDelegate respondsToSelector:@selector(onCloseWindow:)]){
        [self.debugViewDelegate onCloseWindow:self];
    }
}

- (void)export:(UIButton *)button {
    NSString *docsdir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *logFile = [docsdir stringByAppendingPathComponent:kHybridDebuggerLogFile];
    if ([[NSFileManager defaultManager] fileExistsAtPath:logFile]) {
        NSURL *videoURL = [NSURL fileURLWithPath:logFile];
        
        UIActivityViewController *activity = [[UIActivityViewController alloc] initWithActivityItems:@[videoURL] applicationActivities:nil];
        UIPopoverPresentationController *popover = activity.popoverPresentationController;
        if (popover) {
            popover.permittedArrowDirections = UIPopoverArrowDirectionUp;
        }
        [self presentViewController:activity animated:YES completion:NULL];
    }
}

- (void)refresh:(UIButton *)button {
    if ([self.debugViewDelegate respondsToSelector:@selector(fetchData:completion:)]){
        [self.debugViewDelegate fetchData:self completion:^(NSArray<NSString *> * _Nonnull lines) {
            [self showNewLine:lines];
        }];
    }
}

#pragma mark - Protocol Conform
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *kIdentiferOfReuseable = @"kHybridDebuggerCellID";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kIdentiferOfReuseable];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kIdentiferOfReuseable];
        cell.textLabel.numberOfLines = -1;
        cell.backgroundColor = [UIColor clearColor];
        cell.textLabel.textColor = [UIColor greenColor];
        UIView *label = cell.textLabel, *contentView = cell.contentView;
        label.translatesAutoresizingMaskIntoConstraints = NO;
        if (@available(iOS 9.0, *)) {
            [label.topAnchor constraintEqualToAnchor:contentView.topAnchor constant:10].active = YES;
            [label.leftAnchor constraintEqualToAnchor:contentView.leftAnchor constant:10].active = YES;
            [label.bottomAnchor constraintEqualToAnchor:contentView.bottomAnchor constant:-10].active = YES;
            [label.rightAnchor constraintEqualToAnchor:contentView.rightAnchor constant:-10].active = YES;
        }
    }
    
    if (indexPath.row < self.dataSource.count) {
        cell.textLabel.text = [self.dataSource objectAtIndex:indexPath.row];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark - context menu
//允许 Menu菜单
- (BOOL)tableView:(UITableView *)tableView shouldShowMenuForRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

//每个cell都会点击出现Menu菜单
- (BOOL)tableView:(UITableView *)tableView canPerformAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
    if (action == @selector(copy:)) {
        return YES;
    }
    return NO;
}

- (void)tableView:(UITableView *)tableView performAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
    if (action == @selector(copy:)) {
        [UIPasteboard generalPasteboard].string = [self.dataSource objectAtIndex:indexPath.row];
    }
}

@end
