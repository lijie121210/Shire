//
//  JOperationNode.m
//  Shire
//
//  Created by jie on 2016/11/24.
//  Copyright © 2016年 huatengIOT. All rights reserved.
//

#import "JOperationNode.h"

@implementation JOperationNode
{
    id _operation;
    BOOL _finishedSuccessfully;
    NSMutableSet<JUpdatableOperationContext> *_contexts;
}

- (instancetype)initWithOperation:(id)operation {
    return [self initWithOperation:operation andContext:nil];
}

- (instancetype)initWithOperation:(id)operation andContext:(id<JUpdatableOperationContext>)context {
    self = [super init];
    if (self) {
        _operation = operation;
        if (context) {
            _contexts = (NSMutableSet<JUpdatableOperationContext> *)[NSMutableSet setWithObject:context];
        } else {
            _contexts = (NSMutableSet<JUpdatableOperationContext> *)[NSMutableSet set];
        }
    }
    return self;
}

- (void)setFinishedSuccessfully:(BOOL)finishedSuccessfully {
    @synchronized (self) {
        _finishedSuccessfully = finishedSuccessfully;
    }
}
- (BOOL)isFinishedSuccessfully {
    @synchronized (self) {
        return _finishedSuccessfully;
    }
}


- (id)operation {
    @synchronized (self) {
        return _operation;
    }
}

- (NSMutableSet<JUpdatableOperationContext> *)contexts {
    @synchronized (self) {
        return _contexts;
    }
}

- (void)addContext:(nonnull id)ctx {
    @synchronized (self) {
        if (ctx) {
            if (![_contexts containsObject:ctx]) {
                [_contexts addObject:ctx];
            } else {
                [_contexts removeObject:ctx];
                [_contexts addObject:ctx];
            }
        }
    }
}

- (void)removeContext:(nonnull id)ctx {
    @synchronized (self) {
        if (ctx && [_contexts containsObject:ctx]) {
            [_contexts removeObject:ctx];
        }
    }
}

- (nullable JOperationNode *)refreshContexts:(nullable id<JUpdatableOperationContext>)context {
    @synchronized (self) {
        JOperationNode *node = [[JOperationNode alloc] initWithOperation:_operation andContext:context];
        if (_contexts.count > 0) {
            for (id<JUpdatableOperationContext> ctx in _contexts) {
                [node addContext:ctx];
            }
        }
        return node;
    }
    
}

- (void)updateContextsWithResource:(id)resource {
    dispatch_queue_t global = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    for (id<JUpdatableOperationContext> object in _contexts) {
        dispatch_async(global, ^{
            [object updateOperationContextWithResource:resource];
        });
    }
}

- (void)updateContext:(id<JUpdatableOperationContext>)context withResource:(id)resource {
    @synchronized (self) {
        [context updateOperationContextWithResource:resource];
    }
}

@end
