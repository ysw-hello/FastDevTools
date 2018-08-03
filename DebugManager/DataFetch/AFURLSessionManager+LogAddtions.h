//
//  AFURLSessionManager+LogAddtions.h
//  DebugController
//
//  Created by 闫士伟 on 2018/8/2.
//  Copyright © 2018年 com.ysw. All rights reserved.
//

#import "AFURLSessionManager.h"

@interface AFURLSessionManager (LogAddtions)

+ (void)swizzleTaskRequest;

- (NSURLSessionDataTask * _Nullable)debugLog_dataTaskWithRequest:(NSURLRequest *_Nullable)request
                                                  uploadProgress:(nullable void (^)(NSProgress * _Nullable uploadProgress))uploadProgressBlock
                                                        downloadProgress:(nullable void (^)(NSProgress * _Nonnull downloadProgress))downloadProgressBlock
                                                       completionHandler:(nullable void (^)(NSURLResponse * _Nullable response, id _Nullable responseObject,  NSError * _Nullable error))completionHandler;
@end
