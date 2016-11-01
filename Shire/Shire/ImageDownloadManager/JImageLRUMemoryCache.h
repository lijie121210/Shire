//
//  JImageLRUMemoryCache.h
//  Shire
//
//  Created by jie on 2016/10/28.
//  Copyright © 2016年 huatengIOT. All rights reserved.
//

#import "JImageMemoryCache.h"

@interface JImageLRUMemoryCache : JImageMemoryCache
/* 
 * 设置的数量限制应该大于3，并且该类对这个限制提供精确控制，理论上不会出现超过限制的可能；
 * 达到限制值后，再插入时，会直接移除算法应该移除的元素，然后插入；
 */
- (instancetype)initWithCapacity:(NSUInteger)countLimit marking:(NSString *)mark;

- (instancetype)initWithCapacity:(NSUInteger)countLimit;

@end
