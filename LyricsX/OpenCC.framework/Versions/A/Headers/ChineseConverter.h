//
//  ChineseConverter.h
//  LyricsX
//
//  Created by Eru on 2017/4/17.
//  Copyright © 2017年 Eru. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ChineseConverter : NSObject

+ (NSString *)convertStringToSC:(NSString *)str;

+ (NSString *)convertStringToTC:(NSString *)str;

+ (NSString *)convertStringToTC_TW:(NSString *)str;

+ (NSString *)convertStringToTC_HK:(NSString *)str;

+ (NSString *)convertString:(NSString *)str profile:(NSString *)profile;

@end
