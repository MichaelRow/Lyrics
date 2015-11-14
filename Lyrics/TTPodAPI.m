//
//  TTPodAPI.m
//  LrcSeeker
//
//  Created by Eru on 15/10/23.
//  Copyright © 2015年 Eru. All rights reserved.
//

#import "TTPodAPI.h"

NSString *const TTPodLrcLoadedNotification=@"TTPodLrcLoaded";

@implementation TTPodAPI

@synthesize songInfo;

-(void)getLyricsWithTitle:(NSString *)theTitle artist:(NSString *)theArtist {
    songInfo=nil;
    NSLog(@"TTPod starting searching lrcs");
    NSString *urlString=[NSString stringWithFormat:@"http://lp.music.ttpod.com/lrc/down?lrcid=&artist=%@&title=%@",theTitle,theArtist];
    NSString *convertedURLString = [urlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLFragmentAllowedCharacterSet]];
    NSLog(@"TTPodAPI:The converted url is:%@",convertedURLString);
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
        NSString *lyric=[[temp objectForKey:@"data"] objectForKey:@"lrc"];
        if (lyric!=nil && [lyric isNotEqualTo:@""]) {
            songInfo=[[SongInfos alloc] init];
            songInfo.songTitle=theTitle;
            songInfo.artist=theArtist;
            songInfo.lyric=lyric;
            songInfo.source=NSLocalizedString(@"TTPOD", nil);
            NSNotificationCenter *nc=[NSNotificationCenter defaultCenter];
            [nc postNotificationName:TTPodLrcLoadedNotification object:nil];
        }
    }];
    [dataTask resume];
}

@end
