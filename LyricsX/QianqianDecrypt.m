//
//  QianqianDecrypt.m
//  LyricsX
//
//  Created by Eru on 2017/7/1.
//  Copyright © 2017年 Eru. All rights reserved.
//

#import "QianqianDecrypt.h"

@implementation QianqianDecrypt

+ (NSString *)hexEncodedString:(NSString *) originalStr {
    const char *s = [originalStr cStringUsingEncoding:NSUnicodeStringEncoding];
    NSMutableString *result = [NSMutableString string];
    
    if(!s) { return nil; }
    int j = 0;
    int n= (int)[originalStr lengthOfBytesUsingEncoding:NSUnicodeStringEncoding];
    for(int i=0; i<n; i++) {
        unsigned ord=(unsigned)s[i];
        if (j+2>1022) {
            return NULL;
        }
        
        [result appendFormat:@"%c%c",singleDecToHex((ord-ord%16)/16),singleDecToHex(ord%16)];
    }
    return result;
}

+ (NSString *)accessCodeWithArtist:(NSString *)artist title:(NSString *)title songID:(NSInteger)songID {
    const char *bytes=[[artist stringByAppendingString:title] cStringUsingEncoding:NSUTF8StringEncoding];
    long len= strlen(bytes);
    int *song = (int*)malloc(sizeof(int)*len);
    for (int i = 0; i < len; i++) {
        song[i] = bytes[i] & 0xff;
    }
    
    long intVal1 = 0, intVal2 = 0, intVal3 = 0;
    intVal1 = (songID & 0x0000FF00) >> 8;
    if ((songID & 0xFF0000) == 0) {
        intVal3 = 0xFF & ~intVal1;
    } else {
        intVal3 = 0xFF & ((songID & 0x00FF0000) >> 16);
    }
    intVal3 = intVal3 | ((0xFF & songID) << 8);
    intVal3 = intVal3 << 8;
    intVal3 = intVal3 | (0xFF & intVal1);
    intVal3 = intVal3 << 8;
    if ((songID & 0xFF000000) == 0) {
        intVal3 = intVal3 | (0xFF & (~songID));
    } else {
        intVal3 = intVal3 | (0xFF & (songID >> 24));
    }
    long uBound = len - 1;
    while (uBound >= 0) {
        int c = song[uBound];
        if (c >= 0x80) {
            c = c - 0x100;
        }
        intVal1 = (c + intVal2) & 0x00000000FFFFFFFF;
        intVal2 = (intVal2 << (uBound % 2 + 4)) & 0x00000000FFFFFFFF;
        intVal2 = (intVal1 + intVal2) & 0x00000000FFFFFFFF;
        uBound -= 1;
    }
    uBound = 0;
    intVal1 = 0;
    while (uBound <= len - 1) {
        long c = song[uBound];
        if (c >= 128) {
            c = c - 256;
        }
        long intVal4 = (c + intVal1) & 0x00000000FFFFFFFF;
        intVal1 = (intVal1 << (uBound % 2 + 3)) & 0x00000000FFFFFFFF;
        intVal1 = (intVal1 + intVal4) & 0x00000000FFFFFFFF;
        uBound += 1;
    }
    long intVal5 = conv(intVal2 ^ intVal3);
    intVal5 = conv(intVal5 + (intVal1 | songID));
    intVal5 = conv(intVal5 * (intVal1 | intVal3));
    intVal5 = conv(intVal5 * (intVal2 ^ songID));
    
    long intVal6 = intVal5;
    if (intVal6 > 0x80000000) intVal5 = intVal6 - 0x100000000;
    
    free(song);
    
    return [NSString stringWithFormat:@"%ld",intVal5];
}

#pragma mark - Private

FOUNDATION_STATIC_INLINE char singleDecToHex(int dec) {
    dec = dec % 16;
    if(dec < 10) {
        return (char)(dec+'0');
    }
    char arr[6]={'A','B','C','D','E','F'};
    return arr[dec-10];
}

FOUNDATION_STATIC_INLINE long conv(long i) {
    long r = i % 0x100000000;
    if (i >= 0 && r > 0x80000000) {
        r = r - 0x100000000;
    }
    
    if (i < 0 && r < 0x80000000) {
        r = r + 0x100000000;
    }
    return r;
}

@end
