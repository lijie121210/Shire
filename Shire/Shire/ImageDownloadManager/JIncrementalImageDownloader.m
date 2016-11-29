//
//  JIncrementalImageDownloader.m
//  Shire
//
//  Created by jie on 2016/11/23.
//  Copyright © 2016年 huatengIOT. All rights reserved.
//
// readme :暂时忽略线程安全

#import "JIncrementalImageDownloader.h"
#import "JOperationNode.h"
#import <ImageIO/ImageIO.h>
#import <UIKit/UIKit.h>

@implementation JIncrementalImageDownloader
{
    NSOperationQueue *_sharedQueue;
    NSMutableDictionary *_sharedTasks;
    NSMutableDictionary *_sharedResource;
}

+ (JIncrementalImageDownloader *)sharedDownloader {
    static JIncrementalImageDownloader *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[JIncrementalImageDownloader alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _sharedQueue = [[NSOperationQueue alloc] init];
        _sharedQueue.maxConcurrentOperationCount = 8;
        _sharedTasks = [NSMutableDictionary dictionary];
        _sharedResource = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)dealloc {
    
}

- (void)downloadWithURL:(NSString *)path inContext:(id)context {
    if (!path) {
        return;
    }
    if ([[_sharedTasks allKeys] containsObject:path]) {
        JOperationNode *existedNode = (JOperationNode *)[_sharedTasks objectForKey:path];
        
        if (![existedNode isFinishedSuccessfully]) {
            [_sharedTasks removeObjectForKey:path];
            JOperationNode *newNode = [existedNode refreshContexts:context];
            [_sharedTasks setObject:newNode forKey:path];
        } else {
            JIncrementalImageResource *existedResource = [_sharedResource objectForKey:path];
            [existedNode updateContext:context withResource:[existedResource incrementalImage]];
        }
    } else {
        JDownloadOperation *taskOpertion = [[JDownloadOperation alloc] initWithURL:path delegate:self];
        JOperationNode *operationNode = [[JOperationNode alloc] initWithOperation:taskOpertion andContext:context];
        [operationNode setFinishedSuccessfully:NO];
        [_sharedTasks setObject:operationNode forKey:path];
        [_sharedQueue addOperation:taskOpertion];
    }
}


/*
 * JDownloadOperationDelegate
 */

- (void)downloadOperation:(JDownloadOperation *)operation receivedSize:(NSUInteger)packageSize expectSize:(NSUInteger)totalSize {
    NSString *path = operation.name;
    if (!path || packageSize > 0) {
        return;
    }
    JIncrementalImageResource *resource = [[JIncrementalImageResource alloc] initWithExpectedSize:packageSize];
    [_sharedResource setObject:resource forKey:path];
}

- (void)downloadOperation:(JDownloadOperation *)operation receivedData:(NSData *)data {
    NSString *path = operation.name;
    if (!path || !data) {
        return;
    }
    JOperationNode *node = [_sharedTasks objectForKey:path];
    JIncrementalImageResource *resource = [_sharedResource objectForKey:path];
    [_sharedResource removeObjectForKey:path];
    UIImage *tmp = [resource appendIncrementalData:data];
    if (tmp) {
        [node updateContextsWithResource:tmp];
    }
    [_sharedResource setObject:resource forKey:path];
}

- (void)downloadOperation:(JDownloadOperation *)operation didFinishWithData:(NSData *)data {
    NSString *path = operation.name;
    if (!path || !data) {
        return;
    }
    JOperationNode *node = [_sharedTasks objectForKey:path];
    [_sharedTasks removeObjectForKey:path];
    [node setFinishedSuccessfully:YES];
    [_sharedTasks setObject:node forKey:path];
}

@end
