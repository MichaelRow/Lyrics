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

-(void)getLyricsWithTitle:(NSString *)theTitle artist:(NSString *)theArtist {
    currentSongs = nil;
    date = [NSDate date];
    NSDate *dateWhenSearch = date;

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
            NSString *errorStr=[NSString stringWithFormat:@"%@:%@",NSLocalizedString(@"GECIME", nil),NSLocalizedString(@"NET_CONNECTION_ERROR", nil)];
            NSDictionary *userInfo=[NSDictionary dictionaryWithObject:errorStr forKey:ErrorOccuredNotification];
            [[NSNotificationCenter defaultCenter] postNotificationName:ErrorOccuredNotification object:nil userInfo:userInfo];
            return;
        }
        NSDictionary *dic=[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&jsonError];
        if (jsonError) {
            NSString *errorStr=[NSString stringWithFormat:@"%@:%@",NSLocalizedString(@"GECIME", nil),NSLocalizedString(@"PARSE_ERROR", nil)];
            NSDictionary *userInfo=[NSDictionary dictionaryWithObject:errorStr forKey:ErrorOccuredNotification];
            [[NSNotificationCenter defaultCenter] postNotificationName:ErrorOccuredNotification object:nil userInfo:userInfo];
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
                info.source=NSLocalizedString(@"GECIME", nil);
                [resultArray addObject:info];
            }
            if ([date isEqualToDate:dateWhenSearch]) {
                currentSongs = resultArray;
                [[NSNotificationCenter defaultCenter] postNotificationName:LSGeCiMeLoadedNotification object:nil];
            }
        }
    }];
    [dataTask resume];
}

@end
