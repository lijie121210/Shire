//
//  JImageCache.m
//  Shire
//
//  Created by jie on 2016/10/22.
//  Copyright © 2016年 huatengIOT. All rights reserved.
//

#import "JImageCache.h"

@implementation JImageCache


+ (JImageCache *)sharedCache {
    return nil;
}

- (void)insertImage:(UIImage *)image forKey:(NSString *)key includeDisk:(BOOL)incDisk {
    
}

- (void)queryImage:(NSString *)forKey completionCallBack:(void (^)(UIImage *, JImageCacheType))completion {
    
}

- (UIImage *)imageForKey:(NSString *)key {
    return nil;
}

- (void)existImage:(NSString *)forKey completionCallBack:(void (^)(BOOL))completion {
    
}

- (BOOL)existImageForKey:(NSString *)key {
    return NO;
}

- (void)removeImage:(NSString *)forKey onlyFromDisk:(BOOL)fromDisk completionCallBack:(void (^)())completion {
    
}

- (void)clearDisk:(BOOL)onlyExpired completionCallBack:(void (^)())completion {
    
}

- (void)clearMemory {
    
}

- (NSString *)cachePathForKey:(NSString *)key underFolder:(NSString *)rootFolder {
    return nil;
}

- (void)cacheSize:(void (^)(NSUInteger files, NSUInteger size))completion {
    
}

- (NSUInteger)diskCacheSize {
    return 0;
}

- (NSUInteger)diskCacheCount {
    return 0;
}


@end
