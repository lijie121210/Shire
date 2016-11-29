//
//  JOperationNode.h
//  Shire
//
//  Created by jie on 2016/11/24.
//  Copyright © 2016年 huatengIOT. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JUpdatableOperationContext.h"
#import "JIncrementalImageResource.h"

@interface JOperationNode : NSObject

@property (readwrite, getter=isFinishedSuccessfully) BOOL finishedSuccessfully;
@property (nullable, readonly, strong) id operation;
@property (nullable, readonly) NSMutableSet<JUpdatableOperationContext> * contexts;

- (nullable instancetype)initWithOperation:(nonnull id)operation;

- (nullable instancetype)initWithOperation:(nonnull id)operation andContext:(nullable id<JUpdatableOperationContext>)context;

- (void)addContext:(nonnull id)ctx;

- (void)removeContext:(nonnull id)ctx;

- (nullable JOperationNode *)refreshContexts:(nullable id<JUpdatableOperationContext>)context;

- (void)updateContextsWithResource:(nonnull id)resource;

- (void)updateContext:(nonnull id<JUpdatableOperationContext>)context withResource:(nonnull id)resource;

@end
