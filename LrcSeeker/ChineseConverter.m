//
//  ChineseConverter.m
//  LrcSeeker
//
//  Created by Eru on 15/11/21.
//  Copyright © 2015年 Eru. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ChineseConverter.h"

NSString* convertToChineseUsingProfile (NSString* profile, NSString* inputStr) {
    opencc_t cc = opencc_open(profile.UTF8String);
    const char* cInput = inputStr.UTF8String;
    char *cOutput = opencc_convert_utf8(cc, cInput, strlen(cInput));
    NSString *outputStr = [NSString stringWithUTF8String:cOutput];
    opencc_convert_utf8_free(cOutput);
    opencc_close(cc);
    return outputStr;
}

NSString* convertToSC (NSString* input) {
    NSString *profilePath=[[NSBundle mainBundle] pathForResource:@"t2s" ofType:@"json"];
    return convertToChineseUsingProfile(profilePath, input);
}

NSString* convertToTC (NSString* input) {
    NSString *profilePath=[[NSBundle mainBundle] pathForResource:@"s2t" ofType:@"json"];
    return convertToChineseUsingProfile(profilePath, input);
}

NSString* convertToTCTW (NSString* input) {
    NSString *profilePath=[[NSBundle mainBundle] pathForResource:@"s2tw" ofType:@"json"];
    return convertToChineseUsingProfile(profilePath, input);
}

NSString* convertToTCHK (NSString* input) {
    NSString *profilePath=[[NSBundle mainBundle] pathForResource:@"s2hk" ofType:@"json"];
    return convertToChineseUsingProfile(profilePath, input);
}