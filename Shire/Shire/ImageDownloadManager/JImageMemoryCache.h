//
//  JImageMemoryCache.h
//  Shire
//
//  Created by jie on 2016/10/25.
//  Copyright © 2016年 huatengIOT. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef NS_ENUM(NSUInteger, MCacheAlgorithm) {
    MCacheAlgorithmDefault = 1<<0,
    MCacheAlgorithmLFU = 1<<1,
    MCacheAlgorithmLRU = 1<<2,
};

extern NSString *const MCacheSizeLimitKey;
extern NSString *const MCacheCountLimitKey;
extern NSString *const MCacheTimeIntervalLimitKey;


@protocol JImageMemoryCacheAbility <NSObject>

@optional
- (void)insertValue:(NSData *)data forKey:(NSString *)key;
- (NSData *)fetchValueForKey:(NSString *)key;
- (BOOL)existValueForKey:(NSString *)key;
- (void)clearMemory;
- (NSUInteger)realCacheCount;

@end



@interface JImageMemoryCache: NSObject <JImageMemoryCacheAbility> {
    @public
    dispatch_source_t _monitorTimer;
    NSUInteger _cacheSize;
}

@property (copy) NSString *mark;
@property (readonly) NSUInteger cacheSizeLimit;
@property (readonly) NSUInteger cacheCountLimit;
@property (readonly) NSTimeInterval cacheTimeInterval;

+ (JImageMemoryCache *)memoryCacheMark:(NSString *)mark CacheAlgorithm:(MCacheAlgorithm)algorithm LimitOptions:(NSDictionary *)options;

- (void)startMonitorLoopWithEventHandler:(dispatch_block_t)eventHandler AndCancelHandler:(dispatch_block_t)cancelHandler;

@end




/* private class */

@class JImageMemoryCacheNode;

/*!
 * The instance of JImageMemoryCacheItem will be used to construct a dictionary,
 * while the key will always be isntance of NSString;
 {
    @"key 1": item_1,
    @"key 2": item_2...
 }
 */
@interface JImageMemoryCacheItem : NSObject

@property (nonatomic, strong) id data;
@property (nonatomic, strong) JImageMemoryCacheNode *parentNode;

- (instancetype)initWithData:(id)data parentNode:(JImageMemoryCacheNode *)pnode;

@end

/*!
 * The instance of JImageMemoryCacheNode(subclass actually) will be used to construct a doubly linked list;
 */
@interface JImageMemoryCacheNode : NSObject

@property (nonatomic, weak) JImageMemoryCacheNode *preNode;
@property (nonatomic, strong) JImageMemoryCacheNode *nextNode;

@end
