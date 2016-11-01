//
//  JImageDownloadOperation.m
//  Shire
//
//  Created by jie on 16/9/25.
//  Copyright © 2016年 huatengIOT. All rights reserved.
//

#import "JImageDownloadOperation.h"
#import <ImageIO/ImageIO.h>

NSString *const JDStartNotificationKey = @"JDStartNotificationKey";
NSString *const JDStopNotificationKey = @"JDStopNotificationKey";
NSString *const JDFinishNotificationKey = @"JDFinishNotificationKey";
NSString *const JDReceiveResponseNotificationKey = @"JDReceiveResponseNotificationKey";

@interface JImageDownloadOperation () 

@property (nonatomic, copy) JDProgressBlock progressBlock;
@property (nonatomic, copy) JDCompleteBlock completeBlock;
@property (nonatomic, copy) JDCancelBlock cancelBlock;

@property (nonatomic, weak) NSURLSession *unownSession;
@property (nonatomic, strong) NSURLSession *ownSession;
//@property (nonatomic, strong) NSURLSessionTask *dataTask;

@property (atomic, strong) NSThread *thread;
@property (nonatomic, assign) UIBackgroundTaskIdentifier backgroundTaskID;

@property (nonatomic, strong) NSMutableData *imageData;
@property (nonatomic, assign) CGImageSourceRef increamentallyImageSource;

@end

@implementation JImageDownloadOperation

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

//@override
- (BOOL)isAsynchronous {
    return YES;
}

#pragma methon

//@override
/* 
 初始化_dataTask，并且启动之。启动失败则 完成回调函数 会被调用；
 多线程条件下，防止初始化多次，需要@synchronized同步；
 更新finished和executing状态时，暂时不考虑kvo；
*/
- (void)start {
    @synchronized (self) {
        if (_cancelled) {
            _finished = YES;
            
            [self reset];
            
            return;
        }
        
        // 暂时借鉴，学习后需要重写，避免使用多个session
        NSURLSession *session = _unownSession;
        if (!session) {
            NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
            _ownSession = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
            session = _ownSession;
        }
        _dataTask = [session dataTaskWithRequest:_request];
        
        _thread = [NSThread currentThread];
        
        _execting = YES;
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
            _completeBlock(YES, nil, nil, [NSError errorWithDomain:NSURLErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey:@"Can't start image data task!"}]);
        }
    }
}

//@override
/*
 取消操作应该在初始化实例的线程中完成
 */
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
            _execting = NO;
        }
        
        if (!_finished) {
            _finished = YES;
        }
    }
    
    [self reset];
}

- (void)done {
    _finished = YES;
    _execting = NO;
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

#pragma NSURLSessionDataDelegate

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
        self.thread = nil;
        self.dataTask = nil;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:JDStopNotificationKey object:self];
            
            if (!error) {
                [[NSNotificationCenter defaultCenter] postNotificationName:JDFinishNotificationKey object:self];
            }
            
        });
    }
    
    if (error) {
        
        if (_completeBlock) _completeBlock(YES, nil, nil, error);
        
    } else {
        JDCompleteBlock block = _completeBlock;
        
        if (block) {
            NSCachedURLResponse *cachedResponse = [[NSURLCache sharedURLCache] cachedResponseForRequest:self.request];
            
            if (isResponseCached && cachedResponse) {
                _completeBlock(YES, nil, nil, nil);
            } else if (_imageData) {
                UIImage *image = [UIImage imageWithData:_imageData];
                
                if (CGSizeEqualToSize([image size], CGSizeZero)) {
                    _completeBlock(YES, nil, nil, [NSError errorWithDomain:NSURLErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey:@"image data 0 pixel!"}]);
                } else {
                    _completeBlock(YES, image, _imageData, nil);
                }
            } else {
                _completeBlock(YES, nil, nil, [NSError errorWithDomain:NSURLErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey:@"image data nil!"}]);
            }
        } // if (block)
    }
    _completeBlock = nil;
    
    [self done];
}

// 关于如何处理认证，还需要学习之后重写
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler {
    
    NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengePerformDefaultHandling;
    
    __block NSURLCredential *credential = nil;
    
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        
        BOOL testing = NO;
        if (testing) {
            credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
            disposition = NSURLSessionAuthChallengeUseCredential;
        } else {
            disposition = NSURLSessionAuthChallengePerformDefaultHandling;
        }
        
    } else {
        
        if (challenge.previousFailureCount == 0 && self.credential) {
            credential = self.credential;
            disposition = NSURLSessionAuthChallengeUseCredential;
        } else {
            disposition = NSURLSessionAuthChallengeCancelAuthenticationChallenge;
        }
        
    }
    
    if (completionHandler) {
        completionHandler(disposition, credential);
    }
}

@end
