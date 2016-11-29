//
//  JIncrementalImageDownloader.h
//  Shire
//
//  Created by jie on 2016/11/23.
//  Copyright © 2016年 huatengIOT. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JDownloadOperation.h"

@interface JIncrementalImageDownloader : NSObject <JDownloadOperationDelegate>

+ (JIncrementalImageDownloader *)sharedDownloader;

- (void)downloadWithURL:(NSString *)path inContext:(id)context;

@end
