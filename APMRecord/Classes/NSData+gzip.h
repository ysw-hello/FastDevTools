//
//  NSData+gzip.h
//  FastDevTools
//
//  Created by TimmyYan on 2019/12/13.
//

#import <Foundation/Foundation.h>
#import <zlib.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSData (gzip)

- (NSData *)gzipDeflate;

@end

NS_ASSUME_NONNULL_END
