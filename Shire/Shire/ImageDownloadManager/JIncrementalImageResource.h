//
//  JDownloadResource.h
//  Shire
//
//  Created by jie on 2016/11/25.
//  Copyright © 2016年 huatengIOT. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface JIncrementalImageResource : NSObject

@property (readwrite) NSUInteger expectedSize;
@property (readwrite) UIImage *incrementalImage;

- (instancetype)initWithExpectedSize:(NSUInteger)size;

- (NSData *)incrementalData;

- (UIImage *)appendIncrementalData:(NSData *)data;

@end
