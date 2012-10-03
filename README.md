GCNetworkReachability
=====================

GCNetworkReachability monitors the network state on iOS and OS X devices. Full ARC and GCD support.

The API is inspired by Apple's Reachability class but the implementation is built from the ground up to utilize modern LLVM compiler features and POSIX standards. It also runs concurrently with GCD (libdispatch) and has OS X and IPv6 support.

Features / Design
-----------------
* Network monitoring is done via a secondary thread (via libdispatch) and thus fully asynchronous. Apple's Reachability class uses a (main thread) blocking synchronous API.
* Supports modern LLVM compiler features like Blocks.
* Full support for OS X.
* Full ARC support
* Supports IPv4 and IPv6 addresses.

Requirements
------------
GCNetworkReachability requires iOS 5.0 and above or OS X 10.7 and above. It also requires Xcode 4.5 and above and LLVM Compiler 4.1.

Installation
------------
Add the source code to your project. Link your target against the `SystemConfiguration.framework`.

If you use this class in a non-ARC project, make sure you add the `-fobjc-arc` compiler flag for the implementation file.

Usage
-----
The recommended way is to use a global instance variable of `GCNetworkReachability` in a class that stays alive during the whole runtime of your application (e.g. AppDelegate). This ensures that `GCNetworkReachability` can keep monitoring the network state of the device. When you're done monitoring, always call `-stopMonitoringNetworkReachability` to clean up memory and to stop the monitoring process.

The application can get reachability callbacks via a block handler or via a notification. The callbacks are called from a secondary thread, so make sure you dispatch back to the main thread if you need to (e.g. UI updates).

Should you use the block handler or notification API? Well, notifications allow you to listen for changes in networking state in your whole project. If that's not necessary then you should use the handler as this requires less code and is more efficient for your application.

Block handler example:

```
self.reachability = [GCNetworkReachability reachabilityWithHostName:@"www.google.com"];

[self.reachability startMonitoringNetworkReachabilityWithHandler:^(GCNetworkReachabilityStatus status) {
        
    switch (status) {
        case GCNetworkReachabilityStatusNotReachable:
            NSLog(@"No connection");
            break;
        case GCNetworkReachabilityStatusWiFi:
        case GCNetworkReachabilityStatusWWAN:
            // e.g. start syncing...
            break;
    }
}];

```
If you use notifications, you can access the instance of `GCNetworkReachability` via the block parameter `NSNotification`. The status value can be accessed inside the `userInfo` dictionary via the key `kGCNetworkReachabilityStatusKey`.

Notification example:

```
[self.reachability startMonitoringNetworkReachabilityWithNotification];

self.observer = [[NSNotificationCenter defaultCenter] addObserverForName:kGCNetworkReachabilityDidChangeNotification
                                                                  object:nil
                                                                   queue:nil
                                                              usingBlock:^(NSNotification *note) {
                                                                  
                                                                  GCNetworkReachabilityStatus status = [[note userInfo][kGCNetworkReachabilityStatusKey] integerValue];
                                                                  
                                                                  switch (status) {
                                                                      case GCNetworkReachabilityStatusNotReachable:
                                                                          NSLog(@"No connection");
                                                                          break;
                                                                      case GCNetworkReachabilityStatusWiFi:
                                                                          NSLog(@"Reachable via WiFi");
                                                                          break;
                                                                      case GCNetworkReachabilityStatusWWAN:
                                                                          NSLog(@"Reachable via WWAN");
                                                                          break;
                                                                  }
                                                              }];


```

You are not forced to start monitoring the network state, just to check the reachability. It's also possible to check the network state yourself, e.g.:

```
GCNetworkReachability *reachability = [GCNetworkReachability reachabilityWithHostName:@"www.google.com"];

if ([reachability isReachable])
{
	// do stuff that requires an internet connection…
}

if ([reachability currentReachabilityStatus] == GCNetworkreachabilityStatusWWAN)
{
	// e.g. download smaller file sized images...
}
```

License
-------

This code is distributed under the terms and conditions of the MIT license.

Copyright (c) 2012 Glenn Chiu

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.