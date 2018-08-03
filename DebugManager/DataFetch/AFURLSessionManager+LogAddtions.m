//
//  AFURLSessionManager+LogAddtions.m
//  DebugController
//
//  Created by 闫士伟 on 2018/8/2.
//  Copyright © 2018年 com.ysw. All rights reserved.
//

#import "AFURLSessionManager+LogAddtions.h"
#import <objc/runtime.h>
#import "DataFetch_Debug.h"

@implementation AFURLSessionManager (LogAddtions)

+ (void)swizzleTaskRequest {
    Class objClass = [AFURLSessionManager class];
    if (objClass) {
        Method ori_Method = class_getInstanceMethod(objClass, @selector(dataTaskWithRequest:uploadProgress:downloadProgress:completionHandler:));
        Method sw_Method = class_getInstanceMethod(objClass, @selector(debugLog_dataTaskWithRequest:uploadProgress:downloadProgress:completionHandler:));
        method_exchangeImplementations(ori_Method, sw_Method);
    }
}

- (NSURLSessionDataTask * _Nullable)debugLog_dataTaskWithRequest:(NSURLRequest *_Nullable)request
                                                  uploadProgress:(nullable void (^)(NSProgress * _Nullable uploadProgress))uploadProgressBlock
                                                downloadProgress:(nullable void (^)(NSProgress * _Nonnull downloadProgress))downloadProgressBlock
                                               completionHandler:(nullable void (^)(NSURLResponse * _Nullable response, id _Nullable responseObject,  NSError * _Nullable error))completionHandler {
    
    return [self debugLog_dataTaskWithRequest:request uploadProgress:uploadProgressBlock downloadProgress:downloadProgressBlock completionHandler:^(NSURLResponse *response, id  _Nullable responseObject, NSError * _Nullable error) {
        
        NSString *requestBody = [[NSString alloc] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding];
//        NSLog(@"Succeed:URL:%@,\n param:%@,\n  method:%@,\n response:%@,\n error:%@\n", request.URL, requestBody, request.HTTPMethod, responseObject, error);
        DataFetch_Model *model = [DataFetch_Model new];
        model.method = request.HTTPMethod;
        model.URL = [NSString stringWithFormat:@"%@", request.URL];
        model.requestHeader = [NSString stringWithFormat:@"%@", request.allHTTPHeaderFields];
        model.requestBody = [NSString stringWithFormat:@"%@", requestBody];
        model.responseBody = [NSString stringWithFormat:@"%@", responseObject];
        model.error = error;
        NSMutableArray *arr = [DataFetch_Debug sharedInstance].dataArr;
        [arr insertObject:model atIndex:0];
        [DataFetch_Debug sharedInstance].dataArr = arr;
        if ([DataFetch_Debug sharedInstance].dataArr.count > 250) { //最多显示250条请求数据
            [[DataFetch_Debug sharedInstance].dataArr removeLastObject];
        }
        
        completionHandler(response, responseObject, error);
    }];
}


@end
