//
//  UIImageView+DownloadImage.m
//  Shire
//
//  Created by jie on 2016/11/23.
//  Copyright © 2016年 huatengIOT. All rights reserved.
//

#import "UIImageView+DownloadImage.h"
#import "JIncrementalImageDownloader.h"


@implementation UIImageView (DownloadImage)

- (void)setImageWithURL:(NSString *)path placeholdImage:(NSString *)name {
    
    if (path) {
        [[JIncrementalImageDownloader sharedDownloader] downloadWithURL:path inContext:self];
    }
    
}

- (void)updateOperationContextWithResource:(id)resource {
    if (resource && [resource isKindOfClass:[UIImage class]]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setImage:resource];
            [self setNeedsLayout];
        });
    }
}

@end
