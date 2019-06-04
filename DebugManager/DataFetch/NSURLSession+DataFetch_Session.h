//
//  NSURLSession+DataFetch_Session.h
//  FastDevTools
//
//  Created by TimmyYan on 2019/6/4.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSURLSession (DataFetch_Session)

+ (void)swizzleTaskRequest;

- (NSURLSessionDataTask *)debugLog_dataTaskWithRequest:(NSURLRequest *)request completionHandler:(void (^)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))completionHandler;

@end

NS_ASSUME_NONNULL_END
