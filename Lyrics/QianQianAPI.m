//
//  QianQianAPI.m
//  LrcSeeker
//
//  Created by Eru on 15/10/23.
//  Copyright © 2015年 Eru. All rights reserved.
//

#import "QianQianAPI.h"

@implementation QianQianAPI

@synthesize songs;

-(id) init {
    self=[super init];
    if (self) {
        songs=[[NSMutableArray alloc] init];
    }
    return self;
}

-(void)getLyricsWithTitle:(NSString *)theTitle artist:(NSString *)theArtist;
 {
     [songs removeAllObjects];
     NSLog(@"QianQian starting searching lrcs");
     NSMutableString *title = [NSMutableString stringWithString: [theTitle stringByReplacingOccurrencesOfString:@" " withString:@""]];
     
     [title setString:[title lowercaseString]];
     
     NSMutableString *artist = [NSMutableString stringWithString:[theArtist stringByReplacingOccurrencesOfString:@" " withString:@""]];
     
     [artist setString:[artist lowercaseString]];
     
     
    NSString *urlString=[NSString stringWithFormat:@"http://ttlrccnc.qianqian.com/dll/lyricsvr.dll?sh?Artist=%@&Title=%@&Flags=0",setToHexString(artist),setToHexString(title)];
    NSMutableURLRequest *req=[NSMutableURLRequest requestWithURL:[NSURL URLWithString: urlString] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:15];
    [req setHTTPMethod:@"GET"];
    [req addValue:@"text/xml" forHTTPHeaderField: @"Content-Type"];
    NSURLSession *session=[NSURLSession sharedSession];
    NSURLSessionDataTask *dataTask=[session dataTaskWithRequest:req completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSHTTPURLResponse *httpResponse=(NSHTTPURLResponse *)response;
        int statusCode=(int)[httpResponse statusCode];
        if (!(statusCode>=200 && statusCode<300) || error || !data) {
            return;
        }
        NSXMLParser *parser=[[NSXMLParser alloc]initWithData:data];
        [parser setDelegate:self];
        if ([parser parse]==NO) {
            NSLog(@"%@",[parser parserError]);
            return;
        }
        else {
            NSDictionary *userInfo=[NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:1] forKey:@"source"];
            [[NSNotificationCenter defaultCenter] postNotificationName:LrcLoadedNotification object:userInfo];
        }
    }];
    [dataTask resume];
}

#pragma mark - NSXMLParseDelegate

-(void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary<NSString *,NSString *> *)attributeDict {
    if ([elementName isEqualToString:@"lrc"]) {
        SongInfos *info=[[SongInfos alloc] init];
        info.songID=[attributeDict objectForKey:@"id"];
        info.artist=[attributeDict objectForKey:@"artist"];
        info.songTitle=[attributeDict objectForKey:@"title"];
        NSString *accessCode=ttpCode(info.artist, info.songTitle, [info.songID intValue]);
        info.lyricURL=[NSString stringWithFormat:@"http://ttlrccnc.qianqian.com/dll/lyricsvr.dll?dl?Id=%@&Code=%@",info.songID,accessCode];
        [songs addObject:info];
    }
}


#pragma mark - Baidu Encoding

FOUNDATION_STATIC_INLINE char singleDecToHex(int dec)
{
    dec = dec % 16;
    if(dec < 10)
    {
        return (char)(dec+'0');
    }
    char arr[6]={'A','B','C','D','E','F'};
    return arr[dec-10];
}

FOUNDATION_STATIC_INLINE NSMutableString* setToHexString(NSString *str)
{
    
    const char *s = [str cStringUsingEncoding:NSUnicodeStringEncoding];
    NSMutableString *result = [NSMutableString string];
    
    if(!s) return NULL;
    int j = 0;
    int n= (int)[str lengthOfBytesUsingEncoding:NSUnicodeStringEncoding];
    for(int i=0; i<n; i++)
    {
        unsigned ord=(unsigned)s[i];
        if (j+2>1022)
        {
            return NULL;
        }
        
        [result appendFormat:@"%c%c",singleDecToHex((ord-ord%16)/16),singleDecToHex(ord%16)];
        
    }
    return result;
}



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
