//
//  QianQianAPI.m
//  LrcSeeker
//
//  Created by Eru on 15/10/23.
//  Copyright © 2015年 Eru. All rights reserved.
//

#import "QianQian.h"

@implementation QianQian

@synthesize currentSongs;

-(id)init {
    self = [super init];
    if (self) {
        currentSongs = [[NSMutableArray alloc] init];
    }
    return self;
}

-(void)getLyricsWithTitle:(NSString *)theTitle artist:(NSString *)theArtist songID:(NSString *)songID titleForSearching:(NSString *)titleForSearching andArtistForSearching:(NSString *) artistForSearching  {
    [currentSongs removeAllObjects];
    date = [NSDate date];
    NSDate *dateWhenSearch = date;
    NSLog(@"QianQian starting searching lrcs");
    
    NSMutableString *title = [NSMutableString stringWithString: [titleForSearching stringByReplacingOccurrencesOfString:@" " withString:@""]];
     
    [title setString:[title lowercaseString]];
     
    NSMutableString *artist = [NSMutableString stringWithString:[artistForSearching stringByReplacingOccurrencesOfString:@" " withString:@""]];
     
    [artist setString:[artist lowercaseString]];
    
    NSString *urlString;
    if ([[NSUserDefaults standardUserDefaults] integerForKey:@"LyricsServerIndex"] == 0) {
        urlString=[NSString stringWithFormat:@"http://ttlrcct.qianqian.com/dll/lyricsvr.dll?sh?Artist=%@&Title=%@&Flags=0",setToHexString(artist),setToHexString(title)];
    } else {
        urlString=[NSString stringWithFormat:@"http://ttlrccnc.qianqian.com/dll/lyricsvr.dll?sh?Artist=%@&Title=%@&Flags=0",setToHexString(artist),setToHexString(title)];
    }

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
        
        XMLParserForQianQian *parser = [[XMLParserForQianQian alloc] init];
        NSArray *resultArray = [parser arrayWithData:data];
        if ([date isEqualToDate:dateWhenSearch] && [resultArray count]!=0) {
            [currentSongs addObjectsFromArray:resultArray];
            NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
            [userInfo setObject:[NSNumber numberWithInteger:1] forKey:@"source"];
            [userInfo setObject:theTitle forKey:@"title"];
            [userInfo setObject:theArtist forKey:@"artist"];
            [userInfo setObject:songID forKey:@"songID"];
            [[NSNotificationCenter defaultCenter] postNotificationName:LrcLoadedNotification object:nil userInfo:userInfo];
        }
    }];
    [dataTask resume];
}


#pragma mark - Hex convert Methods

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

@end
