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



@implementation JImageLFUMemoryCache {
    NSMutableDictionary *_dictionary;
    FreqNode *_head;
    dispatch_queue_t _mqueue;
}

- (void)dealloc {
    _dictionary = nil;
    _head = nil;
    _mqueue = nil;
}

- (instancetype)init {
    return [self initWithCapacity:0 marking:nil];
}

- (instancetype)initWithCapacity:(NSUInteger)countLimit {
    return [self initWithCapacity:countLimit marking:nil];
}

- (instancetype)initWithCapacity:(NSUInteger)countLimit marking:(NSString *)mark {
    self = [super init];
    if (self) {
        _head = [[FreqNode alloc] init];
        
        if (countLimit > 0) {
            self.cacheCountLimit = countLimit;
            
            _dictionary = [NSMutableDictionary dictionaryWithCapacity:countLimit];
        } else {
            _dictionary = [NSMutableDictionary dictionary];
        }
        
        if (mark) {
            self.mark = mark;
        }
        
        self.cacheTimeInterval = 60 * 60 * 24 * 3.5;
        
        _mqueue = dispatch_queue_create("com.viwii.jimagelfumemorycache", DISPATCH_QUEUE_SERIAL);
        
        
    }
    return self;
}

// inherit methods

- (void)insertValue:(NSData *)data forKey:(NSString *)key {
    if (!key || ![key isKindOfClass:[NSString class]]) {
        NSLog(@"key is illicit");
        return;
    }
    
    dispatch_sync(_mqueue, ^{
        
        LfuItem *existedItem = [_dictionary objectForKey:key];
        FreqNode *parentNode = nil;
        
        // get parent node
        if (existedItem) {
            [_dictionary removeObjectForKey:key];
            
            parentNode = (FreqNode *)existedItem.parentNode;
        } else {
            parentNode = _head;
        }
        
        FreqNode *node = [self increasingNodeNextToParentNode:parentNode];
        
        // save key
        [node addItem:key];
        
        // save item
        [_dictionary setObject:[[LfuItem alloc] initWithData:data parentNode:node] forKey:key];
        
        //at last, update parent node status if need
        if (existedItem) {
            [parentNode removeItem:key];
            
            if ([parentNode itemCount] == 0) {
                [self deleteFreqNode:parentNode];
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
    
    dispatch_sync(_mqueue, ^{
        LfuItem *item = [_dictionary objectForKey:key];
        if (!item) {
            NSLog(@"item not find for key:%@", key);
            return;
        }
        [_dictionary removeObjectForKey:key];
        
        value = item.data;
        FreqNode *parentNode = (FreqNode *)item.parentNode;
        
        if (!parentNode) {
            NSLog(@"item.parentNode(weak refrence) is released");
            return;
        }
        
        FreqNode *node = [self increasingNodeNextToParentNode:parentNode];
        
        [node addItem:key];
        [_dictionary setObject:[[LfuItem alloc] initWithData:value parentNode:parentNode] forKey:key];
        
        //at last, update parent node status if need
        [parentNode removeItem:key];
        if ([parentNode itemCount] == 0) {
            [self deleteFreqNode:parentNode];
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
    [_dictionary removeAllObjects];
    
    _dictionary = nil;
    
    FreqNode *p = _head;
    while (p) {
        [p.items removeAllObjects];
        
        p = (FreqNode *)p.nextNode;
    }
    
    _head = nil;
    
    // reset
    
    if (self.cacheCountLimit > 0) {
        _dictionary = [NSMutableDictionary dictionaryWithCapacity:self.cacheCountLimit];
    } else {
        _dictionary = [NSMutableDictionary dictionary];
    }
    
    _head = [[FreqNode alloc] init];
}

- (NSUInteger)realCacheCount {
    __block NSUInteger count = 0;
    dispatch_sync(_mqueue, ^{
        count = [_dictionary count];
    });
    return count;
}

// help method

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

@end
