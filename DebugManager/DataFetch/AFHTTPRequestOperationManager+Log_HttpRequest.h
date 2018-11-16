//
//  AFHTTPRequestOperationManager+Log_HttpRequest.h
//  Pods
//
//  Created by TimmyYan on 2018/11/16.
//

#if __has_include(<AFNetworking/AFHTTPRequestOperationManager.h>)

#import "AFHTTPRequestOperationManager.h"

@interface AFHTTPRequestOperationManager (Log_HttpRequest)

+ (void)swizzleTaskRequest;

- (AFHTTPRequestOperation *)debugLog_HTTPRequestOperationWithRequest:(NSURLRequest *)request
                                                      success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                                                    failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

@end

#endif
