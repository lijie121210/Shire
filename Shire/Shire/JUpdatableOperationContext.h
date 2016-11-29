//
//  JUpdatableOperationContext.h
//  Shire
//
//  Created by jie on 2016/11/24.
//  Copyright © 2016年 huatengIOT. All rights reserved.
//

//#import <Foundation/Foundation.h>

@protocol JUpdatableOperationContext <NSObject>

@required
- (void)updateOperationContextWithResource:(id)resource;

@end
