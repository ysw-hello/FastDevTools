//
//  HybridDebuggerLogger.m
//  ZYBHybrid
//
//  Created by TimmyYan on 2019/10/24.
//

#import "HybridDebuggerLogger.h"
#import "HybridDebuggerDefine.h"
#import "HybridDebuggerServerManager.h"
#import <GCDWebServer/GCDWebServerPrivate.h>

static dispatch_io_t _logFile_io;
static off_t _log_offset_write = 0;
static off_t _log_offset_read = 0;
static dispatch_semaphore_t _sync_log_semaphore;

@interface HybridDebuggerLogger ()

@property (nonatomic, assign) BOOL isSyncing;

@end

@implementation HybridDebuggerLogger

+ (instancetype)sharedInstance {
    static HybridDebuggerLogger *_logger;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _logger = [[HybridDebuggerLogger alloc] init];
        
    });
    return _logger;
}

- (void)startLogger {
    /**
     kGCDWebServerLoggingLevel_Debug = 0,
     kGCDWebServerLoggingLevel_Verbose,
     kGCDWebServerLoggingLevel_Info,
     kGCDWebServerLoggingLevel_Warning,
     kGCDWebServerLoggingLevel_Error
     */
    [GCDWebServer setLogLevel:2]; // 默认的日志等级
    
    // 获取日志输出的回调
    [GCDWebServer setBuiltInLogger:^(int level, NSString * _Nonnull message) {
        if (_logFile_io && level >= 2) { // 只记录日志等级为info及以上的日志，并写入文件
            long timeout = dispatch_semaphore_wait(_sync_log_semaphore, DISPATCH_TIME_FOREVER);
            if (timeout == 0) {
                static const char* levelNames[] = {"DEBUG", "VERBOSE", "INFO", "WARNING", "ERROR"};
                dispatch_queue_t dq = dispatch_queue_create("timmy.webservice.hybrid.logqueue", DISPATCH_QUEUE_SERIAL);
                NSString *content = [NSString stringWithFormat:@"[%s] %s\n", levelNames[level], [message UTF8String]];
                NSData *data = [content dataUsingEncoding:NSUTF8StringEncoding];
                dispatch_data_t data_t = dispatch_data_create([data bytes], [data length], dq, DISPATCH_DATA_DESTRUCTOR_DEFAULT);
                dispatch_io_write(_logFile_io, _log_offset_write, data_t, dq, ^(bool done, dispatch_data_t  _Nullable data, int error) {
                    if (done && error == 0) {
                        off_t start = dispatch_data_get_size(data_t);
                        _log_offset_write+= start;
                    }
                    dispatch_semaphore_signal(_sync_log_semaphore);
                });
                
            } else {
                dispatch_semaphore_signal(_sync_log_semaphore);
                ZYBHybridLog(@"The message '%@' is not written", message);
            }
        }
    }];
    
    //初始化GCD文件IO
    [self createGCD_File_IO];
}

- (void)createGCD_File_IO {
    if (!_logFile_io) {
        NSString *docsdir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
        NSString *logFile = [docsdir stringByAppendingPathComponent:kHybridDebuggerLogFile];
        ZYBHybridLog(@"Document = %@", docsdir);
        NSError *err = nil;
        if ([[NSFileManager defaultManager] fileExistsAtPath:logFile]) {
            [[NSFileManager defaultManager] removeItemAtPath:logFile error:&err];
        }
        if (!err) {
            // 创建日志文件
            [[NSFileManager defaultManager] createFileAtPath:logFile contents:nil attributes:nil];
            _sync_log_semaphore = dispatch_semaphore_create(1);
        }
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:logFile]) {
            // 同时设置读取流对象
            dispatch_queue_t dq = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
            _logFile_io = dispatch_io_create_with_path(DISPATCH_IO_RANDOM,
                                                       [logFile UTF8String], // Convert to C-string
                                                       O_RDWR,               // Open for reading
                                                       0,                    // No extra flags
                                                       dq, ^(int error) {
                                                           // Cleanup code for normal channel operation.
                                                           // Assumes that dispatch_io_close was called elsewhere.
                                                           ZYBHybridLog(@"I am ok ");
                                                       });
        } else {
            ZYBHybridLog(@"创建日志文件失败");
        }
        
    }
}

- (void)clearOffset {
    _log_offset_read = 0;
}

- (void)parseLog:(void (^)(NSArray<NSString *> *))completion {
    if (_logFile_io) {
        if (self.isSyncing) {
            return;
        }
        self.isSyncing = YES;
        
        dispatch_queue_t dq = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        __weak typeof(self) weakSelf = self;
        dispatch_io_read(_logFile_io, _log_offset_read, SIZE_T_MAX, dq, ^(bool done, dispatch_data_t _Nullable data, int error) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (error == 0) {
                // convert
                const void *buffer = NULL;
                size_t size = 0;
                dispatch_data_t new_data_file = dispatch_data_create_map(data, &buffer, &size);
                if (new_data_file && size == 0) { /* to avoid warning really - since dispatch_data_create_map demands we care about the return arg */
                    strongSelf.isSyncing = NO;
                    return ;
                }
                _log_offset_read += size;
                
                NSData *nsdata = [[NSData alloc] initWithBytes:buffer length:size];
                NSString *line = [[NSString alloc] initWithData:nsdata encoding:NSUTF8StringEncoding];
                
                if (completion && line.length > 0) {
                    NSArray<NSString *> *lines = [line componentsSeparatedByString:@"\n"];
                    NSMutableArray *newLines = [NSMutableArray array];
                    [lines enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                        if (obj.length > 0) {
                            [newLines addObject:obj];
                        }
                    }];
                    completion(newLines);
                }
                
            } else if (error != 0) {
                ZYBHybridLog(@"日志出错了");
                [strongSelf recordLogWithMessage:@"ReadLogError，errCode：%d", error];
            }
            
            strongSelf.isSyncing = NO;
        });
    }
}

- (void)recordLogWithMessage:(NSString *)format, ... {
    if ([[HybridDebuggerServerManager sharedInstance] getLocalServer]) {
        va_list arguments;
        va_start(arguments, format);
        [[[HybridDebuggerServerManager sharedInstance] getLocalServer] logInfo:@"%@", [[NSString alloc] initWithFormat:format arguments:arguments]];
        va_end(arguments);
    } else {
        ZYBHybridLog(@"xxx-DebugServerNotStart!!!");
    }
}

@end
