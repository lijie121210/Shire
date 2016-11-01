//
//  JImageLFUMemoryCache.h
//  Shire
//
//  Created by jie on 2016/10/25.
//  Copyright © 2016年 huatengIOT. All rights reserved.
//

#import "JImageMemoryCache.h"

@interface JImageLFUMemoryCache : JImageMemoryCache

- (instancetype)initWithCapacity:(NSUInteger)countLimit marking:(NSString *)mark;

- (instancetype)initWithCapacity:(NSUInteger)countLimit;

- (NSArray *)getLfuItemKeys;

@end




@interface LfuItem : JImageMemoryCacheItem

@end




@interface FreqNode : JImageMemoryCacheNode

@property (nonatomic, assign) NSInteger frequencyValue;
@property (nonatomic, readonly, copy) NSMutableSet *items;

- (instancetype)initWithFrequencyValue:(NSInteger)frequency previousNode:(FreqNode *)pre nextNode:(FreqNode *)next;

// for test
- (NSString *)getRandomItem;
- (NSArray<NSString *> *)getItems;
- (NSUInteger)itemCount;
- (void)addItem:(NSString *)object;
- (void)removeItem:(NSString *)object;

@end
