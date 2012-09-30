//
//  GCNetworkReachability.h
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

#import <Foundation/Foundation.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <netinet/in.h>

typedef enum : unsigned char
{
    GCNetworkReachabilityStatusNotReachable = 1 << 0,
    GCNetworkReachabilityStatusWWAN         = (1 << 1) | GCNetworkReachabilityStatusNotReachable,
    GCNetworkReachabilityStatusWiFi         = (1 << 2) | GCNetworkReachabilityStatusNotReachable
} GCNetworkReachabilityStatus;

extern NSString * const kGCNetworkReachabilityDidChangeNotification;
extern NSString * const kGCNetworkReachabilityStatusKey;

@interface GCNetworkReachability : NSObject

@property (readonly, assign, nonatomic) GCNetworkReachabilityStatus networkReachabilityStatus;

+ (GCNetworkReachability *)reachabilityWithHostName:(NSString *)hostName;

+ (GCNetworkReachability *)reachabilityWithAddress:(const struct sockaddr_in *)hostAddress;

+ (GCNetworkReachability *)reachabilityWithInternetAddress:(in_addr_t)internetAddress;

+ (GCNetworkReachability *)reachabilityForInternetConnection;

+ (GCNetworkReachability *)reachabilityForLocalWiFi;


- (id)initWithAddress:(const struct sockaddr_in *)address;

- (id)initWithHostName:(NSString *)hostName;

- (id)initWithReachability:(SCNetworkReachabilityRef)reachability;


- (GCNetworkReachabilityStatus)currentReachabilityStatus;


- (BOOL)isReachable;

- (BOOL)isReachableViaWWAN;

- (BOOL)isReachableViaWiFi;


- (void)startNotifierWithHandler:(void(^)(void))block;

- (void)stopNotifier;

@end
