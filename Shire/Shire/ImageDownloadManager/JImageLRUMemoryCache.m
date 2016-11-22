//
//  JImageLRUMemoryCache.m
//  Shire
//
//  Created by jie on 2016/10/28.
//  Copyright © 2016年 huatengIOT. All rights reserved.
//

#import "JImageLRUMemoryCache.h"

@interface LruItem : JImageMemoryCacheItem

@end

@implementation LruItem

@end


@interface LruNode : JImageMemoryCacheNode

@property (nonatomic, copy) NSString *key;

- (instancetype)initWithKey:(NSString *)key previousNode:(LruNode *)pre nextNode:(LruNode *)next;

@end

@implementation LruNode

- (instancetype)init {
    self = [super init];
    if (self) {
        self.preNode = nil;
        self.nextNode = nil;
        self.key = nil;
    }
    return self;
}
- (instancetype)initWithKey:(NSString *)key previousNode:(LruNode *)pre nextNode:(LruNode *)next;
{
    self = [super init];
    if (self) {
        self.preNode = pre;
        self.nextNode = next;
        self.key = [key copy];
    }
    return self;
}

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }
    if (![object isKindOfClass:[LruNode class]]) {
        return NO;
    }
    if (![self.key isEqualToString:[(LruNode *)object key]]) {
        return NO;
    }
    return YES;
}

- (NSUInteger)hash {
    return [self.key hash];
}

@end

@interface JImageLRUMemoryCache ()

@property NSUInteger cacheSizeLimit;
@property NSUInteger cacheCountLimit;
@property NSTimeInterval cacheTimeInterval;

@end

@implementation JImageLRUMemoryCache {
    NSMutableDictionary *_dictionary;
    LruNode *_head;
    LruNode *_tail;
    dispatch_queue_t _mqueue;
}

@synthesize cacheSizeLimit = _cacheSizeLimit;
@synthesize cacheCountLimit = _cacheCountLimit;
@synthesize cacheTimeInterval = _cacheTimeInterval;


- (void)dealloc {
    _dictionary = nil;
    _head = nil;
    _tail = nil;
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
        _head = [[LruNode alloc] init];
        _tail = _head;
        
        if (countLimit > 3) {
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
                
        _mqueue = dispatch_queue_create("com.viwii.jimagelrumemorycache", DISPATCH_QUEUE_SERIAL);
        
        [self startMonitorLoop];
    }
    return self;
}


#pragma mark - protocol


-(void)insertValue:(id)data forKey:(id<NSCopying>)key {
    if (!key) {
        NSLog(@"key is nil");
        return;
    }
    __weak typeof(self) weakself = self;
    dispatch_sync(_mqueue, ^{
        __strong typeof(weakself) sself = weakself;
        
        LruItem *existedItem = [_dictionary objectForKey:key];
        
        if (existedItem) {
            /*
             * 1.查到了该key已经保存，并且当前链表也存在别的节点； 此时更新 项目 的数据，并调整 项目 对应的 节点 到最前；
             */
            [sself insertValue:data forExsitedKey:(NSString *)key andExsitedItem:existedItem];
        } else {
            /* 还有另外两种情况，可以共享一种处理代码
             * 2. 尚不存在节点;
             * 3. 查不到该key，并且当前链表存在别的节点；
             */
            if (sself.cacheCountLimit>3 && sself.cacheCountLimit <= _dictionary.count) {
                [self deleteTailNodeAndUpdateDictionaryItem];
            }
            
            LruNode *node = [[LruNode alloc] initWithKey:(NSString *)key previousNode:_head nextNode:(LruNode *)_head.nextNode];
            
            if (_head.nextNode) {
                _head.nextNode.preNode = node;
            } else {
                _tail = node;
            }
            _head.nextNode = node;
            
            [_dictionary setObject:[[LruItem alloc] initWithData:data parentNode:node] forKey:key];
        }
    });
}

-(NSData *)fetchValueForKey:(NSString *)key {
    if (!key) {
        NSLog(@"key is nil");
        return nil;
    }
    __block id value = nil;
    __weak typeof(self) weakself = self;
    dispatch_sync(_mqueue, ^{
        __strong typeof(weakself) sself = weakself;
        
        LruItem *item = [_dictionary objectForKey:key];
        
        if (_dictionary.count == 0 || !item) {
            return;
        }
        [_dictionary removeObjectForKey:key];

        value = item.data;
        LruNode *parentNode = (LruNode *)item.parentNode;
        
        [sself adjustExsitedNodeToFront:parentNode];
        
        [_dictionary setObject:[[LruItem alloc] initWithData:value parentNode:parentNode] forKey:key];
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

- (void)clearMemory {
    __weak typeof(self) weakself = self;
    
    dispatch_sync(_mqueue, ^{
        __strong typeof(weakself) sself = weakself;
        
        // remove
        
        while (_head != _tail) {
            [sself deleteTailNode];
        }
        _head = _tail = nil;
        
        [_dictionary removeAllObjects];
        _dictionary = nil;
        
        //
        
        _head = [[LruNode alloc] init];
        _tail = _head;
        
        if (self.cacheCountLimit > 3) {
            _dictionary = [NSMutableDictionary dictionaryWithCapacity:sself.cacheCountLimit];
        } else {
            _dictionary = [NSMutableDictionary dictionary];
        }
    });
}

- (NSUInteger)realCacheCount {
    __block NSUInteger count = 0;
    dispatch_sync(_mqueue, ^{
        count = [_dictionary count];
    });
    return count;
}

#pragma mark - help method

/*!
 @discussion
    insert exsited key does not need to create a new node, 
    but the item should be removed and added;
 @param data 
    value of object
 @param key
    key for value
 @param existedItem
    Item read from dictionary, can be nil;
 */
- (void)insertValue:(NSData *)data forExsitedKey:(NSString *)key andExsitedItem:(LruItem *)existedItem {
    if (!data || !key) {
        return;
    }
    if (!existedItem) {
        existedItem = [_dictionary objectForKey:existedItem];
    }
    [_dictionary removeObjectForKey:key];
    
    LruNode *node = (LruNode *)existedItem.parentNode;
    if (!node) {
        NSLog(@"an error occured! this item <%@> parentNode is nil", existedItem);
    }
    
    [self adjustExsitedNodeToFront:node];
    
    [_dictionary setObject:[[LruItem alloc] initWithData:data parentNode:node] forKey:key];
}

/*!
 @discussion
    this method simply adjusts the position of the node in the doubly linked list,
    does not create neither delete the other node,
    in addition to the _tail node;
 @param node 
    the node needs adjust;
 */
- (void)adjustExsitedNodeToFront:(LruNode *)node {
    if (!node) {
        return;
    }
    if ([node isEqual:_head]) {
        NSLog(@"error: trying adjust head < %@ >", node);
        return;
    }
    
    // 正确断开：链接该节点的上下节点
    if (node.preNode) {
        node.preNode.nextNode = node.nextNode;
        
        if (node.nextNode) {
            node.nextNode.preNode = node.preNode;
        } else {
            _tail = (LruNode *)node.preNode;
        }
    } else {
        NSLog(@"error : this node has no previous node< %@ >", node);
    }
    
    // 正确插入：链接在_head节点后面
    LruNode *n_node = (LruNode *)_head.nextNode;
    if (n_node) {
        node.nextNode = n_node;
        n_node.preNode = node;
        
        node.preNode = _head;
        _head.nextNode = node;
    } else {
        _head.nextNode = node;
        node.preNode = _head;
        
        _tail = node;
    }
}

/*!
 @discussion
    depends on lru, tail node is the node that should be removed;
    after doing deletion, dictionary should remove the item pointing this node, either;
 */
- (void)deleteTailNodeAndUpdateDictionaryItem {
    NSString *deletedKey = [self deleteTailNode];
    if (!deletedKey) {
        return;
    }
    LruItem *item = [_dictionary objectForKey:deletedKey];
    if (item) {
        item.data = nil;
        item.parentNode = nil;
    }
    [_dictionary removeObjectForKey:deletedKey];
}

/*!
 @discussion 
    delelte last node in the link list; this method will not affect dictionary, so operate dictionary with the return key!
 @return 
    key of deleted node; nil if this deletion discarded;
 */
- (NSString *)deleteTailNode {
    NSString *key = nil;
    
    if ((_head != _tail) && (_tail != nil)) {
        LruNode *tail_node = _tail;
        
        key = tail_node.key;
        
        _tail = (LruNode *)tail_node.preNode;
        _tail.nextNode = nil;
        
        tail_node.preNode = nil;
        tail_node.nextNode = nil;
        tail_node = nil;
    }
    
    return key;
}



#pragma mark - Monitor


/*!
 @discussion
 this method start a timer source, which check the cache limit every five seconds
 */
- (void)startMonitorLoop {
    
    // timer call back fire block
    __weak typeof(self) wself = self;
    
    dispatch_block_t eventHandler = ^{@autoreleasepool{
        __strong typeof(wself) sself = wself;
        NSLog(@"<objc:%@, mark:%@, sel:%@> in timer event handler", sself, sself.mark, NSStringFromSelector(_cmd));
    }};
    
    // timer cancel block
    dispatch_block_t cancelHandler = ^{@autoreleasepool{
        __strong typeof(wself) sself = wself;
        NSLog(@"<objc:%@, mark:%@, sel:%@> in timer cancel handler", sself, wself.mark, NSStringFromSelector(_cmd));
    }};
    
    [self startMonitorLoopWithEventHandler:eventHandler AndCancelHandler:cancelHandler];
}

- (void)startMonitorLoopWithEventHandler:(dispatch_block_t)eventHandler AndCancelHandler:(dispatch_block_t)cancelHandler {
    [super startMonitorLoopWithEventHandler:eventHandler AndCancelHandler:cancelHandler];
}



@end





