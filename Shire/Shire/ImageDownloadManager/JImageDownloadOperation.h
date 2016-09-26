//
//  JImageDownloadOperation.h
//  Shire
//
//  Created by jie on 16/9/25.
//  Copyright © 2016年 huatengIOT. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MacroDefineHeader.h"

@interface JImageDownloadOperation : NSOperation

@property (readonly, nonatomic, strong) NSURLRequest *request;
@property (readonly, nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSURLResponse *response; // NSHTTPURLResponse ?? nil
@property (nonatomic, assign) NSUInteger expectedSize;

- (instancetype)initWithRequest:(NSURLRequest *)request session:(NSURLSession *)session progressBlock:(JDProgressBlock)progressBlock completeBlock:(JDCompleteBlock)completeBlock cancelBlock:(JDCancelBlock)cancelBlock;


@end
