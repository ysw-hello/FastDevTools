//
//  Mp3EncodeManager.m
//  MediaDemo
//
//  Created by 闫士伟 on 2018/7/26.
//  Copyright © 2018年 com.ysw. All rights reserved.
//

#import "Mp3EncodeManager.h"
#include "Mp3Encoder.hpp"

@interface Mp3EncodeManager ()

@end

@implementation Mp3EncodeManager

+ (instancetype)sharedInstance {
    static Mp3EncodeManager *mp3EncodeManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        mp3EncodeManager = [Mp3EncodeManager new];
    });
    return mp3EncodeManager;
    
}

#pragma mark - getters profile
//采样频率是指录音设备在一秒钟内对声音信号的采样次数，采样频率越高声音的还原就越真实越自然。在当今的主流采集卡上，采样频率一般共分为22.05KHz、44.1KHz、48KHz三个等级，22.05 KHz只能达到FM广播的声音品质，44.1KHz则是理论上的CD音质界限，48KHz则更加精确一些。
- (float)sampleRate {
    return _sampleRate < 22.05 ? 44.1 : _sampleRate;
}

- (float)bitRate {
    return _bitRate < 128 ? 128 : _bitRate;
}

#pragma mark - encode process
- (void)audioToMp3ForSourcePath:(NSString *)sourcePath resultPath:(NSString *)resultPath channels:(int)channels isDeleteSourchFile:(BOOL)isDelete complete:(CompleteBlock)complete{
    // 判断输入路径是否存在
    NSFileManager *fm = [NSFileManager defaultManager];
    NSAssert([fm fileExistsAtPath:sourcePath], @"源音频文件不存在");

    Mp3Encoder *encoder = new Mp3Encoder();
    int ret_1 = encoder->processSource([sourcePath UTF8String], [resultPath UTF8String], (float)self.sampleRate, channels, (int)self.bitRate);
    int ret_2 = encoder->encode();
    encoder->destory();
    encoder = nil;

    if (isDelete) {
        NSError *error;
        [fm removeItemAtPath:sourcePath error:&error];
        if (!error) {
            NSLog(@"删除源音频文件成功");
        }
    }

    BOOL ret = ret_1 == 0 && ret_2 == 0 && [fm fileExistsAtPath:resultPath] && [self getFileSize:resultPath] > 0;
    
    [complete copy];
    complete(ret);
}


#pragma 获取文件大小
- (float) getFileSize:(NSString *)path {
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    float filesize = -1.0;
    if ([fileManager fileExistsAtPath:path]) {
        NSDictionary *fileDic = [fileManager attributesOfItemAtPath:path error:nil];//获取文件的属性
        unsigned long long size = [[fileDic objectForKey:NSFileSize] longLongValue];
        filesize = 1.0*size/1024;
    }
    return filesize;
}

@end
