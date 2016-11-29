//
//  JDownloadResource.m
//  Shire
//
//  Created by jie on 2016/11/25.
//  Copyright © 2016年 huatengIOT. All rights reserved.
//

#import "JIncrementalImageResource.h"
#import <ImageIO/ImageIO.h>
#import "JOperationNode.h"

@implementation JIncrementalImageResource
{
    NSUInteger _expectedSize;
    NSMutableData *_incrementalData;
    UIImage *_incrementalImage;
    CGImageSourceRef _increamentallyImageSource;
}

- (instancetype)init {
    if (self = [super init]) {
        
    }
    return self;
}

- (instancetype)initWithExpectedSize:(NSUInteger)size {
    if (self = [super init]) {
        _expectedSize = size;
        _incrementalData = [NSMutableData dataWithCapacity:size];
        _increamentallyImageSource = CGImageSourceCreateIncremental(NULL);
    }
    return self;
}


- (NSUInteger)expectedSize {
    @synchronized (self) {
        return _expectedSize;
    }
}

- (void)setExpectedSize:(NSUInteger)expectedSize {
    @synchronized (self) {
        _expectedSize = expectedSize;
    }
}

- (UIImage *)incrementalImage {
    return _incrementalImage;
}

- (void)setIncrementalImage:(UIImage *)incrementalImage {
    @synchronized (self) {
        _incrementalImage = incrementalImage;
    }
}

- (NSData *)incrementalData {
    @synchronized (self) {
        return (NSData *)[_incrementalData copy];
    }
}


- (UIImage *)appendIncrementalData:(NSData *)data {
    @synchronized (self) {
        if (data) {
            [_incrementalData appendData:data];
            
            CGImageSourceUpdateData(_increamentallyImageSource, (__bridge CFDataRef)_incrementalData, _incrementalData.length == _expectedSize);
            
            CGImageRef imageRef = CGImageSourceCreateImageAtIndex(_increamentallyImageSource, 0, NULL);
            
            _incrementalImage = [UIImage imageWithCGImage:imageRef];
            
            CGImageRelease(imageRef);
            
            return _incrementalImage;
        } else {
            return nil;
        }
    }
}

- (void)updateOperation:(id)operation {
    
}

@end
