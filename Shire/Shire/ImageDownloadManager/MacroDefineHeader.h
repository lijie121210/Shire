//
//  MacroDefineHeader.h
//  Shire
//
//  Created by jie on 16/9/25.
//  Copyright © 2016年 huatengIOT. All rights reserved.
//

#ifndef MacroDefineHeader_h
#define MacroDefineHeader_h

@class UIImage;
typedef void(^JDProgressBlock)(NSInteger expected, NSInteger received);
typedef void(^JDCompleteBlock)(BOOL finished, UIImage *image, NSData *data, NSError *error);
typedef void(^JDCancelBlock)();



#endif /* MacroDefineHeader_h */
