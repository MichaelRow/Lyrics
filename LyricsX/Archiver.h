//
//  Archiver.h
//
//  Created by Eru on 2017/6/30.
//  Copyright © 2017年 Eru. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Archiver : NSObject

/// 解压
+ (NSData *)uncompress: (NSData*)data;

/// 压缩
+ (NSData *)compress: (NSData*)data;

@end
