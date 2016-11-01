//
//  ShireTests.m
//  ShireTests
//
//  Created by jie on 16/9/25.
//  Copyright © 2016年 huatengIOT. All rights reserved.
//

#import <XCTest/XCTest.h>



@interface ShireTests : XCTestCase

@end

@implementation ShireTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
    
    NSLog(@"set up code");
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
    
    NSLog(@"teat down code");
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    
    NSLog(@"test example");
}


- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}


- (void)testDictionary {
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] initWithCapacity:2];
    [dic setObject:@"1" forKey:@"a"];
    [dic setObject:@"2" forKey:@"b"];
    
    XCTAssertEqual(dic.count, 2);
    
    [dic setObject:@"3" forKey:@"c"];
    
    XCTAssertEqual(dic.count, 3);
    
    const char keys[8] = {'d','e','f','g','h','i','j','k'};
    
    for (int i=0; i<8; ++i) {
        [dic setObject:[NSString stringWithFormat:@"%d", i] forKey:[NSString stringWithFormat:@"%c", keys[i]]];
    }
    
    XCTAssertEqual(dic.count, 11);
}

- (void)testDictionaryUpdate {
    NSCache *cache = [[NSCache alloc] init];
    cache.name = @"name 1";
    
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    [dic setObject:cache forKey:@"cache"];
    
    NSCache *theCache = [dic objectForKey:@"cache"];
    
    XCTAssertEqual(cache, theCache);
    XCTAssertEqual(dic.count, 1);
    
    theCache.name = @"name 2";
    
    XCTAssertEqual(dic.count, 1);
    
    NSCache *theCache_updated = [dic objectForKey:@"cache"];
    
    XCTAssertEqual(theCache_updated.name, theCache.name);
}

- (void)testDictionaryUpdate_2 {
    NSString *name_befor = [NSString stringWithFormat:@"name 1"];
    NSString *name_after = [NSString stringWithFormat:@"name 2"];
    NSString *key = [NSString stringWithFormat:@"cache key"];
    
    NSCache *cache = [[NSCache alloc] init];
    cache.name = name_befor;
    
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    [dic setObject:cache forKey:@"cache"];
    
    NSCache *theCache = [dic objectForKey:@"cache"];
    
    XCTAssertEqual(theCache, cache);
    XCTAssertEqual(theCache.name, name_befor);
    
    [dic removeObjectForKey:@"cache"];
    
    XCTAssertEqual(dic.count, 0);
    XCTAssertNotNil(theCache);
    
    NSCache *new_cache = [[NSCache alloc] init];
    new_cache.name = name_after;
    
    [dic setObject:new_cache forKey:key];
    
    XCTAssertEqual(dic.count, 1);
   
    NSCache *update_cache = [dic objectForKey:key];
    
    XCTAssertNotEqual(update_cache, cache);
    XCTAssertEqual(update_cache, new_cache);
}






@end
