//
//  NSURLSession+DataFetch_Session.m
//  FastDevTools
//
//  Created by TimmyYan on 2019/6/4.
//

#import "NSURLSession+DataFetch_Session.h"
#import <objc/runtime.h>
#import "DataFetch_Debug.h"
#import "NSString+EncodeFormat.h"

@implementation NSURLSession (DataFetch_Session)

+ (void)swizzleTaskRequest {
    Class objClass = [NSURLSession class];
    if (objClass) {
        Method ori_Method = class_getInstanceMethod(objClass, @selector(dataTaskWithRequest:completionHandler:));
        Method sw_Method = class_getInstanceMethod(objClass, @selector(debugLog_dataTaskWithRequest:completionHandler:));
        method_exchangeImplementations(ori_Method, sw_Method);
    }
}

- (NSURLSessionDataTask *)debugLog_dataTaskWithRequest:(NSURLRequest *)request completionHandler:(void (^)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))completionHandler {
    return [self debugLog_dataTaskWithRequest:request completionHandler:^(NSURLResponse *response, id  _Nullable responseObject, NSError * _Nullable error) {
        
        NSString *requestBody = [[[NSString alloc] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding] encodeFormat];
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
