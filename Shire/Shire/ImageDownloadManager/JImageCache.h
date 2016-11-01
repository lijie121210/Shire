//
//  JImageCache.h
//  Shire
//
//  Created by jie on 2016/10/22.
//  Copyright © 2016年 huatengIOT. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, JImageCacheType) {
    JImageCacheTypeNone,
    JImageCacheTypeDisk,
    JImageCacheTypeMemory,
};


@interface JImageCache : NSObject

@property (nonatomic, assign) NSUInteger cacheSizeLimit;
@property (nonatomic, assign) NSUInteger cacheCountLimit;
@property (nonatomic, assign) NSTimeInterval cacheTimeInterval;

+ (JImageCache *)sharedCache;

// incDisk ： false只缓存图片到内存，true缓存到内存和磁盘
- (void)insertImage:(UIImage *)image forKey:(NSString *)key includeDisk:(BOOL)incDisk;

//异步读取缓存的图片
- (void)queryImage:(NSString *)forKey completionCallBack:(void (^)(UIImage *, JImageCacheType))completion;
//同步读取缓存的图片
- (UIImage *)imageForKey:(NSString *)key;
//异步判断图片是否存在
- (void)existImage:(NSString *)forKey completionCallBack:(void (^)(BOOL))completion;
//同步判断图片是否存在
- (BOOL)existImageForKey:(NSString *)key;
//fromDisk ： true从内存和磁盘删除图片缓存，false只删除内存中的图片缓存
- (void)removeImage:(NSString *)forKey onlyFromDisk:(BOOL)fromDisk completionCallBack:(void (^)())completion;
//onlyExpired： true只清理缓存时间过期的图片，false清理全部缓存
- (void)clearDisk:(BOOL)onlyExpired completionCallBack:(void (^)())completion;
//清空内存缓存
- (void)clearMemory;

- (NSString *)cachePathForKey:(NSString *)key underFolder:(NSString *)rootFolder;

- (void)cacheSize:(void (^)(NSUInteger files, NSUInteger size))completion;
- (NSUInteger)diskCacheSize;
- (NSUInteger)diskCacheCount;

@end
