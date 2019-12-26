//
//  NetStatus_LocalConnection.m
//  NetStatus_Demo
//
//  Created by TimmyYan on 2018/11/28.
//  Copyright © 2018年 com.ysw. All rights reserved.
//

#import "NetStatus_LocalConnection.h"
#import <netinet/in.h>
#import <netinet6/in6.h>
#import <arpa/inet.h>
#import <ifaddrs.h>

#if (!defined(DEBUG))
#define NSLog(...)
#endif

NSString *const kLocalConnectionInitializedNotification = @"kLocalConnectionInitializedNotification";
NSString *const kLocalConnectionChangedNotification = @"kLocalConnectionChangedNotification";

@interface NetStatus_LocalConnection ()

@property (nonatomic, assign) SCNetworkReachabilityRef reachabilityRef;
@property (nonatomic, strong) dispatch_queue_t reachabilitySerialQueue;
@property (nonatomic, assign) BOOL isNotifying;

- (void)localConnectionChanged;
@end

static void LocalConnectionCallback(SCNetworkReachabilityRef target, SCNetworkConnectionFlags flags, void* info) {
#pragma unused (target)
    NetStatus_LocalConnection *connection = (__bridge NetStatus_LocalConnection *)info;
    
    @autoreleasepool {
        [connection localConnectionChanged];
    }
}

static NSString *connectionFlags(SCNetworkReachabilityFlags flags)
{
    return [NSString stringWithFormat:@"%c%c %c%c%c%c%c%c%c",
            (flags & kSCNetworkReachabilityFlagsIsWWAN)               ? 'W' : '-',
            (flags & kSCNetworkReachabilityFlagsReachable)            ? 'R' : '-',
            (flags & kSCNetworkReachabilityFlagsConnectionRequired)   ? 'c' : '-',
            (flags & kSCNetworkReachabilityFlagsTransientConnection)  ? 't' : '-',
            (flags & kSCNetworkReachabilityFlagsInterventionRequired) ? 'i' : '-',
            (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic)  ? 'C' : '-',
            (flags & kSCNetworkReachabilityFlagsConnectionOnDemand)   ? 'D' : '-',
            (flags & kSCNetworkReachabilityFlagsIsLocalAddress)       ? 'l' : '-',
            (flags & kSCNetworkReachabilityFlagsIsDirect)             ? 'd' : '-'];
}


@implementation NetStatus_LocalConnection

- (instancetype)init {
    self = [super init];
    if (self) {
        struct sockaddr_in address;
        bzero(&address, sizeof(address));
        address.sin_len = sizeof(address);
        address.sin_family = AF_INET;
        _reachabilityRef = SCNetworkReachabilityCreateWithAddress(NULL, (struct sockaddr *) &address);
        _reachabilitySerialQueue = dispatch_queue_create("com.ysw.netstatusSerial", NULL);
    }
    return self;
}

- (void)dealloc {
    [self stopNotifier];
    
    if (_reachabilityRef != NULL) {
        CFRelease(_reachabilityRef);
        _reachabilityRef = NULL;
    }
    
    self.reachabilitySerialQueue = nil;
}

#pragma mark - singlton

+ (instancetype)sharedInstance {
    static NetStatus_LocalConnection *localConnection = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        localConnection = [[NetStatus_LocalConnection alloc] init];
    });
    return localConnection;
}

#pragma mark - public SEL
- (void)startNotifier {
    if (self.isNotifying) {
        return;
    }
    
    self.isNotifying = YES;
    
    SCNetworkReachabilityContext context = {0, NULL, NULL, NULL, NULL};
    context.info = (__bridge void *)self;
    
    if (SCNetworkReachabilitySetCallback(self.reachabilityRef, LocalConnectionCallback, &context)) {
        if (!SCNetworkReachabilitySetDispatchQueue(self.reachabilityRef, self.reachabilitySerialQueue)) {
            SCNetworkReachabilitySetCallback(self.reachabilityRef, NULL, NULL);
            NSLog(@"SCNetworkReachabilitySetDispatchQueue() failed: %s", SCErrorString(SCError()));
        }
    } else {
        NSLog(@"SCNetworkReachabilitySetCallback() failed: %s", SCErrorString(SCError()));
    }
    
    self.isReachable = [self _isReachable];
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [[NSNotificationCenter defaultCenter] postNotificationName:kLocalConnectionInitializedNotification object:strongSelf];
    });
}

- (void)stopNotifier {
    if (!self.isNotifying) {
        return;
    }
    
    self.isNotifying = NO;
    
    SCNetworkReachabilitySetCallback(self.reachabilityRef, NULL, NULL);
    
    SCNetworkReachabilitySetDispatchQueue(self.reachabilityRef, NULL);
}

- (NS_LocalConnectionStatus)currentLocalConnectionStatus {
    if ([self _isReachable]) {
        if ([self isReachableViaWiFi]) {
            return NS_WiFi;
        } else {
            return NS_WWAN;
        }
    } else {
        return NS_UnReachable;
    }
}

#pragma mark - inner methods
- (void)localConnectionChanged {
    self.isReachable = [self _isReachable];
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [[NSNotificationCenter defaultCenter] postNotificationName:kLocalConnectionChangedNotification object:strongSelf];
    });
}

- (NSString *)currentConnectionFlags {
    return connectionFlags([self reachabilityFlags]);
}

- (SCNetworkReachabilityFlags)reachabilityFlags {
    SCNetworkReachabilityFlags flags = 0;
    if (SCNetworkReachabilityGetFlags(self.reachabilityRef, &flags)) {
        return flags;
    }
    return 0;
}

#pragma mark - LocalReachability
- (BOOL)_isReachable {
    SCNetworkReachabilityFlags flags;
    if (!SCNetworkReachabilityGetFlags(self.reachabilityRef, &flags)) {
        return NO;
    } else {
        return [self isReachableWithFlags:flags];
    }
}

- (BOOL)isReachableWithFlags:(SCNetworkReachabilityFlags)flags {
    if ( (flags & kSCNetworkFlagsReachable) == 0 ) {
        return NO;
    }
    
    if ( (flags & kSCNetworkReachabilityFlagsConnectionRequired) == 0 ) {
        return YES;
    }
    
    if ( (flags & kSCNetworkReachabilityFlagsConnectionOnDemand) != 0 || (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) != 0 ) {
        if ( (flags & kSCNetworkReachabilityFlagsInterventionRequired) == 0 ) {
            return YES;
        }
    }
    
    return NO;
}

- (BOOL)isReachableViaWWAN {
    SCNetworkReachabilityFlags flags = 0;
    if (SCNetworkReachabilityGetFlags(self.reachabilityRef, &flags)) {
        if (flags & kSCNetworkReachabilityFlagsReachable) {
            if (flags & kSCNetworkReachabilityFlagsIsWWAN) {
                return YES;
            }
        }
    }
    return NO;
}

- (BOOL)isReachableViaWiFi {
    SCNetworkReachabilityFlags flags = 0;
    if (SCNetworkReachabilityGetFlags(self.reachabilityRef, &flags)) {
        if (flags & kSCNetworkReachabilityFlagsReachable) {
            if (flags & kSCNetworkReachabilityFlagsIsWWAN) {
                return NO;
            }
            return YES;
        }
    }
    
    return NO;
}

@end
