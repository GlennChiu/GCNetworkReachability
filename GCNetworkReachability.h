//
//  Version 1.3.2
//
//  This code is distributed under the terms and conditions of the MIT license.
//
//  Copyright (c) 2013 Glenn Chiu
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#import <Foundation/Foundation.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <netinet/in.h>

#define PRINT_REACHABILITY_FLAGS 0

typedef enum : unsigned char
{
    GCNetworkReachabilityStatusNotReachable = 1 << 0,
    GCNetworkReachabilityStatusWWAN         = 1 << 1,
    GCNetworkReachabilityStatusWiFi         = 1 << 2
} GCNetworkReachabilityStatus;

extern NSString * const kGCNetworkReachabilityDidChangeNotification;
extern NSString * const kGCNetworkReachabilityStatusKey;

@interface GCNetworkReachability : NSObject

+ (instancetype)reachabilityWithHostName:(NSString *)hostName;

+ (instancetype)reachabilityWithHostAddress:(const struct sockaddr *)hostAddress;

+ (instancetype)reachabilityWithInternetAddress:(in_addr_t)internetAddress;

+ (instancetype)reachabilityWithInternetAddressString:(NSString *)internetAddress;

+ (instancetype)reachabilityWithIPv6Address:(const struct in6_addr)internetAddress;

+ (instancetype)reachabilityWithIPv6AddressString:(NSString *)internetAddress;

+ (instancetype)reachabilityForInternetConnection;

+ (instancetype)reachabilityForLocalWiFi;


- (id)initWithHostAddress:(const struct sockaddr *)hostAddress;

- (id)initWithHostName:(NSString *)hostName;

- (id)initWithReachability:(SCNetworkReachabilityRef)reachability;


- (void)startMonitoringNetworkReachabilityWithHandler:(void(^)(GCNetworkReachabilityStatus status))block;

- (void)startMonitoringNetworkReachabilityWithNotification;

- (void)stopMonitoringNetworkReachability;


- (GCNetworkReachabilityStatus)currentReachabilityStatus;


- (BOOL)isReachable;

- (BOOL)isReachableViaWiFi;

#if TARGET_OS_IPHONE
- (BOOL)isReachableViaWWAN;
#endif

- (SCNetworkReachabilityFlags)reachabilityFlags;

@end
