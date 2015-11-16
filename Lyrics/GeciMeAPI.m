//
//  GeciMeAPI.m
//  LrcSeeker
//
//  Created by Eru on 15/10/26.
//  Copyright © 2015年 Eru. All rights reserved.
//

#import "GeciMeAPI.h"

@implementation GeciMeAPI 

@synthesize songs;

-(id)init {
    self=[super init];
    if (self) {
        songs=[[NSMutableArray alloc] init];
    }
    return self;
}

-(void)getLyricsWithTitle:(NSString *)theTitle artist:(NSString *)theArtist {
    [songs removeAllObjects];
    NSLog(@"GeciMe starting searching lrcs");
    NSString *urlString=[NSString stringWithFormat:@"http://geci.me/api/lyric/%@/%@",theTitle,theArtist];
    NSString *convertedURLString = [urlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLFragmentAllowedCharacterSet]];
    NSMutableURLRequest *req=[NSMutableURLRequest requestWithURL:[NSURL URLWithString: convertedURLString] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:15];
    [req setHTTPMethod:@"GET"];
    [req addValue:@"text/xml" forHTTPHeaderField: @"Content-Type"];
    NSURLSession *session=[NSURLSession sharedSession];
    NSURLSessionDataTask *dataTask=[session dataTaskWithRequest:req completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSError *jsonError;
        NSHTTPURLResponse *httpResponse=(NSHTTPURLResponse *)response;
        int statusCode=(int)[httpResponse statusCode];
        if (!(statusCode>=200 && statusCode<300) || error || !data) {
            return;
        }
        NSDictionary *dic=[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&jsonError];
        if (jsonError) {
            NSLog(@"GeciMeAPI:%@",[jsonError localizedDescription]);
            return;
        }
        int count=[[dic objectForKey:@"count"] intValue];
        if (count==0) {
            return;
        }
        else {
            NSArray *songArray=[dic objectForKey:@"result"];
            for (int i=0; i<count; ++i) {
                NSDictionary *songInfoDic=[songArray objectAtIndex:i];
                NSString *lrcURL=[songInfoDic objectForKey:@"lrc"];
                if (lrcURL == nil || [lrcURL isEqualToString:@""]) {
                    continue;
                }
                SongInfos *info=[[SongInfos alloc] init];
                info.artist=theArtist;
                info.songTitle=theTitle;
                info.lyricURL=lrcURL;
                [songs addObject:info];
            }
            NSDictionary *userInfo=[NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:4] forKey:@"source"];
            [[NSNotificationCenter defaultCenter] postNotificationName:LrcLoadedNotification object:userInfo];
        }
    }];
    [dataTask resume];
}

@end
