//
//  UIImageView+DownloadImage.h
//  Shire
//
//  Created by jie on 2016/11/23.
//  Copyright © 2016年 huatengIOT. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JUpdatableOperationContext.h"

@interface UIImageView (DownloadImage) <JUpdatableOperationContext>

- (void)setImageWithURL:(NSString *)path placeholdImage:(NSString *)name;

@end
