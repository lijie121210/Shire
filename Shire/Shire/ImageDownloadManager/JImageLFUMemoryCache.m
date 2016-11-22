//
//  JImageLFUMemoryCache.m
//  Shire
//
//  Created by jie on 2016/10/25.
//  Copyright © 2016年 huatengIOT. All rights reserved.
//

#import "JImageLFUMemoryCache.h"

@implementation LfuItem

@end

@implementation FreqNode

- (instancetype)init {
    self = [super init];
    if (self) {
        _frequencyValue = 0;
        self.preNode = nil;
        self.nextNode = nil;
        _items = [NSMutableSet set];
    }
    return self;
}
- (instancetype)initWithFrequencyValue:(NSInteger)frequency previousNode:(FreqNode *)pre nextNode:(FreqNode *)next
{
    self = [super init];
    if (self) {
        _frequencyValue = frequency;
        self.preNode = pre;
        self.nextNode = next;
        _items = [NSMutableSet set];
    }
    return self;
}

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }
    if (![object isKindOfClass:[FreqNode class]]) {
        return NO;
    }
    FreqNode *node = (FreqNode *)object;
    if (self.frequencyValue != node.frequencyValue) {
        return NO;
    }
    if (self.items.count != node.items.count) {
        return NO;
    }
    return YES;
}

- (NSUInteger)hash {
    return [[NSString stringWithFormat:@"%ld %lu",(long)_frequencyValue, [_items count]] hash];
}

- (NSString *)getRandomItem {
    if (_items) {
        return _items.objectEnumerator.nextObject;
    } else {
        return nil;
    }
}

- (NSArray<NSString *> *)getItems {
    if (_items) {
        return _items.allObjects;
    } else {
        return nil;
    }
}
- (NSUInteger)itemCount {
    if (_items) {
        return _items.count;
    } else {
        return 0;
    }
}
- (void)addItem:(NSString *)object {
    if (object && _items) {
        [_items addObject:object];
    }
}
- (void)removeItem:(NSString *)object {
    if (object && _items) {
        [_items removeObject:object];
    }
}

@end


@interface JImageLFUMemoryCache ()

@property NSUInteger cacheSizeLimit;
@property NSUInteger cacheCountLimit;
@property NSTimeInterval cacheTimeInterval;

@end

@implementation JImageLFUMemoryCache {
    NSMutableDictionary *_dictionary;
    FreqNode *_head;
    
    dispatch_queue_t _mqueue;
}

@synthesize cacheSizeLimit = _cacheSizeLimit;
@synthesize cacheCountLimit = _cacheCountLimit;
@synthesize cacheTimeInterval = _cacheTimeInterval;

- (void)dealloc {
    _dictionary = nil;
    _head = nil;
    _mqueue = nil;
}

- (instancetype)init {
    return [self initWithCapacity:0 CostLimit:0 AgeLimit:0 Marking:nil];
}

- (instancetype)initWithCapacity:(NSUInteger)countLimit marking:(NSString *)mark {
    return [self initWithCapacity:countLimit CostLimit:0 AgeLimit:0 Marking:mark];
}

- (instancetype)initWithCostLimit:(NSUInteger)costLimit marking:(NSString *)mark {
    return [self initWithCapacity:0 CostLimit:costLimit AgeLimit:0 Marking:mark];
}

- (instancetype)initWithAgeLimit:(NSTimeInterval)ageLimit marking:(NSString *)mark {
    return [self initWithCapacity:0 CostLimit:0 AgeLimit:ageLimit Marking:mark];
}

- (instancetype)initWithCapacity:(NSUInteger)countLimit CostLimit:(NSUInteger)costLimit AgeLimit:(NSTimeInterval)ageLimit Marking:(NSString *)mark {
    self = [super init];
    if (self) {
        _head = [[FreqNode alloc] init];
        
        if (countLimit > 0) {
            self.cacheCountLimit = countLimit;
            
            _dictionary = [NSMutableDictionary dictionaryWithCapacity:countLimit];
        } else {
            _dictionary = [NSMutableDictionary dictionary];
        }
        if (costLimit > 0) {
            self.cacheSizeLimit = costLimit;
        }
        if (ageLimit > 0) {
            self.cacheTimeInterval = ageLimit;
        } else {
            self.cacheTimeInterval = 60 * 60 * 24;
        }
        if (mark) {
            self.mark = mark;
        }
        
        _mqueue = dispatch_queue_create("com.viwii.jimagelfumemorycache", DISPATCH_QUEUE_SERIAL);
        
        [self startMonitorLoop];
    }
    return self;
}

#pragma mark - protocol

- (void)insertValue:(NSData *)data forKey:(NSString *)key {
    if (!key || ![key isKindOfClass:[NSString class]]) {
        NSLog(@"key is illicit");
        return;
    }
    __weak typeof(self) weakself = self;
    dispatch_sync(_mqueue, ^{
        __strong typeof(weakself) sself = weakself;
        
        LfuItem *existedItem = [_dictionary objectForKey:key];
        FreqNode *parentNode = nil;
        
        // get parent node
        if (existedItem) {
            [_dictionary removeObjectForKey:key];
            
            parentNode = (FreqNode *)existedItem.parentNode;
        } else {
            parentNode = _head;
        }
        
        // create new parent node, which indicate the right frequency
        FreqNode *node = [sself increasingNodeNextToParentNode:parentNode];
        
        // save key
        [node addItem:key];
        
        // save item
        [_dictionary setObject:[[LfuItem alloc] initWithData:data parentNode:node] forKey:key];
        
        //at last, update parent node status if need
        if (existedItem) {
            [parentNode removeItem:key];
            
            if ([parentNode itemCount] == 0) {
                [sself deleteFreqNode:parentNode];
            }
        }
    });
}

- (NSData *)fetchValueForKey:(NSString *)key {
    if (!key) {
        NSLog(@"key is nil");
        return nil;
    }
    __block id value = nil;
    __weak typeof(self) weakself = self;
    dispatch_sync(_mqueue, ^{
        __strong typeof(weakself) sself = weakself;
        
        LfuItem *item = [_dictionary objectForKey:key];
        if (!item) {
            NSLog(@"item not find for key:%@", key);
            return;
        }
        
        // remove this item from dictionary
        [_dictionary removeObjectForKey:key];
        
        // get item's value
        value = item.data;
        
        // get item's parent node on the link list
        FreqNode *parentNode = (FreqNode *)item.parentNode;
        
        if (!parentNode) {
            NSLog(@"item.parentNode(weak refrence) is released");
            return;
        }
        
        // create new parent node, which indicate the right frequency
        FreqNode *node = [sself increasingNodeNextToParentNode:parentNode];
        
        // save key to node's set
        [node addItem:key];
        
        // save new item for key
        [_dictionary setObject:[[LfuItem alloc] initWithData:value parentNode:parentNode] forKey:key];
        
        //at last, update parent node status if need
        [parentNode removeItem:key];
        if ([parentNode itemCount] == 0) {
            [sself deleteFreqNode:parentNode];
        }
    });
    
    return value;
}

-(BOOL)existValueForKey:(NSString *)key {
    if (!key) {
        NSLog(@"key is nil");
        return NO;
    }
    __block BOOL existed = NO;
    
    dispatch_sync(_mqueue, ^{
        if (_dictionary && _dictionary.count > 0) {
            existed = [[_dictionary allKeys] containsObject:key];
        }
    });
    
    return existed;
}

-(void)clearMemory {
    __weak typeof(self) weakself = self;
    
    dispatch_sync(_mqueue, ^{
        __strong typeof(weakself) sself = weakself;
        
        // remove
        
        [_dictionary removeAllObjects];
        
        _dictionary = nil;
        
        FreqNode *p = _head;
        while (p) {
            [p.items removeAllObjects];
            
            p = (FreqNode *)p.nextNode;
        }
        
        _head = nil;
        
        // reset
        
        if (sself.cacheCountLimit > 0) {
            _dictionary = [NSMutableDictionary dictionaryWithCapacity:self.cacheCountLimit];
        } else {
            _dictionary = [NSMutableDictionary dictionary];
        }
        
        _head = [[FreqNode alloc] init];
    });
}

- (NSUInteger)realCacheCount {
    __block NSUInteger count = 0;
    dispatch_sync(_mqueue, ^{
        count = [_dictionary count];
    });
    return count;
}

- (NSUInteger)realCacheSize {
    __block NSUInteger count = 0;
    dispatch_sync(_mqueue, ^{
        count = _cacheSize;
    });
    return count;
}


#pragma mark - help method

- (void)deleteFreqNode:(FreqNode *)fnode {
    
    __block FreqNode *node = fnode;
    
    dispatch_async(_mqueue, ^{
        if (!node) {
            return;
        }
        if (!node.preNode && node.nextNode) {
            NSLog(@"like deleting head node");
            node.nextNode.preNode = nil;
            node.nextNode = nil;
        }
        if (node.preNode && !node.nextNode) {
            node.preNode.nextNode = nil;
            node.preNode = nil;
        }
        if (node.preNode && node.nextNode) {
            node.preNode.nextNode = node.nextNode;
            node.nextNode.preNode = node.preNode;
            node.preNode = nil;
            node.nextNode = nil;
        }
        
        node = nil;
    });
}

- (FreqNode *)increasingNodeNextToParentNode:(FreqNode *)parentNode {
    if (!parentNode) {
        return nil;
    }
    
    FreqNode *node = (FreqNode *)parentNode.nextNode;
    if (!node) {
        node = [[FreqNode alloc] initWithFrequencyValue:(parentNode.frequencyValue + 1) previousNode:parentNode nextNode:nil];
    }
    if (node.frequencyValue != (parentNode.frequencyValue + 1)) {
        node = [[FreqNode alloc] initWithFrequencyValue:(parentNode.frequencyValue + 1) previousNode:parentNode nextNode:node];
        parentNode.nextNode.preNode = node;
    }
    parentNode.nextNode = node;
    
    return node;
}

- (LfuItem *)getLfuItem {
    __block LfuItem *item = nil;
    
    dispatch_sync(_mqueue, ^{
        if (_dictionary.count == 0) {
            return;
        }
        
        id key = [[((FreqNode *)_head.nextNode).items objectEnumerator] nextObject];
        
        if (key) {
            item = [_dictionary objectForKey:key];
        }
    });
    
    return item;
}


// for test
- (NSArray *)getLfuItemKeys {
    __block NSArray *keys = nil;
    
    dispatch_sync(_mqueue, ^{
        if (_dictionary.count == 0) {
            return;
        }
        keys = [((FreqNode *)_head.nextNode) getItems];
    });
    
    return keys;
}



#pragma mark - Monitor todo

- (void)monitorCurrentCount:(NSUInteger)count Limit:(NSUInteger)limit {
    
    NSLog(@"<objc:%@>", self);
    /*if (count >= limit) {
        NSUInteger exceeded = count - limit;
    }*/
}
- (void)monitorCurrentSize:(NSUInteger)size Limit:(NSUInteger)limit {
    /*if (size >= limit) {
        NSUInteger exceeded = size - limit;
    }*/
}
- (void)cacheElementAgeMonitor {
    
}

/*!
 @discussion
    this method start a timer source, which check the cache limit every five seconds
 */
- (void)startMonitorLoop {
    
    // timer call back fire block
    __weak typeof(self) wself = self;
    
    dispatch_block_t eventHandler = ^{@autoreleasepool{
        
        __strong typeof(wself) sself = wself;
        
        NSUInteger currentCount = [sself realCacheCount];
        //NSUInteger currentSize = [sself realCacheSize];
        
        [sself monitorCurrentCount:currentCount Limit:sself.cacheCountLimit];
        //[sself monitorCurrentSize:currentSize Limit:sself.cacheSizeLimit];
        
        NSLog(@"<objc:%@, mark:%@, sel:%@> in timer event handler", sself, sself.mark, NSStringFromSelector(_cmd));
    }};
    
    // timer cancel block
    dispatch_block_t cancelHandler = ^{@autoreleasepool{
        __strong typeof(wself) sself = wself;
        NSUInteger currentCount = [sself realCacheCount];        
        [sself monitorCurrentCount:currentCount Limit:sself.cacheCountLimit];
        
        NSLog(@"<sel:%@> in timer cancel handler", NSStringFromSelector(_cmd));
    }};
    
    [self startMonitorLoopWithEventHandler:eventHandler AndCancelHandler:cancelHandler];
}

/*!
 @override
 */
- (void)startMonitorLoopWithEventHandler:(dispatch_block_t)eventHandler AndCancelHandler:(dispatch_block_t)cancelHandler {
    [super startMonitorLoopWithEventHandler:eventHandler AndCancelHandler:cancelHandler];
}

@end
