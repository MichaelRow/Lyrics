//
//  GeCiMe.m
//  LrcSeeker
//
//  Created by Eru on 15/11/21.
//  Copyright © 2015年 Eru. All rights reserved.
//

#import "GeCiMe.h"

@implementation GeCiMe

@synthesize currentSongs;

-(id) init {
    self = [super init];
    if (self) {
        currentSongs = [[NSMutableArray alloc] init];
    }
    return self;
}

-(void)getLyricsWithTitle:(NSString *)theTitle artist:(NSString *)theArtist songID:(NSString *)songID titleForSearching:(NSString *)titleForSearching andArtistForSearching:(NSString *) artistForSearching {
    [currentSongs removeAllObjects];
    date = [NSDate date];
    NSDate *dateWhenSearch = date;

    NSLog(@"GeciMe starting searching lrcs");
    NSString *urlString=[NSString stringWithFormat:@"http://geci.me/api/lyric/%@/%@",titleForSearching,artistForSearching];
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
            return;
        }
        int count=[[dic objectForKey:@"count"] intValue];
        if (count==0) {
            return;
        }
        else {
            NSMutableArray *resultArray = [[NSMutableArray alloc] init];
            NSArray *serverSongArray=[dic objectForKey:@"result"];
            for (int i=0; i<count; ++i) {
                NSDictionary *songInfoDic=[serverSongArray objectAtIndex:i];
                SongInfos *info=[[SongInfos alloc] init];
                info.artist=theArtist;
                info.songTitle=[songInfoDic objectForKey:@"song"];
                info.lyricURL=[songInfoDic objectForKey:@"lrc"];
                [resultArray addObject:info];
            }
            if ([date isEqualToDate:dateWhenSearch]) {
                currentSongs = resultArray;
                NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
                [userInfo setObject:[NSNumber numberWithInteger:4] forKey:@"source"];
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
