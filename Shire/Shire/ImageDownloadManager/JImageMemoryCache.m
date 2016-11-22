//
//  JImageMemoryCache.m
//  Shire
//
//  Created by jie on 2016/10/25.
//  Copyright © 2016年 huatengIOT. All rights reserved.
//

#import "JImageMemoryCache.h"
#import "JImageLFUMemoryCache.h"
#import "JImageLRUMemoryCache.h"

NSString *const MCacheSizeLimitKey = @"JImageMemoryCacheSizeLimitKey";
NSString *const MCacheCountLimitKey = @"JImageMemoryCacheCountLimitKey";
NSString *const MCacheTimeIntervalLimitKey = @"JImageMemoryCacheTimeIntervalLimitKey";

@implementation JImageMemoryCache

- (void)dealloc {
    dispatch_source_cancel(_monitorTimer);
    _monitorTimer = nil;
}

/*!
 @discussion
    factory method.
 @param
    algorithm : lfu or lru
 @return 
    either instance of JImageLFUMemoryCache or JImageLRUMemoryCache, depends on algorithm
 */
+ (JImageMemoryCache *)memoryCacheMark:(NSString *)mark CacheAlgorithm:(MCacheAlgorithm)algorithm LimitOptions:(NSDictionary *)options {
    JImageMemoryCache *instance = nil;

    NSUInteger countLimit = 0;
    NSUInteger sizeLimit = 0;
    NSTimeInterval timeIntervalLimit = 0;
    
    if (options) {
        id tmp = [options objectForKey:MCacheCountLimitKey];
        if (tmp) {
            countLimit = [(NSNumber *)tmp unsignedIntegerValue];
        }
        tmp = [options objectForKey:MCacheSizeLimitKey];
        if (tmp) {
            sizeLimit = [(NSNumber *)tmp unsignedIntegerValue];
        }
        tmp = [options objectForKey:MCacheTimeIntervalLimitKey];
        if (tmp > 0) {
            timeIntervalLimit = [(NSNumber *)tmp doubleValue];;
        }
    }
    
    if (algorithm & MCacheAlgorithmDefault || algorithm & MCacheAlgorithmLFU) {
        instance = [[JImageLFUMemoryCache alloc] initWithCapacity:countLimit CostLimit:sizeLimit AgeLimit:timeIntervalLimit Marking:mark];
    } else {
        instance = [[JImageLRUMemoryCache alloc] initWithCapacity:countLimit CostLimit:sizeLimit AgeLimit:timeIntervalLimit Marking:mark];
    }
    return instance;
}


/*!
 @discussion
 this method start a timer source, which check the cache limit every five seconds
 */
- (void)startMonitorLoopWithEventHandler:(dispatch_block_t)eventHandler AndCancelHandler:(dispatch_block_t)cancelHandler {
    // the queue that timer running on;
    dispatch_queue_t timerQueue = dispatch_queue_create("com.timerQueue.concurrent", DISPATCH_QUEUE_CONCURRENT);
    // timer fire interval
    uint64_t intervalInSeconds = 3;
    // leeway for interval
    uint64_t leewayInSeconds = 5;
    // create timer
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, timerQueue);
    // set up timer
    dispatch_source_set_timer(timer, DISPATCH_TIME_NOW, intervalInSeconds * NSEC_PER_SEC, leewayInSeconds * NSEC_PER_SEC);
    // set handlers
    dispatch_source_set_event_handler(timer, eventHandler);
    dispatch_source_set_cancel_handler(timer, cancelHandler);
    // fire timer immediately
    dispatch_resume(timer);
    
    // hold the timer;
    _monitorTimer = timer;
}


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
