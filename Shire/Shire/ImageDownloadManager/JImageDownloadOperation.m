//
//  JImageDownloadOperation.m
//  Shire
//
//  Created by jie on 16/9/25.
//  Copyright © 2016年 huatengIOT. All rights reserved.
//

#import "JImageDownloadOperation.h"
#import <UIKit/UIKit.h>
#import <ImageIO/ImageIO.h>

NSString *const JDStartNotificationKey = @"JDStartNotificationKey";
NSString *const JDStopNotificationKey = @"JDStopNotificationKey";
NSString *const JDFinishNotificationKey = @"JDFinishNotificationKey";
NSString *const JDReceiveResponseNotificationKey = @"JDReceiveResponseNotificationKey";


@interface JImageDownloadOperation () <NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDataDelegate>

@property (nonatomic, copy) JDProgressBlock progressBlock;
@property (nonatomic, copy) JDCompleteBlock completeBlock;
@property (nonatomic, copy) JDCancelBlock cancelBlock;

@property (nonatomic, weak) NSURLSession *unownSession;
@property (nonatomic, strong) NSURLSession *ownSession;
@property (nonatomic, strong) NSURLSessionTask *dataTask;

@property (nonatomic, strong) NSMutableData *imageData;
@property (nonatomic, assign) CGImageSourceRef increamentallyImageSource;

@property (atomic, strong) NSThread *thread;

@property (nonatomic, assign) UIBackgroundTaskIdentifier backgroundTaskID;


@end

@implementation JImageDownloadOperation
{
    UIImageOrientation orien;
    BOOL isResponseCached;
}

@synthesize finished = _finished;
@synthesize executing = _execting;
@synthesize cancelled = _cancelled;

#pragma init

- (void)deinit {
    NSLog(@"deinit JImageDownloadOperation %@", self);
    [self reset];
}

- (void)dealloc {
    NSLog(@"dealloc JImageDownloadOperation %@", self);
    [self reset];
}

- (instancetype)initWithRequest:(NSURLRequest *)request session:(NSURLSession *)session progressBlock:(JDProgressBlock)progressBlock completeBlock:(JDCompleteBlock)completeBlock cancelBlock:(JDCancelBlock)cancelBlock
{
    self = [super init];
    if (self) {
        _progressBlock = [progressBlock copy];
        _completeBlock = [completeBlock copy];
        _cancelBlock = [cancelBlock copy];
        _request = [request copy];
        _unownSession = session;
        _expectedSize = 0;
        _finished = NO;
        _execting = NO;
        _increamentallyImageSource = CGImageSourceCreateIncremental(NULL);
    }
    return self;
}
// keyPath should be : @"finished" and @"execting"
- (void)enableFinish_KVOSetter:(BOOL)value {
    [self willChangeValueForKey:@"finished"];
    _finished = value;
    [self didChangeValueForKey:@"finished"];
}
- (void)enableExecuting_KVOSetter:(BOOL)value {
    [self willChangeValueForKey:@"execting"];
    _execting = value;
    [self didChangeValueForKey:@"execting"];
}
//@override
- (BOOL)isAsynchronous {
    return YES;
}

#pragma methon

//@override
- (void)start {
    @synchronized (self) {
        if (_cancelled) {
            [self enableFinish_KVOSetter:YES];
            [self reset];
            return;
        }
        NSURLSession *session = _unownSession;
        if (!session) {
            NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
            _ownSession = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
            session = _ownSession;
        }
        _dataTask = [session dataTaskWithRequest:_request];
        
        _thread = [NSThread currentThread];
        
        [self enableExecuting_KVOSetter:YES];
    }
    
    [_dataTask resume];
    
    if (_dataTask) {
        if (_progressBlock) {
            _progressBlock(0, NSURLResponseUnknownLength);
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:JDStartNotificationKey object:self];
        });
    } else {
        if (_completeBlock) {
            NSDictionary *reason = [NSDictionary dictionaryWithObjectsAndKeys:@"Can't start image data task!",NSLocalizedDescriptionKey, nil];
            NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:0 userInfo:reason];
            _completeBlock(YES, nil, nil, error);
        }
    }
}

- (void)done {
    [self enableFinish_KVOSetter:YES];
    [self enableExecuting_KVOSetter:NO];
    [self reset];
}

//@override
- (void)cancel {
    @synchronized (self) {
        if (_thread) {
            [self performSelector:@selector(cancelAndClear) onThread:_thread withObject:nil waitUntilDone:NO];
        } else {
            [self cancelAndClear];
        }
    }
}
- (void)cancelAndClear {
    if (_finished) {
        return;
    }
    
    [super cancel];
    
    if (_cancelBlock) {
        _cancelBlock();
    }
    
    if (_dataTask) {
        [_dataTask cancel];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:JDStopNotificationKey object:self];
        });
        
        if (_execting) {
            [self enableExecuting_KVOSetter:NO];
        }
        if (!_finished) {
            [self enableFinish_KVOSetter:YES];
        }
    }
    
    [self reset];
}
- (void)reset {
    if (_increamentallyImageSource) {
        CFRelease(_increamentallyImageSource);
        _increamentallyImageSource = NULL;
    }
    _progressBlock = nil;
    _completeBlock = nil;
    _cancelBlock = nil;
    _dataTask = nil;
    _imageData = nil;
    _thread = nil;
    if (_ownSession) {
        [_ownSession invalidateAndCancel];
        _ownSession = nil;
    }
}

#pragma NSURLSessionTaskDelegate

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    // 正常读取到statuscode，我们就可以取到图片长度信息，否则执行结束和清理的操作
    if (!httpResponse || ([httpResponse statusCode] < 400 && [httpResponse statusCode] != 304)) {
        _expectedSize = [httpResponse expectedContentLength] > 0 ? [httpResponse expectedContentLength] : 0;
        
        if (_progressBlock) {
            _progressBlock(0, _expectedSize);
        }
        _imageData = [[NSMutableData alloc] initWithCapacity:_expectedSize];
        
        _response = httpResponse;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:JDReceiveResponseNotificationKey object:self];
        });
    } else {
        NSUInteger code = httpResponse ? [httpResponse statusCode] : 9999;
        if (code == 304) {
            [self cancelAndClear];
        } else {
            [_dataTask cancel];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:JDStopNotificationKey object:self];
        });
        if (_completeBlock) {
            _completeBlock(YES, nil, nil, [NSError errorWithDomain:NSURLErrorDomain code:code userInfo:nil]);
        }
        [self done];
    }
    if (completionHandler) {
        completionHandler(NSURLSessionResponseAllow);
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    [_imageData appendData:data];
    
    CGImageSourceUpdateData(_increamentallyImageSource, (__bridge CFDataRef)_imageData, _imageData.length == _expectedSize);
    
    CGImageRef imageRef = CGImageSourceCreateImageAtIndex(_increamentallyImageSource, 0, NULL);
    
    UIImage *image = [UIImage imageWithCGImage:imageRef];
    
    if (_completeBlock) {
        _completeBlock(NO, image, nil, nil); // 实时回传图片 didCompleteWithError被调用时才是结束
    }
    CGImageRelease(imageRef);
    
    if (_progressBlock) {
        _progressBlock(_imageData.length, _expectedSize); // 实时更新进度
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask willCacheResponse:(NSCachedURLResponse *)proposedResponse completionHandler:(void (^)(NSCachedURLResponse * _Nullable))completionHandler {
    
    isResponseCached = NO;
    
    NSCachedURLResponse *cachedResponse = proposedResponse;
    if ([_request cachePolicy] == NSURLRequestReloadIgnoringLocalCacheData) {
        cachedResponse = nil;
    }
    if (completionHandler) {
        completionHandler(cachedResponse);
    }
}

#pragma NSURLSessionTaskDelegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    @synchronized (self) {
        _thread = nil;
        _dataTask = nil;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:JDFinishNotificationKey object:self];
        });
    }
    if (error) {
        if (_completeBlock) _completeBlock(YES, nil, nil, error);
    } else {
        JDCompleteBlock block = _completeBlock;
        if (block) {
            NSCachedURLResponse *cachedResponse = [[NSURLCache sharedURLCache] cachedResponseForRequest:_request];
            if (isResponseCached && cachedResponse) {
                _completeBlock(YES, nil, nil, nil);
            } else if (_imageData) {
                UIImage *image = [UIImage imageWithData:_imageData];
                if (CGSizeEqualToSize([image size], CGSizeZero)) {
                    NSDictionary *reason = [NSDictionary dictionaryWithObjectsAndKeys:@"image data 0 pixel!",NSLocalizedDescriptionKey, nil];
                    NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:0 userInfo:reason];
                    _completeBlock(YES, nil, nil, error);
                } else {
                    _completeBlock(YES, image, _imageData, nil);
                }
            } else {
                NSDictionary *reason = [NSDictionary dictionaryWithObjectsAndKeys:@"image data nil!",NSLocalizedDescriptionKey, nil];
                NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:0 userInfo:reason];
                _completeBlock(YES, nil, nil, error);
            }
        }
    }
    _completeBlock = nil;
    
    [self done];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler {
    
}

@end
