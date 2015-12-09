//
//  TTPod.m
//  LrcSeeker
//
//  Created by Eru on 15/10/23.
//  Copyright © 2015年 Eru. All rights reserved.
//

#import "TTPod.h"

@implementation TTPod

@synthesize songInfos;

-(void)getLyricsWithTitle:(NSString *)theTitle artist:(NSString *)theArtist {
    songInfos = nil;
    date = [NSDate date];
    NSDate *dateWhenSearch = date;

    NSLog(@"TTPod starting searching lrcs");
    NSString *urlString=[NSString stringWithFormat:@"http://lp.music.ttpod.com/lrc/down?lrcid=&artist=%@&title=%@",theTitle,theArtist];
    NSString *convertedURLString = [urlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLFragmentAllowedCharacterSet]];
    NSMutableURLRequest *req=[NSMutableURLRequest requestWithURL:[NSURL URLWithString: convertedURLString] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:15];
    [req setHTTPMethod:@"GET"];
    [req addValue:@"text/xml" forHTTPHeaderField: @"Content-Type"];
    
    NSURLSession *session=[NSURLSession sharedSession];
    NSURLSessionDataTask *dataTask=[session dataTaskWithRequest:req completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSError *jsonError;
        NSHTTPURLResponse *httpResponse=(NSHTTPURLResponse *)response;
        int statusCode=(int)[httpResponse statusCode];
        if (!(statusCode>=200 && statusCode<300) || error) {
            NSString *errorStr=[NSString stringWithFormat:@"%@:%@",NSLocalizedString(@"TTPOD", nil),NSLocalizedString(@"NET_CONNECTION_ERROR", nil)];
            NSDictionary *userInfo=[NSDictionary dictionaryWithObject:errorStr forKey:ErrorOccuredNotification];
            [[NSNotificationCenter defaultCenter] postNotificationName:ErrorOccuredNotification object:nil userInfo:userInfo];
            return;
        }
        NSDictionary *temp=[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&jsonError];
        if (jsonError) {
            NSLog(@"TTPodAPI:%@",[jsonError localizedDescription]);
            NSString *errorStr=[NSString stringWithFormat:@"%@:%@",NSLocalizedString(@"TTPOD", nil),NSLocalizedString(@"PARSE_ERROR", nil)];
            NSDictionary *userInfo=[NSDictionary dictionaryWithObject:errorStr forKey:ErrorOccuredNotification];
            [[NSNotificationCenter defaultCenter] postNotificationName:ErrorOccuredNotification object:nil userInfo:userInfo];
            return;
        }
        SongInfos *info = [[SongInfos alloc] init];
        NSString *lyric=[[temp objectForKey:@"data"] objectForKey:@"lrc"];
        if (lyric!=nil && [lyric isNotEqualTo:@""]) {
            info.songTitle=theTitle;
            info.artist=theArtist;
            info.lyric=lyric;
            info.source=NSLocalizedString(@"TTPOD", nil);
            
            if ([date isEqualToDate:dateWhenSearch]) {
                songInfos = info;
                [[NSNotificationCenter defaultCenter] postNotificationName:LSTTPodLoadedNotification object:nil];
            }
        }
    }];
    [dataTask resume];
}

@end
