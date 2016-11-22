//
//  JDownloadOperation.m
//  Shire
//
//  Created by jie on 2016/11/21.
//  Copyright © 2016年 huatengIOT. All rights reserved.
//

#import "JDownloadOperation.h"

@interface JDownloadOperation ()

@property (nonatomic) uint16_t *configureFlag; // 暂时未使用 后续开关量和其他配置选项统一到这个字典中

@property (nonatomic, getter=isFinished) BOOL finished;
@property (nonatomic, getter=isExecuting) BOOL executing;

@end

@implementation JDownloadOperation
{
    void *kIsDispatchedOnQueue;
    dispatch_queue_t _serialQueue;
    __weak id<JDownloadOperationDelegate> _operationDelegate;
    NSString *_downloadPath;
    NSUInteger _expectedSize;
    NSMutableData *_receivedData;
    NSURLSession *_session;
    NSURLSessionTask *_dataTask;
    NSURLResponse *_response;
    NSURLRequest *_request;
    NSURLCredential *_credential;
}

@synthesize finished = _finished, executing = _executing;

- (instancetype)initWithURL:(NSString *)path delegate:(id<JDownloadOperationDelegate>)delegate
{
    self = [super init];
    if (self) {
        _downloadPath = path;
        _operationDelegate = delegate;
        
        _finished = NO;
        _executing = NO;
        _serialQueue = dispatch_queue_create("com.JDownloadOperation.serial.queue", NULL);

        /*
         * 这段代码学习自CocoaAsyncSocket GCDAsyncSocket.m 998
         * https://github.com/robbiehanson/CocoaAsyncSocket
         * 大神就是大神
         */
        kIsDispatchedOnQueue = &kIsDispatchedOnQueue;
        void *nonNullUnusedPointer = (__bridge void *)self;
        dispatch_queue_set_specific(_serialQueue, kIsDispatchedOnQueue, nonNullUnusedPointer, NULL);
    }
    return self;
}


/*
 * configuration
 */
- (void)setFinished:(BOOL)finished {
    dispatch_block_t block = ^{
        [self willChangeValueForKey:@"isFinished"];
        _finished = finished;
        [self didChangeValueForKey:@"isFinished"];
    };
    if (dispatch_get_specific(kIsDispatchedOnQueue)) {
        block();
    } else {
        dispatch_async(_serialQueue, block);
    }
}

- (void)setExecuting:(BOOL)executing {
    dispatch_block_t block = ^{
        [self willChangeValueForKey:@"isExecuting"];
        _executing = executing;
        [self didChangeValueForKey:@"isExecuting"];
    };
    if (dispatch_get_specific(kIsDispatchedOnQueue)) {
        block();
    } else {
        dispatch_async(_serialQueue, block);
    }
}

- (BOOL)isConcurrent {
    return YES;
}

- (BOOL)isAsynchronous {
    return YES;
}

- (NSString *)downloadPath {
    if (dispatch_get_specific(kIsDispatchedOnQueue)) {
        return _downloadPath;
    } else {
        __block NSString *path = [NSString string];
        dispatch_sync(_serialQueue, ^{
            path = _downloadPath;
        });
        return path;
    }
}
- (void)setDownloadPath:(NSString *)downloadPath {
    dispatch_block_t block = ^{
        _downloadPath = nil;
        _downloadPath = (NSString *)[downloadPath copy];
    };
    if (dispatch_get_specific(kIsDispatchedOnQueue)) {
        block();
    } else {
        dispatch_async(_serialQueue, block);
    }
}


- (id<JDownloadOperationDelegate>)operationDelegate {
    if (dispatch_get_specific(kIsDispatchedOnQueue)) {
        return _operationDelegate;
    } else {
        __block id<JDownloadOperationDelegate> delegate;
        dispatch_sync(_serialQueue, ^{
            delegate = _operationDelegate;
        });
        return delegate;
    }
}
- (void)setOperationDelegate:(id<JDownloadOperationDelegate>)operationDelegate {
    dispatch_block_t block = ^{
        _operationDelegate = operationDelegate;
    };
    if (dispatch_get_specific(kIsDispatchedOnQueue)) {
        block();
    } else {
        dispatch_sync(_serialQueue, block);
    }
}

- (NSURLSessionTask *)dataTask {
    if (dispatch_get_specific(kIsDispatchedOnQueue)) {
        return _dataTask;
    } else {
        __block NSURLSessionTask *task = nil;
        dispatch_sync(_serialQueue, ^{
            task = _dataTask;
        });
        return task;
    }
}
- (void)setDataTask:(NSURLSessionTask *)newTask {
    dispatch_block_t block = ^{
        _dataTask = newTask;
    };
    if (dispatch_get_specific(kIsDispatchedOnQueue)) {
        block();
    } else {
        dispatch_async(_serialQueue, block);
    }
}

- (NSURLSession *)session {
    if (dispatch_get_specific(kIsDispatchedOnQueue)) {
        return _session;
    } else {
        __block NSURLSession *s = nil;
        dispatch_sync(_serialQueue, ^{
            s = _session;
        });
        return s;
    }
}
- (void)setSession:(NSURLSession *)session {
    dispatch_block_t block = ^{
        _session = session;
    };
    if (dispatch_get_specific(kIsDispatchedOnQueue)) {
        block();
    } else {
        dispatch_async(_serialQueue, block);
    }
}

- (NSURLCredential *)credential {
    if (dispatch_get_specific(kIsDispatchedOnQueue)) {
        return _credential;
    } else {
        __block NSURLCredential *c = nil;
        dispatch_sync(_serialQueue, ^{
            c = _credential;
        });
        return c;
    }
}
- (void)setCredential:(NSURLCredential *)credential {
    dispatch_block_t block = ^{
        _credential = credential;
    };
    if (dispatch_get_specific(kIsDispatchedOnQueue)) {
        block();
    } else {
        dispatch_async(_serialQueue, block);
    }
}

- (NSUInteger)execeptedSize {
    if (dispatch_get_specific(kIsDispatchedOnQueue)) {
        return _expectedSize;
    } else {
        __block NSUInteger size = 0;
        dispatch_sync(_serialQueue, ^{
            size = _expectedSize;
        });
        return size;
    }
}

- (NSData *)receivedData {
    if (dispatch_get_specific(kIsDispatchedOnQueue)) {
        return _receivedData;
    } else {
        __block NSData *data = nil;
        dispatch_sync(_serialQueue, ^{
            data = (NSData *)[_receivedData copy];
        });
        return data;
    }
}

/*
 * override methods
 */

- (void)start { dispatch_sync(_serialQueue, ^{ @autoreleasepool{
    
    if (self.isCancelled || !_downloadPath) {
        self.finished = YES;
        self.executing = NO;
        
        if (_operationDelegate && [_operationDelegate respondsToSelector:@selector(downloadOperationDidCancel:)]) {
            [_operationDelegate downloadOperationDidCancel:self];
        }
        
        [self clear];
    } else {
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        NSURL *url = [NSURL URLWithString:_downloadPath];
        _request = [NSURLRequest requestWithURL:url];
        _session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
        _dataTask = [_session dataTaskWithRequest:_request];
        
        [_dataTask resume];
        
        self.finished = NO;
        self.executing = YES;
    }
    
}});}

- (void)cancel { dispatch_sync(_serialQueue, ^{
    [self abolish];
});}



/*
 * help method
 */

/*!
 * done
 * @discussion  Called when the task should finish
 */
- (void)done {
    dispatch_block_t block = ^{
        self.finished = YES;
        self.executing = NO;
        
        [self clear];
    };
    if (dispatch_get_specific(kIsDispatchedOnQueue)) {
        block();
    } else {
        dispatch_sync(_serialQueue, block);
    }
}

/*!
 * abolish  
 * @discussion  Gonna Cancel the task
 */
- (void)abolish {
    dispatch_block_t block = ^{
        if (self.finished) return;
        
        [super cancel];
        
        if (_operationDelegate && [_operationDelegate respondsToSelector:@selector(downloadOperationDidCancel:)]) {
            [_operationDelegate downloadOperationDidCancel:self];
        }
        
        if (_dataTask) {
            [_dataTask cancel];
        }
        
        self.executing = NO;
        self.finished = YES;
        
        [self clear];
    };
    if (dispatch_get_specific(kIsDispatchedOnQueue)) {
        block();
    } else {
        dispatch_sync(_serialQueue, block);
    }
}

/*!
 * callOff
 * @discussion  Called When Request Failed
 *              Responsible for proxy methods but not for updating flags (finished and executing)
 *              In general, @selector(done:) will be called next.
 */
- (void)callOff {
    dispatch_block_t block = ^{
        if (self.finished) return;
        
        if (_dataTask) {
            [_dataTask cancel];
        }
        
        if (_operationDelegate && [_operationDelegate respondsToSelector:@selector(downloadOperationDidCancel:)]) {
            [_operationDelegate downloadOperationDidCancel:self];
        }
    };
    if (dispatch_get_specific(kIsDispatchedOnQueue)) {
        block();
    } else {
        dispatch_sync(_serialQueue, block);
    }
}

/*!
 * clear
 * @discussion  This method will be responsible for clearing member data,
 *              and will not be responsible for updating flags(finished and executing)
 *              nor for responding to proxy methods.
 */
- (void)clear {
    dispatch_block_t block = ^{
        if (_session) {
            [_session invalidateAndCancel];
        }
        _receivedData = nil;
        _response = nil;
        _request = nil;
        _dataTask = nil;
        _session = nil;
        _operationDelegate = nil;
    };
    if (dispatch_get_specific(kIsDispatchedOnQueue)) {
        block();
    } else {
        dispatch_sync(_serialQueue, block);
    }
}


/*
 * @protocol NSURLSessionDataDelegate <NSURLSessionTaskDelegate>
 */

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    
    dispatch_block_t block = ^{
        
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        NSInteger responseCode = [httpResponse statusCode];
        /*
         * responseCode == 304  Remote image is not changed
         * responseCode < 400   Received response successfully
         * responseCode == other    Request failed
         */
        if (!httpResponse || (responseCode < 400 && responseCode != 304)) {
            
            _response = httpResponse;

            NSUInteger length = [httpResponse expectedContentLength] > 0 ? (NSUInteger)[httpResponse expectedContentLength] : 0;
            _expectedSize = length;
            _receivedData = [[NSMutableData alloc] initWithCapacity:length];
            if (_operationDelegate && [_operationDelegate respondsToSelector:@selector(downloadOperation:receivingData:expectData:)]) {
                [_operationDelegate downloadOperation:self receivingData:0 expectData:length];
            }
        } else {
            
            if (responseCode == 304) {
                [self abolish];
            } else {
                [self callOff];
            }
            
            [self done];
        }
    };
    if (dispatch_get_specific(kIsDispatchedOnQueue)) {
        block();
    } else {
        dispatch_sync(_serialQueue, block);
    }
    
    if (completionHandler) {
        completionHandler(NSURLSessionResponseAllow);
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    
    dispatch_block_t block = ^{
        [_receivedData appendData:data];
        
        if (_operationDelegate && [_operationDelegate respondsToSelector:@selector(downloadOperation:receivingData:expectData:)]) {
            [_operationDelegate downloadOperation:self receivingData:data.length expectData:_expectedSize];
        }
        
        if (_operationDelegate && [_operationDelegate respondsToSelector:@selector(downloadOperation:updateProgress:)]) {
            double progress = (double)_receivedData.length / (double)_expectedSize;
            [_operationDelegate downloadOperation:self updateProgress:[NSNumber numberWithDouble:progress]];
        }
    };
    if (dispatch_get_specific(kIsDispatchedOnQueue)) {
        block();
    } else {
        dispatch_sync(_serialQueue, block);
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask willCacheResponse:(NSCachedURLResponse *)proposedResponse completionHandler:(void (^)(NSCachedURLResponse * _Nullable))completionHandler {
    
    __block NSCachedURLResponse *cachedResponse = nil;
    dispatch_block_t block = ^{
        cachedResponse = proposedResponse;
        if (_request.cachePolicy == NSURLRequestReloadIgnoringLocalCacheData) {
            cachedResponse = nil;
        }
    };
    if (dispatch_get_specific(kIsDispatchedOnQueue)) {
        block();
    } else {
        dispatch_sync(_serialQueue, block);
    }
    if (completionHandler) {
        completionHandler(cachedResponse);
    }
}


/*
 * @protocol NSURLSessionTaskDelegate <NSURLSessionDelegate>
 */

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    
    dispatch_block_t block = ^{
        _dataTask = nil;
        
        if (error) {
            if (_operationDelegate && [_operationDelegate respondsToSelector:@selector(downloadOperationDidFail:)]) {
                [_operationDelegate downloadOperationDidFail:self];
            }
        } else {
            if (_operationDelegate && [_operationDelegate respondsToSelector:@selector(downloadOperation:didFinishWithData:)]) {
                [_operationDelegate downloadOperation:self didFinishWithData:_receivedData];
            }
        }
        
        [self done];
    };
    if (dispatch_get_specific(kIsDispatchedOnQueue)) {
        block();
    } else {
        dispatch_sync(_serialQueue, block);
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler {
    
    __block NSURLSessionAuthChallengeDisposition disposition;
    __block NSURLCredential *credential = nil;
    
    dispatch_block_t block = ^{
        disposition = NSURLSessionAuthChallengePerformDefaultHandling;
        
        if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
            
            BOOL testing = NO;
            if (testing) {
                credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
                disposition = NSURLSessionAuthChallengeUseCredential;
            } else {
                disposition = NSURLSessionAuthChallengePerformDefaultHandling;
            }
            
        } else {
            
            if (challenge.previousFailureCount == 0 && _credential) {
                credential = _credential;
                disposition = NSURLSessionAuthChallengeUseCredential;
            } else {
                disposition = NSURLSessionAuthChallengeCancelAuthenticationChallenge;
            }
            
        }
    };
    if (dispatch_get_specific(kIsDispatchedOnQueue)) {
        block();
    } else {
        dispatch_sync(_serialQueue, block);
    }
    
    if (completionHandler) {
        completionHandler(disposition, credential);
    }
}

@end
