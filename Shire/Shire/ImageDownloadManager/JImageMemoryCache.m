//
//  JImageMemoryCache.m
//  Shire
//
//  Created by jie on 2016/10/25.
//  Copyright © 2016年 huatengIOT. All rights reserved.
//

#import "JImageMemoryCache.h"

@implementation JImageMemoryCache

- (void)insertValue:(NSData *)data forKey:(NSString *)key {
    NSAssert(YES, @"not find implementation of msg: %@", NSStringFromSelector(_cmd));
}

- (NSData *)fetchValueForKey:(NSString *)key {
    NSAssert(YES, @"not find implementation of msg: %@", NSStringFromSelector(_cmd));
    return nil;
}

- (BOOL)existValueForKey:(NSString *)key {
    NSAssert(YES, @"not find implementation of msg: %@", NSStringFromSelector(_cmd));
    return false;
}

- (void)clearMemory {
    NSAssert(YES, @"not find implementation of msg: %@", NSStringFromSelector(_cmd));
}

- (NSUInteger)realCacheCount {
    return 0;
}
/*
- (void)startMonitorLoop {
    dispatch_queue_t monitorThread =  dispatch_queue_create("com.viwii.monitorloop", DISPATCH_QUEUE_CONCURRENT);
    dispatch_async(monitorThread, ^{
       
        @autoreleasepool {
            
            NSRunLoop *loop = [NSRunLoop currentRunLoop];
            
            while (1) {
                
                // work to do
 
                
                [loop runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
            }
        } // autoreleasepool
    });
}
*/

@end



#pragma mark JImageMemoryCacheItem

@implementation JImageMemoryCacheItem

- (instancetype)initWithData:(id)data parentNode:(JImageMemoryCacheNode *)pnode {
    self = [super init];
    if (self) {
        _data = data;
        _parentNode = pnode;
    }
    return self;
}

@end



#pragma mark JImageMemoryCacheNode


@implementation JImageMemoryCacheNode

@end
