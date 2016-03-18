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

-(id) init {
    self = [super init];
    if (self) {
        songInfos = [[SongInfos alloc] init];
    }
    return self;
}

-(void)getLyricsWithTitle:(NSString *)theTitle artist:(NSString *)theArtist songID:(NSString *)songID titleForSearching:(NSString *)titleForSearching andArtistForSearching:(NSString *) artistForSearching {
    songInfos.lyric = @"";
    date = [NSDate date];
    NSDate *dateWhenSearch = date;

    NSLog(@"TTPod starting searching lrcs");
    NSString *urlString=[NSString stringWithFormat:@"http://lp.music.ttpod.com/lrc/down?lrcid=&artist=%@&title=%@",titleForSearching,artistForSearching];
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
            return;
        }
        NSDictionary *temp=[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&jsonError];
        if (jsonError) {
            return;
        }
        SongInfos *info = [[SongInfos alloc] init];
        NSString *lyric=[[[temp objectForKey:@"data"] objectForKey:@"lrc"] stringByReplacingOccurrencesOfString:@"�" withString:@""];
        if (lyric!=nil && [lyric isNotEqualTo:@""]) {
            info.songTitle=theTitle;
            info.artist=theArtist;
            info.lyric=lyric;
            
            if ([date isEqualToDate:dateWhenSearch]) {
                songInfos = info;
                NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
                [userInfo setObject:[NSNumber numberWithInteger:3] forKey:@"source"];
                [userInfo setObject:theTitle forKey:@"title"];
                [userInfo setObject:theArtist forKey:@"artist"];
                [userInfo setObject:songID forKey:@"songID"];
                [[NSNotificationCenter defaultCenter] postNotificationName:LrcLoadedNotification object:nil userInfo:userInfo];
            }
        }
    }];
    [dataTask resume];
}

@end
