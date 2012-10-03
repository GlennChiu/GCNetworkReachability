//
//  GCNetworkReachability.m
//  GCNetworkReachability
//
//  Created by Glenn Chiu on 26/09/2012.
//  Copyright (c) 2012 Glenn Chiu. All rights reserved.
//

// This code is distributed under the terms and conditions of the MIT license.

// Copyright (c) 2012 Glenn Chiu
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "GCNetworkReachability.h"
#import <arpa/inet.h>

#if ! __has_feature(objc_arc)
#error GCNetworkReachability is ARC only. Use -fobjc-arc as compiler flag for this library
#endif

#ifdef DEBUG
#   define GCNRLog(fmt, ...) NSLog((@"%s [Line %d]\n" fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#else
#   define GCNRLog(...) do {} while(0)
#endif

#if TARGET_OS_IPHONE
#   if __IPHONE_OS_VERSION_MIN_REQUIRED >= 60000
#       define GC_DISPATCH_RELEASE(v) do {} while(0)
#       define GC_DISPATCH_RETAIN(v) do {} while(0)
#   else
#       define GC_DISPATCH_RELEASE(v) dispatch_release(v)
#       define GC_DISPATCH_RETAIN(v) dispatch_retain(v)
#   endif
#else
#   if __MAC_OS_X_VERSION_MIN_REQUIRED >= 1080
#       define GC_DISPATCH_RELEASE(v) do {} while(0)
#       define GC_DISPATCH_RETAIN(v) do {} while(0)
#   else
#       define GC_DISPATCH_RELEASE(v) dispatch_release(v)
#       define GC_DISPATCH_RETAIN(v) dispatch_retain(v)
#   endif
#endif

static GCNetworkReachabilityStatus GCReachabilityStatusForFlags(SCNetworkReachabilityFlags flags);
static const void * GCNetworkReachabilityRetainCallback(const void *info);
static void GCNetworkReachabilityReleaseCallback(const void *info);
static void GCNetworkReachabilityCallbackWithBlock(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void *info);
static void GCNetworkReachabilityCallback(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void *info);
static void GCNetworkReachabilityPostNotification(void *info, GCNetworkReachabilityStatus status);
static void GCNetworkReachabilityPrintFlags(SCNetworkReachabilityFlags flags);
static void GCNetworkReachabilitySetSocketAddress(struct sockaddr_in *addr);
static void GCNetworkReachabilitySetIPv6SocketAddress(struct sockaddr_in6 *addr);

static BOOL _localWiFi;

NSString * const kGCNetworkReachabilityDidChangeNotification    = @"NetworkReachabilityDidChangeNotification";
NSString * const kGCNetworkReachabilityStatusKey                = @"NetworkReachabilityStatusKey";

@interface GCNetworkReachability ()

@end

@implementation GCNetworkReachability
{
    dispatch_queue_t _reachability_queue;
    SCNetworkReachabilityRef _networkReachability;
    void(^_handler_blk)(GCNetworkReachabilityStatus status);
}

static void GCNetworkReachabilityPrintFlags(SCNetworkReachabilityFlags flags)
{
#if 1
    GCNRLog(@"GCNetworkReachability Flag Status: %c%c %c%c%c%c%c%c%c",
#if TARGET_OS_IPHONE
            (flags & kSCNetworkReachabilityFlagsIsWWAN)               ? 'W' : '-',
#else
            '-',
#endif
            (flags & kSCNetworkReachabilityFlagsReachable)            ? 'R' : '-',
            (flags & kSCNetworkReachabilityFlagsTransientConnection)  ? 't' : '-',
            (flags & kSCNetworkReachabilityFlagsConnectionRequired)   ? 'c' : '-',
            (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic)  ? 'C' : '-',
            (flags & kSCNetworkReachabilityFlagsInterventionRequired) ? 'i' : '-',
            (flags & kSCNetworkReachabilityFlagsConnectionOnDemand)   ? 'D' : '-',
            (flags & kSCNetworkReachabilityFlagsIsLocalAddress)       ? 'l' : '-',
            (flags & kSCNetworkReachabilityFlagsIsDirect)             ? 'd' : '-'
            );
#endif
}

+ (GCNetworkReachability *)reachabilityWithHostName:(NSString *)hostName
{
    assert(hostName);
    
    return [[self alloc] initWithReachability:SCNetworkReachabilityCreateWithName(kCFAllocatorDefault, [hostName UTF8String])];
}

+ (GCNetworkReachability *)reachabilityWithHostAddress:(const struct sockaddr *)hostAddress
{
    assert(hostAddress);
    
    return [[self alloc] initWithReachability:SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (const struct sockaddr *)hostAddress)];
}

static void GCNetworkReachabilitySetSocketAddress(struct sockaddr_in *addr)
{
    memset(addr, 0, sizeof(struct sockaddr_in));
	addr->sin_len = sizeof(struct sockaddr_in);
	addr->sin_family = AF_INET;
}

+ (GCNetworkReachability *)reachabilityWithInternetAddress:(in_addr_t)internetAddress
{
    assert(internetAddress >= (in_addr_t)0);
    
    struct sockaddr_in addr;
    GCNetworkReachabilitySetSocketAddress(&addr);
	addr.sin_addr.s_addr = htonl(internetAddress);
	return [self reachabilityWithHostAddress:(const struct sockaddr *)&addr];
}

+ (GCNetworkReachability *)reachabilityWithInternetAddressString:(NSString *)internetAddress
{
    assert(internetAddress);
    
    struct sockaddr_in addr;
    GCNetworkReachabilitySetSocketAddress(&addr);
    inet_pton(AF_INET, [internetAddress UTF8String], &addr.sin_addr);
    return [self reachabilityWithHostAddress:(const struct sockaddr *)&addr];
}

+ (GCNetworkReachability *)reachabilityForInternetConnection
{
    static const in_addr_t zeroAddr = INADDR_ANY;
    return [self reachabilityWithInternetAddress:zeroAddr];
}

+ (GCNetworkReachability *)reachabilityForLocalWiFi
{
    _localWiFi = YES;
    
    static const in_addr_t localAddr = IN_LINKLOCALNETNUM;
    return [self reachabilityWithInternetAddress:localAddr];
}

static void GCNetworkReachabilitySetIPv6SocketAddress(struct sockaddr_in6 *addr)
{
    memset(addr, 0, sizeof(struct sockaddr_in6));
    addr->sin6_len = sizeof(struct sockaddr_in6);
    addr->sin6_family = AF_INET6;
}

+ (GCNetworkReachability *)reachabilityWithIPv6Address:(const struct in6_addr)internetAddress
{
    assert(&internetAddress);
    
    char strAddr[INET6_ADDRSTRLEN];
    
    struct sockaddr_in6 addr;
    GCNetworkReachabilitySetIPv6SocketAddress(&addr);
    addr.sin6_addr = internetAddress;
    inet_ntop(AF_INET6, &addr.sin6_addr, strAddr, INET6_ADDRSTRLEN);
    inet_pton(AF_INET6, strAddr, &addr.sin6_addr);
    return [self reachabilityWithHostAddress:(const struct sockaddr *)&addr];
}

+ (GCNetworkReachability *)reachabilityWithIPv6AddressString:(NSString *)internetAddress
{
    assert(internetAddress);
    
    struct sockaddr_in6 addr;
    GCNetworkReachabilitySetIPv6SocketAddress(&addr);
    inet_pton(AF_INET6, [internetAddress UTF8String], &addr.sin6_addr);
    return [self reachabilityWithHostAddress:(const struct sockaddr *)&addr];
}

- (id)initWithHostAddress:(const struct sockaddr *)hostAddress
{
    assert(hostAddress);
    
    return [self initWithReachability:SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (const struct sockaddr *)hostAddress)];
}

- (id)initWithHostName:(NSString *)hostName
{
    assert(hostName);
    
    return [self initWithReachability:SCNetworkReachabilityCreateWithName(kCFAllocatorDefault, [hostName UTF8String])];
}

- (id)initWithReachability:(SCNetworkReachabilityRef)reachability
{
    self = [super init];
    if (self)
    {
        if (!reachability)
        {
            GCNRLog(@"Creating SCNetworkReachabilityRef failed with error code: %s", SCErrorString(SCError()));
            return nil;
        }
        
        self->_networkReachability = reachability;
        
        _localWiFi = NO;
    }
    return self;
}

- (void)createReachabilityQueue
{
    self->_reachability_queue = dispatch_queue_create("com.gcnetworkreachability.queue", DISPATCH_QUEUE_SERIAL);
    
    if (!SCNetworkReachabilitySetDispatchQueue(self->_networkReachability, self->_reachability_queue))
    {
        GCNRLog(@"SCNetworkReachabilitySetDispatchQueue() failed with error code: %s", SCErrorString(SCError()));
        
        [self releaseReachabilityQueue];
    }
}

- (void)releaseReachabilityQueue
{
    if (self->_networkReachability) SCNetworkReachabilitySetDispatchQueue(self->_networkReachability, NULL);
    
    if (self->_reachability_queue)
    {
        GC_DISPATCH_RELEASE(self->_reachability_queue);
        self->_reachability_queue = NULL;
    }
}

- (void)dealloc
{
    [self stopMonitoringNetworkReachability];
    
    if (self->_networkReachability)
    {
        CFRelease(self->_networkReachability);
        self->_networkReachability = NULL;
    }
}

static GCNetworkReachabilityStatus GCReachabilityStatusForFlags(SCNetworkReachabilityFlags flags)
{
    GCNetworkReachabilityStatus status = GCNetworkReachabilityStatusNotReachable;
    
    if (flags & kSCNetworkFlagsReachable)
    {
        if (_localWiFi)
        {
            status |= (flags & kSCNetworkReachabilityFlagsIsDirect) ? GCNetworkReachabilityStatusWiFi : GCNetworkReachabilityStatusNotReachable;
        }
        else if ((flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) || (flags & kSCNetworkReachabilityFlagsConnectionOnDemand))
        {
            if (flags & kSCNetworkReachabilityFlagsInterventionRequired)
            {
                status |= (flags & kSCNetworkReachabilityFlagsConnectionRequired) ? GCNetworkReachabilityStatusNotReachable : GCNetworkReachabilityStatusWiFi;
            }
            else
            {
                status |= GCNetworkReachabilityStatusWiFi;
            }
        }
        else
        {
            status |= (flags & kSCNetworkReachabilityFlagsConnectionRequired) ? GCNetworkReachabilityStatusNotReachable : GCNetworkReachabilityStatusWiFi;
        }
        
#if TARGET_OS_IPHONE
        if (flags & kSCNetworkReachabilityFlagsIsWWAN)
        {
            status &= ~GCNetworkReachabilityStatusWiFi;
            status |= GCNetworkReachabilityStatusWWAN;
        }
#endif
        
    }
    return status;
}

- (GCNetworkReachabilityStatus)currentReachabilityStatus
{
    SCNetworkReachabilityFlags flags = (SCNetworkReachabilityFlags)0;
    SCNetworkReachabilityGetFlags(self->_networkReachability, &flags);
    return GCReachabilityStatusForFlags(flags);
}

- (BOOL)isReachable
{
    return [self currentReachabilityStatus] != GCNetworkReachabilityStatusNotReachable;
}

- (BOOL)isReachableViaWiFi
{
    return ([self currentReachabilityStatus] & GCNetworkReachabilityStatusWiFi) == GCNetworkReachabilityStatusWiFi;
}

#if TARGET_OS_IPHONE
- (BOOL)isReachableViaWWAN
{
    return ([self currentReachabilityStatus] & GCNetworkReachabilityStatusWWAN) == GCNetworkReachabilityStatusWWAN;
}
#endif

static const void * GCNetworkReachabilityRetainCallback(const void *info)
{
    void(^blk)(GCNetworkReachabilityStatus status) = (__bridge void(^)(GCNetworkReachabilityStatus status))info;
    return CFBridgingRetain(blk);
}

static void GCNetworkReachabilityReleaseCallback(const void *info)
{
    CFRelease(info);
    info = NULL;
}

static void GCNetworkReachabilityPostNotification(void *info, GCNetworkReachabilityStatus status)
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kGCNetworkReachabilityDidChangeNotification
                                                        object:(__bridge GCNetworkReachability *)info
                                                      userInfo:@{kGCNetworkReachabilityStatusKey : @(status)}];
}

static void GCNetworkReachabilityCallbackWithBlock(SCNetworkReachabilityRef __unused target, SCNetworkReachabilityFlags flags, void *info)
{
    GCNetworkReachabilityStatus status = GCReachabilityStatusForFlags(flags);
    void(^cb_blk)(GCNetworkReachabilityStatus status) = (__bridge void(^)(GCNetworkReachabilityStatus status))info;
    if (cb_blk) cb_blk(status);
    
    GCNetworkReachabilityPrintFlags(flags);
}

static void GCNetworkReachabilityCallback(SCNetworkReachabilityRef __unused target, SCNetworkReachabilityFlags flags, void *info)
{
    GCNetworkReachabilityStatus status = GCReachabilityStatusForFlags(flags);
    GCNetworkReachabilityPostNotification(info, status);
    
    GCNetworkReachabilityPrintFlags(flags);
}

- (void)startMonitoringNetworkReachabilityWithHandler:(void(^)(GCNetworkReachabilityStatus status))block
{
    if (!block) return;
    
    self->_handler_blk = [block copy];
    
    __weak GCNetworkReachability *w_self = self;
    
    void(^cb_blk)(GCNetworkReachabilityStatus status) = ^(GCNetworkReachabilityStatus status) {
        
        GCNetworkReachability *s_self = w_self;
        
        if (s_self) s_self->_handler_blk(status);
    };
    
    SCNetworkReachabilityContext context = {
        
        0,
        (__bridge void *)(cb_blk),
        GCNetworkReachabilityRetainCallback,
        GCNetworkReachabilityReleaseCallback,
        NULL
    };
    
    if (!SCNetworkReachabilitySetCallback(self->_networkReachability, GCNetworkReachabilityCallbackWithBlock, &context))
    {
        GCNRLog(@"SCNetworkReachabilitySetCallbackWithBlock() failed with error code: %s", SCErrorString(SCError()));
        return;
    }
    
    [self createReachabilityQueue];
}

- (void)startMonitoringNetworkReachabilityWithNotification
{
    SCNetworkReachabilityContext context = {
        
        0,
        (__bridge void *)(self),
        NULL,
        NULL,
        NULL
    };
    
    if (!SCNetworkReachabilitySetCallback(self->_networkReachability, GCNetworkReachabilityCallback, &context))
    {
        GCNRLog(@"SCNetworkReachabilitySetCallback() failed with error code: %s", SCErrorString(SCError()));
        return;
    }
    
    [self createReachabilityQueue];
}

- (void)stopMonitoringNetworkReachability
{
    if (self->_networkReachability) SCNetworkReachabilitySetCallback(self->_networkReachability, NULL, NULL);
    
    if (self->_handler_blk) self->_handler_blk = nil;
    
    [self releaseReachabilityQueue];
}

@end
