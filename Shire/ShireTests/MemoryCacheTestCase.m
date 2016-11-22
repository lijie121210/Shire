//
//  MemoryCacheTestCase.m
//  Shire
//
//  Created by jie on 2016/10/26.
//  Copyright © 2016年 huatengIOT. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "JImageCache.h"
#import "JImageMemoryCache.h"
#import "JImageLFUMemoryCache.h"
#import "JImageLRUMemoryCache.h"

@interface MemoryCacheTestCase : XCTestCase {
    @private
    NSUInteger _countLimit;
}


@end

@implementation MemoryCacheTestCase

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
    _countLimit = 1000;
    NSLog(@"set up code");
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
    
    
    NSLog(@"tear down code");
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

- (void)testCacheClassProperty {
    
    JImageCache *instance = [[JImageCache alloc] init];
    
    XCTAssertEqual(instance.cacheSizeLimit, 0);
    XCTAssertEqual(instance.cacheCountLimit, 0);
    XCTAssertEqual(instance.cacheTimeInterval, 0);
    
    JImageMemoryCache *minstance = [[JImageMemoryCache alloc] init];

    XCTAssertEqual(minstance.cacheSizeLimit, 0);
    XCTAssertEqual(minstance.cacheCountLimit, 0);
    XCTAssertEqual(minstance.cacheTimeInterval, 0);
    
    JImageLFUMemoryCache *lfu_minstance = [[JImageLFUMemoryCache alloc] init];
    
    XCTAssertEqual(lfu_minstance.cacheSizeLimit, 0);
    XCTAssertEqual(lfu_minstance.cacheCountLimit, 0);
    XCTAssertEqual(lfu_minstance.cacheTimeInterval, 60 * 60 * 24 * 3.5);
    
    JImageLFUMemoryCache *lfu_minstance_c = [[JImageLFUMemoryCache alloc] initWithCapacity:_countLimit marking:nil];
    
    XCTAssertEqual(lfu_minstance_c.cacheCountLimit, _countLimit);
}

- (void)testLFU_1 {
    NSData *test_data_1 = [[NSString stringWithFormat:@"how are you?"] dataUsingEncoding:NSUTF8StringEncoding];
    NSData *test_data_2 = [[NSString stringWithFormat:@"fine, thanks, and you?"] dataUsingEncoding:NSUTF8StringEncoding];
    NSData *test_data_3 = [[NSString stringWithFormat:@"me to"] dataUsingEncoding:NSUTF8StringEncoding];
    
    NSString *key_1 = [NSString stringWithFormat:@"test data 1"];
    NSString *key_2 = [NSString stringWithFormat:@"test data 2"];
    NSString *key_3 = [NSString stringWithFormat:@"test data 3"];
    
    NSString *cache_mark = [NSString stringWithFormat:@"cache 1"];
    
    JImageLFUMemoryCache *lfu_mem_cache = [[JImageLFUMemoryCache alloc] initWithCapacity:10 marking:cache_mark];
    [lfu_mem_cache insertValue:test_data_1 forKey:key_1];
    [lfu_mem_cache insertValue:test_data_2 forKey:key_2];
    [lfu_mem_cache insertValue:test_data_3 forKey:key_3];
    
    XCTAssertEqual([lfu_mem_cache realCacheCount], 3);
    
    NSArray *lfu_keys_1 = [lfu_mem_cache getLfuItemKeys];
    
    XCTAssertNotNil(lfu_keys_1);
    XCTAssertEqual(lfu_keys_1.count, 3);
    
    NSData *fetch_cache_1 = [lfu_mem_cache fetchValueForKey:key_1];
    NSArray *lfu_keys_2 = [lfu_mem_cache getLfuItemKeys];
    
    XCTAssertNotNil(fetch_cache_1);
    XCTAssertNotNil(lfu_keys_2);
    XCTAssertEqual(lfu_keys_2.count, 2);
    
    NSData *fetch_cache_2 = [lfu_mem_cache fetchValueForKey:key_2];
    NSArray *lfu_keys_3 = [lfu_mem_cache getLfuItemKeys];
    
    XCTAssertNotNil(fetch_cache_2);
    XCTAssertNotNil(lfu_keys_3);
    XCTAssertEqual(lfu_keys_3.count, 1);
}

- (void)testLFU_2 {
    NSData *test_data_1 = [[NSString stringWithFormat:@"how are you?"] dataUsingEncoding:NSUTF8StringEncoding];
    NSData *test_data_2 = [[NSString stringWithFormat:@"fine, thanks, and you?"] dataUsingEncoding:NSUTF8StringEncoding];
    NSData *test_data_3 = [[NSString stringWithFormat:@"me to"] dataUsingEncoding:NSUTF8StringEncoding];
    
    NSString *key_1 = [NSString stringWithFormat:@"test data 1"];
    NSString *key_2 = [NSString stringWithFormat:@"test data 2"];
    NSString *key_3 = [NSString stringWithFormat:@"test data 3"];
    
    NSString *cache_mark = [NSString stringWithFormat:@"cache 1"];
    
    JImageLFUMemoryCache *lfu_mem_cache = [[JImageLFUMemoryCache alloc] initWithCapacity:10 marking:cache_mark];
    [lfu_mem_cache insertValue:test_data_1 forKey:key_1];
    
    NSData *fetch_cache_1 = [lfu_mem_cache fetchValueForKey:key_1];
    
    XCTAssertNotNil(fetch_cache_1);
    
    [lfu_mem_cache insertValue:test_data_2 forKey:key_2];

    XCTAssertEqual([lfu_mem_cache getLfuItemKeys].count, 1);
    
    fetch_cache_1 = [lfu_mem_cache fetchValueForKey:key_1];
    XCTAssertNotNil(fetch_cache_1);
    
    NSData *fetch_cache_2 = [lfu_mem_cache fetchValueForKey:key_2];
    XCTAssertNotNil(fetch_cache_2);
    
    XCTAssertEqual([lfu_mem_cache getLfuItemKeys].count, 2);
    
    [lfu_mem_cache insertValue:test_data_3 forKey:key_3];
    
    XCTAssertEqual([lfu_mem_cache getLfuItemKeys].count, 1);
    
    XCTAssertEqual([lfu_mem_cache realCacheCount], 3);
}

- (void)testLFU_3_checkExistedKey {
    NSData *test_data_1 = [[NSString stringWithFormat:@"how are you?"] dataUsingEncoding:NSUTF8StringEncoding];
    NSData *test_data_2 = [[NSString stringWithFormat:@"fine, thanks, and you?"] dataUsingEncoding:NSUTF8StringEncoding];
    NSData *test_data_3 = [[NSString stringWithFormat:@"me to"] dataUsingEncoding:NSUTF8StringEncoding];
    
    NSString *key_1 = [NSString stringWithFormat:@"test data 1"];
    NSString *key_2 = [NSString stringWithFormat:@"test data 2"];
    NSString *key_3 = [NSString stringWithFormat:@"test data 3"];
    
    NSString *cache_mark = [NSString stringWithFormat:@"cache 1"];
    
    JImageLFUMemoryCache *lfu_mem_cache = [[JImageLFUMemoryCache alloc] initWithCapacity:10 marking:cache_mark];
    [lfu_mem_cache insertValue:test_data_1 forKey:key_1];
    [lfu_mem_cache insertValue:test_data_2 forKey:key_2];
    [lfu_mem_cache insertValue:test_data_3 forKey:key_3];
    
    XCTAssertTrue([lfu_mem_cache existValueForKey:key_1]);
    XCTAssertTrue([lfu_mem_cache existValueForKey:key_2]);
    XCTAssertTrue([lfu_mem_cache existValueForKey:key_3]);
    
    NSData *fetch_cache_1 = [lfu_mem_cache fetchValueForKey:key_1];
    
    XCTAssertNotNil(fetch_cache_1);
    XCTAssertTrue([lfu_mem_cache existValueForKey:key_1]);
    
    fetch_cache_1 = [lfu_mem_cache fetchValueForKey:key_1];
    XCTAssertNotNil(fetch_cache_1);
    XCTAssertTrue([lfu_mem_cache existValueForKey:key_1]);
    
    fetch_cache_1 = [lfu_mem_cache fetchValueForKey:key_1];
    XCTAssertNotNil(fetch_cache_1);
    XCTAssertTrue([lfu_mem_cache existValueForKey:key_1]);
    
    fetch_cache_1 = [lfu_mem_cache fetchValueForKey:key_1];
    XCTAssertNotNil(fetch_cache_1);
    XCTAssertTrue([lfu_mem_cache existValueForKey:key_1]);
    
    NSData *fetch_cache_2 = [lfu_mem_cache fetchValueForKey:key_2];
    fetch_cache_2 = [lfu_mem_cache fetchValueForKey:key_2];
    XCTAssertNotNil(fetch_cache_2);
    
    XCTAssertTrue([lfu_mem_cache existValueForKey:key_1]);
    XCTAssertTrue([lfu_mem_cache existValueForKey:key_2]);
    XCTAssertTrue([lfu_mem_cache existValueForKey:key_3]);
}

- (void)testLFU_4_clear {
    NSData *test_data_1 = [[NSString stringWithFormat:@"how are you?"] dataUsingEncoding:NSUTF8StringEncoding];
    NSData *test_data_2 = [[NSString stringWithFormat:@"fine, thanks, and you?"] dataUsingEncoding:NSUTF8StringEncoding];
    NSData *test_data_3 = [[NSString stringWithFormat:@"me to"] dataUsingEncoding:NSUTF8StringEncoding];
    
    NSString *key_1 = [NSString stringWithFormat:@"test data 1"];
    NSString *key_2 = [NSString stringWithFormat:@"test data 2"];
    NSString *key_3 = [NSString stringWithFormat:@"test data 3"];
    
    NSString *cache_mark = [NSString stringWithFormat:@"cache 1"];
    
    JImageLFUMemoryCache *lfu_mem_cache = [[JImageLFUMemoryCache alloc] initWithCapacity:10 marking:cache_mark];
    [lfu_mem_cache insertValue:test_data_1 forKey:key_1];
    [lfu_mem_cache insertValue:test_data_2 forKey:key_2];
    [lfu_mem_cache insertValue:test_data_3 forKey:key_3];
    
    
    NSData *fetch_cache_1 = [lfu_mem_cache fetchValueForKey:key_1];
    
    fetch_cache_1 = [lfu_mem_cache fetchValueForKey:key_1];
    fetch_cache_1 = [lfu_mem_cache fetchValueForKey:key_1];
    fetch_cache_1 = [lfu_mem_cache fetchValueForKey:key_1];
    
    NSData *fetch_cache_2 = [lfu_mem_cache fetchValueForKey:key_2];
    fetch_cache_2 = [lfu_mem_cache fetchValueForKey:key_2];
    
    [lfu_mem_cache clearMemory];
    
    XCTAssertNil([lfu_mem_cache getLfuItemKeys]);
    
    XCTAssertFalse([lfu_mem_cache existValueForKey:key_1]);
    XCTAssertFalse([lfu_mem_cache existValueForKey:key_2]);
    XCTAssertFalse([lfu_mem_cache existValueForKey:key_3]);
}

- (void)testLFU_5_multipeInsert {
    NSData *test_data_1 = [[NSString stringWithFormat:@"how are you?"] dataUsingEncoding:NSUTF8StringEncoding];
    NSData *test_data_2 = [[NSString stringWithFormat:@"fine, thanks, and you?"] dataUsingEncoding:NSUTF8StringEncoding];
    NSData *test_data_3 = [[NSString stringWithFormat:@"me to"] dataUsingEncoding:NSUTF8StringEncoding];
    
    NSString *key_1 = [NSString stringWithFormat:@"test data 1"];
    
    NSString *cache_mark = [NSString stringWithFormat:@"cache 1"];
    
    JImageLFUMemoryCache *lfu_mem_cache = [[JImageLFUMemoryCache alloc] initWithCapacity:10 marking:cache_mark];
    [lfu_mem_cache insertValue:test_data_1 forKey:key_1];
    [lfu_mem_cache insertValue:test_data_2 forKey:key_1];
    [lfu_mem_cache insertValue:test_data_3 forKey:key_1];
    
    XCTAssertEqual([lfu_mem_cache realCacheCount], 1);
    
    NSData *data = [lfu_mem_cache fetchValueForKey:key_1];
    
    XCTAssertEqual(data, test_data_3);
}

- (void)testLFU_6_monitor {
    NSString *cache_mark = [NSString stringWithFormat:@"cache 1"];
    
    JImageLFUMemoryCache *lfu_mem_cache = [[JImageLFUMemoryCache alloc] initWithCapacity:10 marking:cache_mark];
    
    int t = 1;
    while (t<10) {
        
        if (t==5) {
            lfu_mem_cache = nil;
            
            NSLog(@"should be nil");
        }
        
        t+=1;
        sleep(1);
    }
}

- (void)testLFU_7_monitor_multiple {
    JImageMemoryCache *c1 = [JImageMemoryCache memoryCacheMark:@"c1" CacheAlgorithm:MCacheAlgorithmDefault LimitOptions:nil];
    JImageMemoryCache *c2 = [JImageMemoryCache memoryCacheMark:@"c2" CacheAlgorithm:MCacheAlgorithmLFU LimitOptions:nil];
    JImageLFUMemoryCache *lfu1 = [[JImageLFUMemoryCache alloc] initWithCapacity:0 marking:@"lfu1x"];
    
    XCTAssertNotEqual(c1, c2);
    XCTAssertNotEqual(c1, lfu1);
    XCTAssertNotEqual(c2, lfu1);
    
    int t = 1;
    while (t<=10) {
        if (t==3) {
            c1 = nil;
            
            XCTAssertNil(c1);
            NSLog(@"c1 is nil");
        }
        if (t==6) {
            c2 = nil;
            
            XCTAssertNil(c2);
            NSLog(@"c2 is nil");
        }
        if (t==9) {
            lfu1 = nil;
            
            XCTAssertNil(lfu1);
            NSLog(@"lfu1 is nil");
        }
        t+=1;
        sleep(1);
    }
    
}

- (void)testLFU_7_monitor_multiple_threads {
    dispatch_queue_t queue = dispatch_queue_create("com.test.concurrent", DISPATCH_QUEUE_CONCURRENT);
    
    dispatch_async(queue, ^{
        JImageMemoryCache *c1 = [JImageMemoryCache memoryCacheMark:nil CacheAlgorithm:MCacheAlgorithmDefault LimitOptions:nil];
        
        int t = 1;
        while (t<=3) {
            if (t==3) {
                c1 = nil;
                XCTAssertNil(c1);
                NSLog(@"c1 is nil");
            }
            t+=1;
            sleep(1);
        }
    });
    dispatch_async(queue, ^{
        JImageMemoryCache *c2 = [JImageMemoryCache memoryCacheMark:nil CacheAlgorithm:MCacheAlgorithmLFU LimitOptions:nil];
        int t = 1;
        while (t<=6) {
            if (t==6) {
                c2 = nil;
                XCTAssertNil(c2);
                NSLog(@"c2 is nil");
            }
            t+=1;
            sleep(1);
        }
    });
    dispatch_async(queue, ^{
        JImageLFUMemoryCache *lfu1 = [[JImageLFUMemoryCache alloc] initWithCapacity:0 marking:nil];
        int t = 1;
        while (t<=8) {
            if (t==8) {
                lfu1 = nil;
                XCTAssertNil(lfu1);
                NSLog(@"lfu1 is nil");
            }
            t+=1;
            sleep(1);
        }
    });
    
    int t = 1;
    while (t<=12) {
        t+=1;
        sleep(1);
    }
}

- (void)testLFU_8_multithreading {
    NSData *test_data_1 = [[NSString stringWithFormat:@"how are you?"] dataUsingEncoding:NSUTF8StringEncoding];
    NSData *test_data_2 = [[NSString stringWithFormat:@"fine, thanks, and you?"] dataUsingEncoding:NSUTF8StringEncoding];
    NSData *test_data_3 = [[NSString stringWithFormat:@"me to"] dataUsingEncoding:NSUTF8StringEncoding];
    
    NSString *key_1 = [NSString stringWithFormat:@"test data 1"];
    NSString *key_2 = [NSString stringWithFormat:@"test data 2"];
    NSString *key_3 = [NSString stringWithFormat:@"test data 3"];
    
    __block JImageLFUMemoryCache *lfu1 = [[JImageLFUMemoryCache alloc] initWithCapacity:5 marking:@"lfu1"];
    
    dispatch_queue_t queue = dispatch_queue_create("com.test.concurrent", DISPATCH_QUEUE_CONCURRENT);
    dispatch_group_t group = dispatch_group_create();
    
    dispatch_group_async(group, queue, ^{
        NSLog(@"1. %@", [NSThread currentThread]);
        
        [lfu1 insertValue:test_data_1 forKey:key_1];
        [lfu1 insertValue:test_data_2 forKey:key_2];
        [lfu1 insertValue:test_data_3 forKey:key_3];
    });
    dispatch_group_async(group, queue, ^{
        NSLog(@"2. %@", [NSThread currentThread]);
        
        for (int i=0; i<100; ++i) {
            NSData *data = [[NSString stringWithFormat:@"test data NO.%d", i] dataUsingEncoding:NSUTF8StringEncoding];
            NSString *key = [NSString stringWithFormat:@"test data key %d", i];
            [lfu1 insertValue:data forKey:key];
        }
    });
    dispatch_group_async(group, queue, ^{
        NSLog(@"3. %@", [NSThread currentThread]);
        
        int t = 0;
        
        while (t<10) {
            
            NSLog(@"real count of cache:%lu", [lfu1 realCacheCount]);
            
            t++;
            sleep(1);
        }
    });
    
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    
    XCTAssertEqual([lfu1 realCacheCount], 103);
    
    [lfu1 clearMemory];
    
    XCTAssertEqual([lfu1 realCacheCount], 0);
    
    void (^destroyCache)(void) = ^(void){
        lfu1 = nil;
        NSLog(@"lfu1 is nil");
    };
    
    destroyCache();
    
    int t = 0;
    while (t<5) {
        t+=1;
        sleep(1);
    }
    
    XCTAssertNil(lfu1);
    XCTAssertEqual([lfu1 realCacheCount], 0);
}



- (void)testMCache_1_Init {
    
    NSString *mark_1 = [NSString stringWithFormat:@"test"];
    NSDictionary *options_1 = [NSDictionary dictionaryWithObjectsAndKeys:
                               [NSNumber numberWithUnsignedInteger:5], MCacheCountLimitKey,
                               [NSNumber numberWithUnsignedInteger:1024*1024], MCacheSizeLimitKey,
                               [NSNumber numberWithDouble:60*60], MCacheTimeIntervalLimitKey, nil];
    MCacheAlgorithm algo_1 = MCacheAlgorithmDefault;
    
    JImageMemoryCache *mcache_1 = [JImageMemoryCache memoryCacheMark:mark_1 CacheAlgorithm:algo_1 LimitOptions:options_1];
    
    XCTAssertNotNil(mcache_1);
    XCTAssertEqual([mcache_1 mark], mark_1);
    XCTAssertTrue([mcache_1 isKindOfClass:[JImageLFUMemoryCache class]]);
    XCTAssertFalse([mcache_1 isKindOfClass:[JImageLRUMemoryCache class]]);
    
    JImageMemoryCache *mcache_2 = [JImageMemoryCache memoryCacheMark:nil CacheAlgorithm:MCacheAlgorithmLFU LimitOptions:nil];
    
    XCTAssertNotNil(mcache_2);
    XCTAssertTrue([mcache_2 isKindOfClass:[JImageLFUMemoryCache class]]);
    XCTAssertFalse([mcache_2 isKindOfClass:[JImageLRUMemoryCache class]]);
    
    XCTAssertNotEqual(mcache_1, mcache_2);
    
    NSDictionary *options_3 = [NSDictionary dictionary];
    JImageMemoryCache *mcache_3 = [JImageMemoryCache memoryCacheMark:nil CacheAlgorithm:MCacheAlgorithmLRU LimitOptions:options_3];
    
    XCTAssertNotNil(mcache_3);
    XCTAssertFalse([mcache_3 isKindOfClass:[JImageLFUMemoryCache class]]);
    XCTAssertTrue([mcache_3 isKindOfClass:[JImageLRUMemoryCache class]]);
    
    NSString *mark_4 = @"";
    NSDictionary *options_4 = [NSDictionary dictionaryWithObjectsAndKeys:
                               [NSNumber numberWithUnsignedInteger:5], MCacheCountLimitKey, nil];
    MCacheAlgorithm algo_4 = MCacheAlgorithmLRU;
    
    JImageMemoryCache *mcache_4 = [JImageMemoryCache memoryCacheMark:mark_4 CacheAlgorithm:algo_4 LimitOptions:options_4];
    
    XCTAssertNotNil(mcache_4);
    XCTAssertFalse([mcache_4 isKindOfClass:[JImageLFUMemoryCache class]]);
    XCTAssertTrue([mcache_4 isKindOfClass:[JImageLRUMemoryCache class]]);
    
    XCTAssertNotNil([mcache_4 mark]);
    XCTAssertEqual(mark_4, [mcache_4 mark]);
    
}

- (void)testMCache_2_insert {
    NSString *mark_1 = [NSString stringWithFormat:@"test"];
    NSDictionary *options_1 = [NSDictionary dictionaryWithObjectsAndKeys:
                               [NSNumber numberWithUnsignedInteger:5], MCacheCountLimitKey,
                               [NSNumber numberWithUnsignedInteger:1024*1024], MCacheSizeLimitKey,
                               [NSNumber numberWithDouble:60*60], MCacheTimeIntervalLimitKey, nil];
    MCacheAlgorithm algo_1 = MCacheAlgorithmDefault;
    
    JImageMemoryCache *mcache_1 = [JImageMemoryCache memoryCacheMark:mark_1 CacheAlgorithm:algo_1 LimitOptions:options_1];
    NSData *test_data_1 = [[NSString stringWithFormat:@"how are you?"] dataUsingEncoding:NSUTF8StringEncoding];
    NSData *test_data_2 = [[NSString stringWithFormat:@"fine, thanks, and you?"] dataUsingEncoding:NSUTF8StringEncoding];
    NSData *test_data_3 = [[NSString stringWithFormat:@"me to"] dataUsingEncoding:NSUTF8StringEncoding];
    
    NSString *key_1 = [NSString stringWithFormat:@"test data 1"];
    NSString *key_2 = [NSString stringWithFormat:@"test data 2"];
    NSString *key_3 = [NSString stringWithFormat:@"test data 3"];
    
    [mcache_1 insertValue:test_data_1 forKey:key_1];
    [mcache_1 insertValue:test_data_2 forKey:key_2];
    [mcache_1 insertValue:test_data_3 forKey:key_3];
    
    XCTAssertEqual([mcache_1 realCacheCount], 3);
}



@end
