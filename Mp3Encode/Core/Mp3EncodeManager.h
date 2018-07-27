//
//  Mp3EncodeManager.h
//  MediaDemo
//
//  Created by 闫士伟 on 2018/7/26.
//  Copyright © 2018年 com.ysw. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^CompleteBlock)(BOOL ret);

@interface Mp3EncodeManager : NSObject

/**
 采样率 单位为：K
 */
@property (nonatomic, assign) float sampleRate;
/**
 压缩比特率 单位为：K
 */
@property (nonatomic, assign) float bitRate;


+ (instancetype)sharedInstance;

/**
 音频文件转码为Mp3编码文件 默认 采样率sampleRete = 44.1k,压缩的比特率bitRate = 128k

 @param sourcePath 源音频文件路径
 @param resultPath 转换后mp3文件路径
 @param channels 声道 1：为单声道，非1：为双声道
 @param isDelete 是否删除源视频文件
 */
- (void)audioToMp3ForSourcePath:(NSString *)sourcePath resultPath:(NSString *)resultPath channels:(int)channels isDeleteSourchFile:(BOOL)isDelete complete:(CompleteBlock)complete;


@end
