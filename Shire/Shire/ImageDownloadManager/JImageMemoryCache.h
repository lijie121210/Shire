//
//  JImageMemoryCache.h
//  Shire
//
//  Created by jie on 2016/10/25.
//  Copyright © 2016年 huatengIOT. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JImageMemoryCache: NSObject

@property (copy) NSString *mark;

@property NSUInteger cacheSizeLimit;
@property NSUInteger cacheCountLimit;
@property NSTimeInterval cacheTimeInterval;

- (void)insertValue:(NSData *)data forKey:(NSString *)key;

- (NSData *)fetchValueForKey:(NSString *)key;

- (BOOL)existValueForKey:(NSString *)key;

- (void)clearMemory;

- (NSUInteger)realCacheCount;

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
