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



@implementation JImageLRUMemoryCache {
    NSMutableDictionary *_dictionary;
    LruNode *_head;
    LruNode *_tail;
    dispatch_queue_t _mqueue;
}

- (void)dealloc {
    _dictionary = nil;
    _head = nil;
    _tail = nil;
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
        _head = [[LruNode alloc] init];
        _tail = _head;
        
        if (countLimit > 3) {
            self.cacheCountLimit = countLimit;
            
            _dictionary = [NSMutableDictionary dictionaryWithCapacity:countLimit];
        } else {
            
            _dictionary = [NSMutableDictionary dictionary];
        }
        
        if (mark) {
            self.mark = mark;
        }
        
        self.cacheTimeInterval = 60 * 60 * 24 * 3.5;
        
        _mqueue = dispatch_queue_create("com.viwii.jimagelrumemorycache", DISPATCH_QUEUE_SERIAL);
        
    }
    return self;
}


// inherit method

-(void)insertValue:(id)data forKey:(id<NSCopying>)key {
    if (!key) {
        NSLog(@"key is nil");
        return;
    }
    
    dispatch_sync(_mqueue, ^{
        
        LruItem *item = nil;

        if (_head == _tail) {
            // 尚不存在节点；直接创建 节点 和 项目 ，建立关联 并 保存；
            
            LruNode *node = [[LruNode alloc] initWithKey:(NSString *)key previousNode:_head nextNode:nil];
            
            _head.nextNode = node;
            _tail = node;
            
            item = [[LruItem alloc] initWithData:data parentNode:node];
        } else {
            LruItem *existedItem = [_dictionary objectForKey:key];
            
            if (existedItem) {
                // 查到了该key已经保存，并且当前链表也存在别的节点； 此时更新 项目 的数据，并调整 项目 对应的 节点 到最前；
                
                [_dictionary removeObjectForKey:key];
                
                LruNode *node = (LruNode *)existedItem.parentNode;
                
                
                if (!node) {
                    NSLog(@"an error occured! this item <%@> parentNode is nil", item);
                }
                
                [self adjustExsitedNodeToFront:node];
                
                item = [[LruItem alloc] initWithData:data parentNode:node];
            } else {
                //查不到该key，并且当前链表存在别的节点；
                
                if (self.cacheCountLimit>3 && self.cacheCountLimit <= _dictionary.count) {
                    // 设定了缓存数量上限，且已满; 删除链表最后一个节点，并删除它在字典中的对应项目
                    
                    LruNode *tail_node = _tail;
                    
                    if (!tail_node || !tail_node.key) {
                        NSLog(@"error tail pointer or tail'key is nil");
                        return;
                    }
                    
                    [_dictionary removeObjectForKey:tail_node.key];
                    
                    _tail = (LruNode *)tail_node.preNode;
                    _tail.nextNode = nil;
                    tail_node.preNode = nil;
                    tail_node = nil;
                }
                
                LruNode *node = [[LruNode alloc] initWithKey:(NSString *)key previousNode:_head nextNode:(LruNode *)_head.nextNode];
                
                _head.nextNode.preNode = node;
                _head.nextNode = node;
                
                if (!node.nextNode) {
                    _tail = node;
                }
                
                item = [[LruItem alloc] initWithData:data parentNode:node];
            }
        }
        
        [_dictionary setObject:item forKey:key];
    });
}

-(NSData *)fetchValueForKey:(NSString *)key {
    if (!key) {
        NSLog(@"key is nil");
        return nil;
    }
    __block id value = nil;
    
    dispatch_sync(_mqueue, ^{
        if (_dictionary.count == 0) {
            return;
        }
        LruItem *item = [_dictionary objectForKey:key];
        if (!item) {
            return;
        }
        value = item.data;
        
        [_dictionary removeObjectForKey:key];
        
        LruItem *newItem = [[LruItem alloc] initWithData:item.data parentNode:item.parentNode];
        
        [self adjustExsitedNodeToFront:(LruNode *)newItem.parentNode];
        
        [_dictionary setObject:newItem forKey:key];
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

// help method

- (void)adjustExsitedNodeToFront:(LruNode *)node {
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


@end





