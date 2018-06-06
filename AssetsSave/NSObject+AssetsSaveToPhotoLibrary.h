//
//  NSObject+AssetsSaveToPhotoLibrary.h
//  testDemo
//
//  Created by 闫士伟 on 2017/7/29.
//  Copyright © 2017年 闫士伟. All rights reserved.



//////////////////////////////////////////////////////////////////////////////////////////////////

/**********************     保存图片或视频到相机胶卷及是否添加到自创建的相册中     ************************/

//////////////////////////////////////////////////////////////////////////////////////////////////

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef void(^CompleteHandler)(NSString *errorDesc);

@interface NSObject (AssetsSaveToPhotoLibrary)

/**
 处理保存回调handler
 */
@property (nonatomic, strong) CompleteHandler handler;


/**
 保存图片到相册
 @param image 要保存的图片
 @param createPhotoCollection 是否创建本应用的相册 默认创建的相册名字为应用在桌面显示的名字
 @param block 处理的回调block
 */
-(void)saveImageToPhotoLibraryWithImage:(UIImage *)image createPhotoCollection:(BOOL)createPhotoCollection completation:(CompleteHandler)block;

/**
 保存视频到相册
 @param videoURL 要保存的视频URL
 @param createPhotoCollection 是否创建本应用的相册 默认创建的相册名字为应用在桌面显示的名字
 @param block 处理的回调block
 */
-(void)saveVideoToPhotoLibraryWithVideoURL:(NSURL *)videoURL createPhotoCollection:(BOOL) createPhotoCollection completation:(CompleteHandler)block;

@end
