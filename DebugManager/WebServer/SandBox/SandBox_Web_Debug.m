//
//  SandBox_Web_Debug.m
//  DebugController
//
//  Created by 闫士伟 on 2018/8/4.
//  Copyright © 2018年 com.ysw. All rights reserved.
//

#import "SandBox_Web_Debug.h"
#import <GCDWebServer/GCDWebServer.h>
#import <GCDWebServer/GCDWebUploader.h>
#import <GCDWebServer/GCDWebDAVServer.h>

@interface SandBox_Web_Debug ()

@property (nonatomic, strong) GCDWebServer *webServer;
@property (nonatomic, strong) GCDWebUploader *uploader;
@property (nonatomic, strong) GCDWebDAVServer *webDavServer;

@end

@implementation SandBox_Web_Debug

#pragma mark - public SEL
- (NSArray *)sb_run {
    NSMutableArray *arr = [[NSMutableArray alloc] init];
    BOOL ret1 = [self fileContentHtml];
    [arr addObject:ret1 ? _webServer.serverURL.description ? : @"--" : @"webServer 服务开启失败"];
    
    BOOL ret2 = [self sandBox_Uploader];
    [arr addObject:ret2 ? _uploader.serverURL.description ? : @"--" : @"webUploader 服务开启失败"];
    
    BOOL ret3 = [self sandBox_WebDav];
    [arr addObject:ret3 ? _webDavServer.serverURL.description ? : @"--" : @"webDavServer 服务开启失败"];
    
    return arr;
}

- (void)sb_stop {
    [self.webServer stop];
    self.webServer = nil;
    
    [self.uploader stop];
    self.uploader = nil;
    
    [self.webDavServer stop];
    self.webDavServer = nil;
    
}


- (BOOL)fileContentHtml {
    GCDWebServer *webServer = [GCDWebServer new];
    [webServer addGETHandlerForBasePath:@"/" directoryPath:NSHomeDirectory() indexFilename:nil cacheAge:3600 allowRangeRequests:YES];
    BOOL ret = [webServer startWithPort:8080 bonjourName:@"GCD Web Server"];
    NSLog(@"Visit %@ in your web browser", webServer.serverURL);

    self.webServer = webServer;
    return ret;

}
- (BOOL)sandBox_Uploader {
    GCDWebUploader *uploaderServer = [[GCDWebUploader alloc] initWithUploadDirectory:NSHomeDirectory()];
    BOOL ret = [uploaderServer startWithPort:8081 bonjourName:@"Uploader Server"];
    NSLog(@"Visit %@ in your webDav browser", uploaderServer.serverURL);

    self.uploader = uploaderServer;
    return ret;
}
- (BOOL)sandBox_WebDav {
    GCDWebDAVServer *webDavServer = [[GCDWebDAVServer alloc] initWithUploadDirectory:NSHomeDirectory()];
    BOOL ret = [webDavServer startWithPort:8082 bonjourName:@"WebDav Server"];
    NSLog(@"Visit %@ in your webDav browser", webDavServer.serverURL);

    self.webDavServer = webDavServer;
    return ret;
}



@end
