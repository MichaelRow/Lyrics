//
//  QianqianDecrypt.h
//  LyricsX
//
//  Created by Eru on 2017/7/1.
//  Copyright © 2017年 Eru. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface QianqianDecrypt : NSObject

/**
 将字符串转为16进制
 */
+ (NSString *)hexEncodedString:(NSString *) originalStr;

/**
 获取访问码
 */
+ (NSString *)accessCodeWithArtist:(NSString *)artist title:(NSString *)title songID:(NSInteger)songID;

@end
