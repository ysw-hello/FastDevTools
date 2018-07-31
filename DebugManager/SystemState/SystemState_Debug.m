//
//  SystemState_Debug.m
//  DebugController
//
//  Created by 闫士伟 on 2018/7/31.
//  Copyright © 2018年 com.ysw. All rights reserved.
//

#import "SystemState_Debug.h"
#import "SystemState_DataSource.h"
#import "SystemState_StatusBar.h"
#import "SystemState_Config.h"
#import "UIView+Additions.h"

@interface SystemState_Debug ()

@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, strong) UIWindow *statusBarWindow;

@property (nonatomic, assign) NSTimeInterval lastTimeStamp;
@property (nonatomic, assign) NSInteger countPerFrame;

@property (nonatomic, strong) NSMutableDictionary *configDictionary;
@property (nonatomic, strong) SystemState_StatusBar *fpsStatusBar;

@end

@implementation SystemState_Debug

#pragma mark - init
+ (instancetype)sharedInstance {
    static SystemState_Debug *service = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        service = [[SystemState_Debug alloc] init];
    });
    return service;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _lastTimeStamp = -1;
        _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(envokeDisplayLink:)];
        _displayLink.paused = YES;
        [_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
        
        _fpsStatusBar = [[SystemState_StatusBar alloc] initWithFrame:CGRectMake(0, DeviceIsIphoneX ? 24 : 0, kScreenWidth, 20)];
        
        self.statusBarWindow = [[UIWindow alloc] initWithFrame:_fpsStatusBar.frame];
        _statusBarWindow.hidden = YES;
        _statusBarWindow.backgroundColor = [UIColor blackColor];
        _statusBarWindow.windowLevel = UIWindowLevelStatusBar + 10000;
        [_statusBarWindow addSubview:self.fpsStatusBar];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActiveNotif) name:UIApplicationDidBecomeActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActiveNotif) name:UIApplicationWillResignActiveNotification object:nil];
    }
    return self;
}

- (NSMutableDictionary *)configDictionary {
    if (_configDictionary == nil) {
        _configDictionary = [NSMutableDictionary dictionary];
        [_configDictionary setObject:[SystemState_Config defaultConfigForType:kSystemState_LabelType_CPU] forKey:@(kSystemState_LabelType_CPU)];
        [_configDictionary setObject:[SystemState_Config defaultConfigForType:kSystemState_LabelType_FPS] forKey:@(kSystemState_LabelType_FPS)];
        [_configDictionary setObject:[SystemState_Config defaultConfigForType:kSystemState_LabelType_Memory] forKey:@(kSystemState_LabelType_Memory)];
    }
    return _configDictionary;
}

- (void)dealloc {
    _displayLink.paused = YES;
    [_displayLink removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - private SEL
- (void)envokeDisplayLink:(CADisplayLink *)displaylink {
    if (_lastTimeStamp == -1) {
        _lastTimeStamp = displaylink.timestamp;
        return;
    }
    _countPerFrame ++;
    NSTimeInterval interval = displaylink.timestamp - _lastTimeStamp;
    if (interval < 1) {
        return;
    }
    _lastTimeStamp = displaylink.timestamp;
    CGFloat fps = _countPerFrame / interval;
    _countPerFrame = 0;
    self.fpsStatusBar.fpsLabel.text = [NSString stringWithFormat:@"FPS:%d", (int)round(fps)];
    self.fpsStatusBar.fpsLabel.labelState = [self labelStateWith:kSystemState_LabelType_FPS value:fps];
    
    CGFloat memory = [SystemState_DataSource usedMemoryInMB];
    self.fpsStatusBar.memoryLabel.text = [NSString stringWithFormat:@"Memory:%.2fMB", memory];
    self.fpsStatusBar.memoryLabel.labelState = [self labelStateWith:kSystemState_LabelType_Memory value:memory];
    
    CGFloat cpu = [SystemState_DataSource usedCPUPercent];
    self.fpsStatusBar.cpuLabel.text = [NSString stringWithFormat:@"CPU:%.2f%%", cpu];
    self.fpsStatusBar.cpuLabel.labelState = [self labelStateWith:kSystemState_LabelType_CPU value:cpu];
    
}

- (SystemState_LabelState)labelStateWith:(SystemState_LabelType)type value:(CGFloat)currentValue {
    SystemState_Config *config = [self.configDictionary objectForKey:@(type)];
    if (!config.lessIsBetter) {
        if (currentValue > config.goodThreshold) {
            return kSystemState_LabelState_Good;
        } else if (currentValue > config.warningthreshold) {
            return kSystemState_LabelState_Warning;
        } else {
            return kSystemState_LabelState_Bad;
        }
    } else {
        if (currentValue < config.goodThreshold) {
            return kSystemState_LabelState_Good;
        } else if (currentValue < config.warningthreshold) {
            return kSystemState_LabelState_Warning;
        } else {
            return kSystemState_LabelState_Bad;
        }
    }
}

- (void)applicationDidBecomeActiveNotif {
    _displayLink.paused = NO;
}
- (void)applicationWillResignActiveNotif {
    _displayLink.paused = YES;
}

#pragma mark - public SEL
- (void)run {
    _displayLink.paused = NO;
    self.statusBarWindow.hidden = NO;
}

- (void)stop {
    _displayLink.paused = YES;
    self.statusBarWindow.hidden = YES;
}


@end
