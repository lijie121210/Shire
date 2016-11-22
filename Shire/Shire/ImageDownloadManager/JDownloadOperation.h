//
//  JDownloadOperation.h
//  Shire
//
//  Created by jie on 2016/11/21.
//  Copyright © 2016年 huatengIOT. All rights reserved.
//

#import <Foundation/Foundation.h>

@class JDownloadOperation;

@protocol JDownloadOperationDelegate <NSObject>

@optional
- (void)downloadOperationDidCancel:(JDownloadOperation * _Nullable)operation;

- (void)downloadOperation:(JDownloadOperation * _Nullable)operation didFinishWithData:(NSData * _Nullable)data;

- (void)downloadOperationDidFail:(JDownloadOperation * _Nullable)operation;

- (void)downloadOperation:(JDownloadOperation * _Nullable)operation receivingData:(NSUInteger)packageSize expectData:(NSUInteger)totalSize;

- (void)downloadOperation:(JDownloadOperation * _Nullable)operation updateProgress:(NSNumber * _Nullable)progress ;

@end

@interface JDownloadOperation : NSOperation <NSURLSessionTaskDelegate, NSURLSessionDataDelegate>

@property (nullable, readwrite, weak) id<JDownloadOperationDelegate> operationDelegate;

@property (nullable, readwrite, copy) NSString *downloadPath;

@property (nullable, readonly, strong) NSData *receivedData;

@property (nullable, readwrite, strong) NSURLCredential *credential;

@property (readonly) NSUInteger execeptedSize;

- (nullable instancetype)initWithURL:(nullable NSString *)path delegate:(nullable id<JDownloadOperationDelegate>)delegate;

@end
