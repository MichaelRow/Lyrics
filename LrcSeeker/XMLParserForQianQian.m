//
//  XMLParserForQianQian.m
//  LrcSeeker
//
//  Created by Eru on 15/11/21.
//  Copyright © 2015年 Eru. All rights reserved.
//

#import "XMLParserForQianQian.h"

@implementation XMLParserForQianQian

-(id) init {
    self = [super init];
    if (self) {
        resultArray = [[NSMutableArray alloc] init];
    }
    return self;
}

-(NSArray *)arrayWithData: (NSData *)data {
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:data];
    parser.delegate = self;
    if ([parser parse] == NO) {
        NSLog(@"%@",[parser parserError]);
        NSString *errorStr=[NSString stringWithFormat:@"%@:%@",NSLocalizedString(@"QIANQIAN", nil),NSLocalizedString(@"PARSE_ERROR", nil)];
        NSDictionary *userInfo=[NSDictionary dictionaryWithObject:errorStr forKey:ErrorOccuredNotification];
        [[NSNotificationCenter defaultCenter] postNotificationName:ErrorOccuredNotification object:nil userInfo:userInfo];
        [resultArray removeAllObjects];
    }
    return resultArray;
}

-(void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary<NSString *,NSString *> *)attributeDict {
    if ([elementName isEqualToString:@"lrc"]) {
        SongInfos *info=[[SongInfos alloc] init];
        info.songID=[attributeDict objectForKey:@"id"];
        info.artist=[attributeDict objectForKey:@"artist"];
        info.songTitle=[attributeDict objectForKey:@"title"];
        info.source=NSLocalizedString(@"QIANQIAN", nil);
        NSString *accessCode=ttpCode(info.artist, info.songTitle, [info.songID intValue]);
        if ([[NSUserDefaults standardUserDefaults] integerForKey:LSServerIndex] == 0) {
            info.lyricURL=[NSString stringWithFormat:@"http://ttlrcct.qianqian.com/dll/lyricsvr.dll?dl?Id=%@&Code=%@",info.songID,accessCode];
        } else {
            info.lyricURL=[NSString stringWithFormat:@"http://ttlrccnc.qianqian.com/dll/lyricsvr.dll?dl?Id=%@&Code=%@",info.songID,accessCode];
        }
        [resultArray addObject:info];
    }
}

#pragma mark - QianQian Encoding

FOUNDATION_STATIC_INLINE long conv(long i)
{
    long r = i % 0x100000000;
    if (i >= 0 && r > 0x80000000)
        r = r - 0x100000000;
    
    if (i < 0 && r < 0x80000000)
        r = r + 0x100000000;
    return r;
}

FOUNDATION_STATIC_INLINE NSString *ttpCode(NSString *artist, NSString *title, long lrcId)
{
    
    const char *bytes=[[artist stringByAppendingString:title] cStringUsingEncoding:NSUTF8StringEncoding];
    long len= strlen(bytes);
    int *song = (int*)malloc(sizeof(int)*len);
    for (int i = 0; i < len; i++)
        song[i] = bytes[i] & 0xff;
    
    long intVal1 = 0, intVal2 = 0, intVal3 = 0;
    intVal1 = (lrcId & 0x0000FF00) >> 8;
    if ((lrcId & 0xFF0000) == 0) {
        intVal3 = 0xFF & ~intVal1;
    } else {
        intVal3 = 0xFF & ((lrcId & 0x00FF0000) >> 16);
    }
    intVal3 = intVal3 | ((0xFF & lrcId) << 8);
    intVal3 = intVal3 << 8;
    intVal3 = intVal3 | (0xFF & intVal1);
    intVal3 = intVal3 << 8;
    if ((lrcId & 0xFF000000) == 0) {
        intVal3 = intVal3 | (0xFF & (~lrcId));
    } else {
        intVal3 = intVal3 | (0xFF & (lrcId >> 24));
    }
    long uBound = len - 1;
    while (uBound >= 0) {
        int c = song[uBound];
        if (c >= 0x80)
            c = c - 0x100;
        intVal1 = (c + intVal2) & 0x00000000FFFFFFFF;
        intVal2 = (intVal2 << (uBound % 2 + 4)) & 0x00000000FFFFFFFF;
        intVal2 = (intVal1 + intVal2) & 0x00000000FFFFFFFF;
        uBound -= 1;
    }
    uBound = 0;
    intVal1 = 0;
    while (uBound <= len - 1) {
        long c = song[uBound];
        if (c >= 128)
            c = c - 256;
        long intVal4 = (c + intVal1) & 0x00000000FFFFFFFF;
        intVal1 = (intVal1 << (uBound % 2 + 3)) & 0x00000000FFFFFFFF;
        intVal1 = (intVal1 + intVal4) & 0x00000000FFFFFFFF;
        uBound += 1;
    }
    long intVal5 = conv(intVal2 ^ intVal3);
    intVal5 = conv(intVal5 + (intVal1 | lrcId));
    intVal5 = conv(intVal5 * (intVal1 | intVal3));
    intVal5 = conv(intVal5 * (intVal2 ^ lrcId));
    
    long intVal6 = intVal5;
    if (intVal6 > 0x80000000) intVal5 = intVal6 - 0x100000000;
    
    return [NSString stringWithFormat:@"%ld",intVal5];
}

@end
