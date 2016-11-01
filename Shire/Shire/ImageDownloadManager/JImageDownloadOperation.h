//
//  JImageDownloadOperation.h
//  Shire
//
//  Created by jie on 16/9/25.
//  Copyright © 2016年 huatengIOT. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "MacroDefineHeader.h"


extern NSString *const JDStartNotificationKey;
extern NSString *const JDStopNotificationKey;
extern NSString *const JDFinishNotificationKey;
extern NSString *const JDReceiveResponseNotificationKey;


typedef void(^JDProgressBlock)(NSInteger expected, NSInteger received);
typedef void(^JDCompleteBlock)(BOOL finished, UIImage *image, NSData *data, NSError *error);
typedef void(^JDCancelBlock)();


@interface JImageDownloadOperation : NSOperation <NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDataDelegate>
{
    UIImageOrientation orien;
    
    BOOL isResponseCached;
}
// override can't work with kvo!
@property (nonatomic, assign, readonly, getter=isFinished) BOOL finished;
@property (nonatomic, assign, readonly, getter=isExecuting) BOOL executing;
@property (nonatomic, assign, readonly, getter=isCancelled) BOOL cancelled;

@property (nonatomic, copy) NSDictionary *configurations; // 暂时未使用 后续开关量和其他配置选项统一到这个字典中

@property (nonatomic, strong) NSURLRequest *request; // request of private session
@property (nonatomic, strong) NSURLCredential *credential; // credential of private session
@property (nonatomic, strong) NSURLSessionTask *dataTask; // work task of private session
@property (nonatomic, strong, readonly) NSURLResponse *response; // NSHTTPURLResponse instance or nil
@property (nonatomic, assign, readonly) NSUInteger expectedSize; // size of an image expected to receive

- (instancetype)initWithRequest:(NSURLRequest *)request session:(NSURLSession *)session progressBlock:(JDProgressBlock)progressBlock completeBlock:(JDCompleteBlock)completeBlock cancelBlock:(JDCancelBlock)cancelBlock;

@end
