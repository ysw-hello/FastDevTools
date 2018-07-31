//
//  SandBox_Debug.m
//  DebugController
//
//  Created by 闫士伟 on 2018/7/30.
//  Copyright © 2018年 com.ysw. All rights reserved.
//

#import "SandBox_Debug.h"
#import <objc/runtime.h>
#import <FMDB/FMDB.h>
#import "UIView+Additions.h"


/*******************************  逻辑类管理  *******************************/
@interface SandBox_Debug ()

@property (nonatomic, strong) SandBox_ListView *listView;
@property (nonatomic, strong) UIWindow *showWindow;


@end

@implementation SandBox_Debug

+ (instancetype)sharedInstance {
    static SandBox_Debug *debug = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        debug = [SandBox_Debug new];
    });
    
    return debug;
}

- (void)showSandBoxListView {
    self.listView = [[SandBox_ListView alloc] initWithFrame:CGRectMake(0, kStatusBarHeight, kScreenWidth, kScreenHeight - kStatusBarHeight)];
    _listView.tag = SandBox_ListView_Tag;
    _listView.backgroundColor = [UIColor clearColor];
    _listView.alpha = 0.8;
    
    [AppDelegateInstance.rootViewController.view addSubview:_listView];
}

- (void)removeSandBoxListView {
    [self.listView removeFromSuperview];
}

@end




/*******************************  UI层展现  *******************************/
@interface SandBox_ListView () <UITableViewDelegate, UITableViewDataSource, UIDocumentInteractionControllerDelegate>

@property (nonatomic, strong) NSMutableArray *pathArray;
@property (nonatomic, strong) NSArray *nameArray;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UITableView *fileList;
@property (nonatomic, assign) NSInteger row;
@property (nonatomic, strong) UIDocumentInteractionController *controller;
@property (nonatomic, strong) UITextView *textView;


@end

@implementation SandBox_ListView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initNameArray];
        [self initTopView];
        [self initFileList];
        
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
        [self addGestureRecognizer:pan];
        
    }
    return self;
}

#pragma mark - private Methods
- (void)initNameArray {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *path = NSHomeDirectory();
    
    self.pathArray = [NSMutableArray array];
    [self.pathArray addObject:path];
    
    self.nameArray = [fileManager contentsOfDirectoryAtPath:path error:NULL];
}

- (void)initTopView {
    UIView *topView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.width, 44)];
    topView.backgroundColor = [UIColor redColor];
    [self addSubview:topView];
    
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = @"沙盒目录";
    titleLabel.font = [UIFont systemFontOfSize:17];
    titleLabel.textColor = [UIColor whiteColor];
    [titleLabel sizeToFit];
    titleLabel.center = topView.center;
    [topView addSubview:titleLabel];
    self.titleLabel = titleLabel;
    
    [self customButtonWithFrame:CGRectMake(10, 8, 60, 28) selector:@selector(back) title:@"上一级" superView:topView];
    [self customButtonWithFrame:CGRectMake(self.width - 70, 8, 60, 28) selector:@selector(close) title:@"关闭" superView:topView];
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

- (void)back {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (self.pathArray.count > 1) {
        [self.pathArray removeLastObject];
        NSString *nextPath = [self.pathArray lastObject];
        self.nameArray = [fileManager contentsOfDirectoryAtPath:nextPath error:NULL];
        [self.fileList reloadData];
    } else {
        NSLog(@"到头了~");
    }
}

- (void)close {
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kUserDefaults_SandBoxKey_DebugSwitch];
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotif_Name_SandBoxListRemoved object:nil];
    [self removeFromSuperview];
}

- (void)initFileList {
    self.fileList = [[UITableView alloc] initWithFrame:CGRectMake(0, 44, self.width, self.height - 44) style:UITableViewStylePlain];
    _fileList.backgroundColor = [UIColor clearColor];
    _fileList.tableFooterView = [UIView new];
    _fileList.delegate = self;
    _fileList.dataSource = self;
    
    [self addSubview:_fileList];
}

- (void)pan:(UIPanGestureRecognizer *)panGes {
    CGPoint translation = [panGes translationInView:self];
    panGes.view.center = CGPointMake(panGes.view.center.x + translation.x, panGes.view.center.y + translation.y);
    [panGes setTranslation:CGPointZero inView:self];
}


- (NSDictionary *)getAllProperties:(id)obj {
    NSMutableDictionary *props = [NSMutableDictionary dictionary];
    unsigned int outCount, i;
    objc_property_t *properties = class_copyPropertyList([obj class], &outCount);
    for (i = 0; i < outCount; i++) {
        objc_property_t property = properties[i];
        const char *char_f = property_getName(property);
        NSString *propertyName = [NSString stringWithUTF8String:char_f];
        id propertyValue = [obj valueForKey:propertyName];
        if (propertyValue) {
            [props setObject:propertyValue forKey:propertyName];
        }
    }
    free(properties);
    return props;
}

- (void)showContent:(NSString *)content {
    UITextView *textView = [[UITextView alloc] initWithFrame:CGRectMake(0, 1, self.width, self.height-1)];
    NSString *tips = @"温馨提示：双击移除ContentView\n";
    NSMutableAttributedString *arrStr = [[NSMutableAttributedString alloc] initWithString:[tips stringByAppendingString:content]];
    [arrStr addAttributes:@{NSFontAttributeName : [UIFont systemFontOfSize:25], NSForegroundColorAttributeName : [UIColor blueColor]} range:NSMakeRange(0, tips.length)];
    textView.attributedText = arrStr;
    UITapGestureRecognizer *doubleTapGestureRecognizer_ = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTap)];
    [doubleTapGestureRecognizer_ setNumberOfTapsRequired:2];
    [textView addGestureRecognizer:doubleTapGestureRecognizer_];
    [self addSubview:textView];
    self.textView = textView;
    self.alpha = 1.0;
    return;
}
- (void)doubleTap {
    [self.textView removeFromSuperview];
    self.alpha = 0.8;
}

#pragma mark - FileList Delegate & DataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.nameArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellId = @"cellId_SandBox";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.backgroundColor = [UIColor orangeColor];
    }
    cell.textLabel.text = [self.nameArray objectAtIndex:indexPath.row];
    cell.textLabel.minimumScaleFactor = 0.3f;
    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    BOOL isDictionary;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *nextPath = [[self.pathArray lastObject] stringByAppendingPathComponent:[self.nameArray objectAtIndex:indexPath.row]];
    [fileManager fileExistsAtPath:nextPath isDirectory:&isDictionary];
    if (isDictionary) {
        [self.pathArray addObject:nextPath];
        self.nameArray = [fileManager contentsOfDirectoryAtPath:nextPath error:NULL];
        if (_nameArray.count < 1) {
            NSLog(@"空文件夹");
        }
        [tableView reloadData];
        
    } else {
        if (![fileManager isReadableFileAtPath:nextPath]) {
            NSLog(@"没权限读此文件");
            return;
        }
        
        NSString *extersion = [nextPath pathExtension];//文件扩展名
        if ([extersion isEqualToString:@""]) {
            //对象
            NSStringEncoding encoding;
            NSString *test = [NSString stringWithContentsOfFile:nextPath usedEncoding:&encoding error:NULL];
            if (test) {
                [self showContent:test];
            } else {
                @try {
                    id obj = [NSKeyedUnarchiver unarchiveObjectWithFile:nextPath];
                    if (!obj) {
                        NSLog(@"无法识别此文件");
                    } else {
                        [self showContent:[self getAllProperties:obj].description];
                    }
                }
                @catch (NSException *exception) {
                    NSLog(@"无法识别此文件");
                }
                @finally {}
            }
            
        } else if ([extersion isEqualToString:@"txt"]) {
            NSString *str = [NSString stringWithContentsOfFile:nextPath encoding:NSUTF8StringEncoding error:NULL];
            [self showContent:str];
            
        } else if ([extersion isEqualToString:@"plist"]) {
            //plist文件
            NSError *error = nil;
            NSData *data = [NSData dataWithContentsOfFile:nextPath options:NSDataReadingUncached error:&error];
            id plistFile = [NSPropertyListSerialization propertyListWithData:data options:0 format:NULL error:NULL];
            NSData *asXML = [NSPropertyListSerialization dataWithPropertyList:plistFile format:NSPropertyListXMLFormat_v1_0 options:0 error:NULL];
            NSString *asString = [[NSString alloc] initWithData:asXML encoding:NSUTF8StringEncoding];
            
            [self showContent:asString];
            
        } else if ([extersion isEqualToString:@"sqlite"]) {
            //数据库文件
            NSMutableDictionary *tables = [NSMutableDictionary dictionary];
            FMDatabaseQueue *datebaseQueue = [FMDatabaseQueue databaseQueueWithPath:nextPath];
            [datebaseQueue inDatabase:^(FMDatabase * _Nonnull db) {
                FMResultSet *resultSet = [db executeQuery:@"SELECT name FROM sqlite_master WHERE type='table' ORDER BY name"];
                while ([resultSet next]) {
                    [tables setObject:[NSNull null] forKey:[[resultSet resultDictionary] objectForKey:@"name"]];
                }
            }];
            
            for (NSString *name in [tables allKeys]) {
                NSMutableArray *items = [NSMutableArray array];
                [datebaseQueue inDatabase:^(FMDatabase * _Nonnull db) {
                    FMResultSet *set = [db executeQuery:[NSString stringWithFormat:@"SELECT * FROM %@", name]];
                    while ([set next]) {
                        [items addObject:[set resultDictionary]];
                    }
                }];
                [tables setObject:items forKey:name];
            }
            
            NSString *header = [NSString stringWithFormat:@"Count of tables:%lu\n", (unsigned long)tables.allKeys.count];
            [self showContent:[header stringByAppendingString:tables.description]];
            
        } else {
            //其他
            self.row = indexPath.row;
            NSURL *url = [NSURL fileURLWithPath:[[self.pathArray lastObject] stringByAppendingPathComponent:[self.nameArray objectAtIndex:indexPath.row]]];
            self.controller = [UIDocumentInteractionController interactionControllerWithURL:url];
            _controller.delegate = self;
            [self.controller presentOptionsMenuFromRect:CGRectMake(0, 0, 0, 0) inView:self animated:YES];

        }
        
    }
}

#pragma mark - UIDocumentInteractionControllerDelegate
- (UIViewController *)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *)controller {
    return AppDelegateInstance.rootViewController;
}

- (CGRect)documentInteractionControllerRectForPreview:(UIDocumentInteractionController *)controller {
    return self.frame;
}

- (UIView *)documentInteractionControllerViewForPreview:(UIDocumentInteractionController *)controller {
    return self;
}
@end
