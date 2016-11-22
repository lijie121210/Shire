//
//  TestObjc.m
//  Shire
//
//  Created by jie on 2016/11/21.
//  Copyright © 2016年 huatengIOT. All rights reserved.
//

#import "TestObjc.h"

@implementation TestObjc
{
    dispatch_queue_t queue;
}
- (instancetype)init {
    self = [super init];
    if (self) {
        self.count = 0;
        queue = dispatch_queue_create("com.test.queue.con", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void)updateCount {
    @synchronized (self) {
        @synchronized (self) {
//            NSLog(@"two @synchronized");
            
            NSUInteger c = self.count;
            
            self.count = c + 1;
        }
        
    }
    
    
    
//    dispatch_sync(queue, ^{
    
    //    dispatch_sync(queue, ^{

//        NSUInteger c = self.count;
//        
//        self.count = c + 1;
//    });
}

@end
