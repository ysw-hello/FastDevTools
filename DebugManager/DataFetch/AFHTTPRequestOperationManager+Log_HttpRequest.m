//
//  AFHTTPRequestOperationManager+Log_HttpRequest.m
//  Pods
//
//  Created by TimmyYan on 2018/11/16.
//

#import "AFHTTPRequestOperationManager+Log_HttpRequest.h"
#import <objc/runtime.h>
#import "DataFetch_Debug.h"
#import "NSString+EncodeFormat.h"

@implementation AFHTTPRequestOperationManager (Log_HttpRequest)

+ (void)swizzleTaskRequest {
    Class objClass = [AFHTTPRequestOperationManager class];
    if (objClass) {
        Method ori_Method = class_getInstanceMethod(objClass, @selector(HTTPRequestOperationWithRequest:success:failure:));
        Method sw_Method = class_getInstanceMethod(objClass, @selector(debugLog_HTTPRequestOperationWithRequest:success:failure:));
        method_exchangeImplementations(ori_Method, sw_Method);
    }
}

- (AFHTTPRequestOperation *)debugLog_HTTPRequestOperationWithRequest:(NSURLRequest *)request
                                                             success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                                                             failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure {
    return [self debugLog_HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSString *requestBody = [[[NSString alloc] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding] encodeFormat];
        //        NSLog(@"Succeed:URL:%@,\n param:%@,\n  method:%@,\n response:%@, request.URL, requestBody, request.HTTPMethod, responseObject);
        DataFetch_Model *model = [DataFetch_Model new];
        model.method = request.HTTPMethod;
        model.URL = [NSString stringWithFormat:@"%@", request.URL];
        model.requestHeader = [NSString stringWithFormat:@"%@", request.allHTTPHeaderFields];
        model.requestBody = [NSString stringWithFormat:@"%@", requestBody];
        model.responseBody = [NSString stringWithFormat:@"%@", responseObject];
        NSMutableArray *arr = [DataFetch_Debug sharedInstance].dataArr;
        [arr insertObject:model atIndex:0];
        [DataFetch_Debug sharedInstance].dataArr = arr;
        if ([DataFetch_Debug sharedInstance].dataArr.count > 250) { //最多显示250条请求数据
            [[DataFetch_Debug sharedInstance].dataArr removeLastObject];
        }

        success(operation, responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSString *requestBody = [[[NSString alloc] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding] encodeFormat];
        //        NSLog(@"Succeed:URL:%@,\n param:%@,\n  method:%@,\n error:%@\n", request.URL, requestBody, request.HTTPMethod, error);
        DataFetch_Model *model = [DataFetch_Model new];
        model.method = request.HTTPMethod;
        model.URL = [NSString stringWithFormat:@"%@", request.URL];
        model.requestHeader = [NSString stringWithFormat:@"%@", request.allHTTPHeaderFields];
        model.requestBody = [NSString stringWithFormat:@"%@", requestBody];
        model.error = error;
        NSMutableArray *arr = [DataFetch_Debug sharedInstance].dataArr;
        [arr insertObject:model atIndex:0];
        [DataFetch_Debug sharedInstance].dataArr = arr;
        if ([DataFetch_Debug sharedInstance].dataArr.count > 250) { //最多显示250条请求数据
            [[DataFetch_Debug sharedInstance].dataArr removeLastObject];
        }

        failure(operation, error);
    }];
}

@end
