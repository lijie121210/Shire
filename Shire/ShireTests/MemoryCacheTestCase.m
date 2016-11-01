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
    
    JImageLFUMemoryCache *lfu_minstance_c = [[JImageLFUMemoryCache alloc] initWithCapacity:_countLimit];
    
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

- (void)testSet {
    NSMutableSet *set = [NSMutableSet set];
    
    dispatch_queue_t serial = dispatch_queue_create("com.test.serial", DISPATCH_QUEUE_SERIAL);
    
    dispatch_sync(serial, ^{
        
        NSString *key_1 = [NSString stringWithFormat:@"test data 1"];
        NSString *key_2 = [NSString stringWithFormat:@"test data 2"];
        NSString *key_3 = [NSString stringWithFormat:@"test data 3"];
        
        [set addObject:key_1];
        [set addObject:key_2];
        [set addObject:key_3];
        
        
    });
    
    
    XCTAssertEqual(set.count, 3);
}


@end
