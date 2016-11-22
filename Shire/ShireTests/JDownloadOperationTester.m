//
//  JDownloadOperationTester.m
//  Shire
//
//  Created by jie on 2016/11/22.
//  Copyright © 2016年 huatengIOT. All rights reserved.
//

#import "JDownloadOperationTester.h"

@implementation JDownloadOperationTester

- (void)start {
    
    NSString *path = @"https://3hsyn13u3q9dhgyrg2qh3tin-wpengine.netdna-ssl.com/wp-content/uploads/2016/11/SplitShire-3841.jpg";
    
    JDownloadOperation *operation = [[JDownloadOperation alloc] initWithURL:path delegate:self];
    
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    
    queue.maxConcurrentOperationCount = 10;
    
    [queue addOperation:operation];
}


- (void)downloadOperation:(JDownloadOperation *)operation receivingData:(NSUInteger)packageSize expectData:(NSUInteger)totalSize {
    NSLog(@"<%@> receive: %lu total: %lu", NSStringFromSelector(_cmd), packageSize, totalSize);
}

- (void)downloadOperation:(JDownloadOperation *)operation updateProgress:(NSNumber *)progress {
    NSLog(@"<%@> progress: %f", NSStringFromSelector(_cmd), [progress doubleValue]);
}

- (void)downloadOperation:(JDownloadOperation *)operation didFinishWithData:(NSData *)data {
    NSLog(@"<%@> length : %lu", NSStringFromSelector(_cmd), [data length]);
}

- (void)downloadOperationDidFail:(JDownloadOperation *)operation {
    NSLog(@"<%@>", NSStringFromSelector(_cmd));
}

- (void)downloadOperationDidCancel:(JDownloadOperation *)operation {
    NSLog(@"<%@>", NSStringFromSelector(_cmd));
}
@end

