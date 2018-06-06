//
//  NSObject+AssetsSaveToPhotoLibrary.m
//  testDemo
//
//  Created by 闫士伟 on 2017/7/29.
//  Copyright © 2017年 闫士伟. All rights reserved.
//

#import "NSObject+AssetsSaveToPhotoLibrary.h"
#import <objc/runtime.h>
#import <Photos/Photos.h>
#import <AssetsLibrary/AssetsLibrary.h>

#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define iOS_8_0 @"8.0"

//自定义的相簿名字为 应用在桌面显示的名字
#define AssetCollectionName_testDemo   [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"]

@implementation NSObject (AssetsSaveToPhotoLibrary)

#pragma mark - public methods

-(void)saveVideoToPhotoLibraryWithVideoURL:(NSURL *)videoURL createPhotoCollection:(BOOL) createPhotoCollection completation:(CompleteHandler)block{
    [self saveAssetsToLibraryWithAssets:videoURL createPhotoCollection:createPhotoCollection completation:[block copy]];
}

-(void)saveImageToPhotoLibraryWithImage:(UIImage *)image createPhotoCollection:(BOOL)createPhotoCollection completation:(CompleteHandler)block{
    [self saveAssetsToLibraryWithAssets:image createPhotoCollection:createPhotoCollection completation:[block copy]];
}

#pragma mark - private methods
-(void)saveAssetsToLibraryWithAssets:(id)assets createPhotoCollection:(BOOL) createPhotoCollection completation:(CompleteHandler)block{
    if (SYSTEM_VERSION_GREATER_THAN(iOS_8_0)) {
        //iOS 8.0+ 保存处理方式 --可以生产自定义相册
        [self saveImageByPhotos_libWithAssets:assets createPhotoCollection:createPhotoCollection completation:[block copy]];
    }else{
        //iOS 8.0 && iOS 8.0- 保存处理方式  --不能生成自定义相册
        [self saveImageByAssets_libWithAssets:assets completation:[block copy]];
    }

}

-(void)saveImageByAssets_libWithAssets:(id)assets completation:(CompleteHandler)block{
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    ALAuthorizationStatus status = [ALAssetsLibrary authorizationStatus];
    if (status == ALAuthorizationStatusDenied) {
        block(@"用户拒绝当前应用访问相册");
    }else if (status == ALAuthorizationStatusAuthorized) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            if ([assets isKindOfClass:[UIImage class]]) {
                UIImage *image = assets;
                [[[ALAssetsLibrary alloc] init] writeImageToSavedPhotosAlbum:image.CGImage orientation:(ALAssetOrientation)[image imageOrientation] completionBlock:^(NSURL *assetURL, NSError *error) {
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (error) {
                            block(error.description);
                        }else{
                            block(nil);
                        }
                    });
                    
                }];
            } else if ([assets isKindOfClass:[NSURL class]]) {
                NSURL *videoURL = assets;
                [[[ALAssetsLibrary alloc] init] writeVideoAtPathToSavedPhotosAlbum:videoURL completionBlock:^(NSURL *assetURL, NSError *error) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (error) {
                            block(error.description);
                        }else{
                            block(nil);
                        }
                    });

                }];
            
            }
            
        });
        
    }else if (status == ALAuthorizationStatusRestricted) {
        block(@"因为家长控制，应用无法访问相册");
    }else if (status == ALAuthorizationStatusNotDetermined) {
        block(@"需要相册访问权限");
    }
#pragma clang diagnostic pop
    
}

-(void)saveImageByPhotos_libWithAssets:(id)assets createPhotoCollection:(BOOL) createPhotoCollection completation:(CompleteHandler)block{
    /*
     PHAuthorizationStatusNotDetermined,     用户还没有做出选择
     PHAuthorizationStatusDenied,            用户拒绝当前应用访问相册(用户当初点击了"不允许")
     PHAuthorizationStatusAuthorized         用户允许当前应用访问相册(用户当初点击了"好")
     PHAuthorizationStatusRestricted,        因为家长控制, 导致应用无法方法相册(跟用户的选择没有关系)
     */
    
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    if (status == PHAuthorizationStatusRestricted) {
        block(@"因为家长控制，应用无法访问相册");
    } else if (status == PHAuthorizationStatusDenied) {
        block(@"用户拒绝当前应用访问相册");
    } else if (status == PHAuthorizationStatusNotDetermined) {
        //用户尚未作出选择，弹窗请求用户授权
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            if (status == PHAuthorizationStatusAuthorized) {
                //保存图片
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    [self canSaveImageWithAssets:assets createPhotoCollection:createPhotoCollection completation:[block copy]];
                });
            }
        }];
    } else if (status == PHAuthorizationStatusAuthorized) {
        //保存图片
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self canSaveImageWithAssets:assets createPhotoCollection:createPhotoCollection completation:[block copy]];
        });
    }

}
-(void)canSaveImageWithAssets:(id)assets createPhotoCollection:(BOOL)createPhotoCollection completation:(CompleteHandler)block{
    //判断是否写入自定义相册
    if (!createPhotoCollection) {
       [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
           if ([assets isKindOfClass:[UIImage class]]) {
               UIImage *image = assets;
               [PHAssetCreationRequest creationRequestForAssetFromImage:image];
           }else if ([assets isKindOfClass:[NSURL class]]) {
               NSURL *videoURL = assets;
               [PHAssetCreationRequest creationRequestForAssetFromVideoAtFileURL:videoURL];
           }
    
       } completionHandler:^(BOOL success, NSError * _Nullable error) {
           
           dispatch_async(dispatch_get_main_queue(), ^{
               if (success) {
                   block(nil);
               }else{
                   block(error.description);
               }
           });
           
           
       }];
        return;
    }
    
    __block NSString *assetLocalID = nil;
    
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        if ([assets isKindOfClass:[UIImage class]]) {
            UIImage *image = assets;
            assetLocalID = [PHAssetCreationRequest creationRequestForAssetFromImage:image].placeholderForCreatedAsset.localIdentifier;
        }else if ([assets isKindOfClass:[NSURL class]]) {
            NSURL *videoURL = assets;
            assetLocalID = [PHAssetCreationRequest creationRequestForAssetFromVideoAtFileURL:videoURL].placeholderForCreatedAsset.localIdentifier;
        }
        
    } completionHandler:^(BOOL success, NSError * _Nullable error) {
        if (!success) {
            dispatch_async(dispatch_get_main_queue(), ^{
                block(error.description);
                return;
            });
        }
        
        //获取相簿
        PHAssetCollection *createAssetCollection = [self createAssetCollection];
        
        if (createAssetCollection == nil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                block(@"写入相册成功,相簿创建失败");
                return;
            });
        }
        
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
           //添加图片到自定义的相簿中
            PHAsset *asset = [PHAsset fetchAssetsWithLocalIdentifiers:@[assetLocalID] options:nil].lastObject;
            [[PHAssetCollectionChangeRequest changeRequestForAssetCollection:createAssetCollection] addAssets:@[asset]];
            
        } completionHandler:^(BOOL success, NSError * _Nullable error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (success) {
                    block(nil);
                }else{
                    block(error.description);
                }
            });
        }];

    }];
    
}
-(PHAssetCollection *)createAssetCollection{
    //先从已存在的相簿中查找
    PHFetchResult<PHAssetCollection *> *assetCollections = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
    for (PHAssetCollection *assetCollection in assetCollections) {
        if ([assetCollection.localizedTitle isEqualToString:AssetCollectionName_testDemo]) {
            return assetCollection;
        }
    }
    
    //没有找到对应的相簿，创建
    NSError *error = nil;
    
    __block NSString *assetCollectionLocalIdentifier = nil;
    [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
        assetCollectionLocalIdentifier = [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:AssetCollectionName_testDemo].placeholderForCreatedAssetCollection.localIdentifier;
    } error:&error];
    
    if (error) {
        return nil;
    }
    
    return [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[assetCollectionLocalIdentifier] options:nil].lastObject;
}

#pragma mark - runtime add setter && getter
-(void)setHandler:(CompleteHandler)handler{
    objc_setAssociatedObject(self, _cmd, handler, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(CompleteHandler)handler{
    return objc_getAssociatedObject(self, _cmd);
}
@end
