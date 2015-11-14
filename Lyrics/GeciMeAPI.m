//
//  GeciMeAPI.m
//  LrcSeeker
//
//  Created by Eru on 15/10/26.
//  Copyright © 2015年 Eru. All rights reserved.
//

#import "GeciMeAPI.h"

NSString *const GeciMeLrcLoadedNotification=@"GeciMeLrcLoaded";

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
    NSLog(@"GeciMe:The converted url is:%@",convertedURLString);
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
            NSLog(@"GeciMeAPI:%@",[jsonError localizedDescription]);
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
            NSArray *songArray=[dic objectForKey:@"result"];
            for (int i=0; i<count; ++i) {
                NSDictionary *songInfoDic=[songArray objectAtIndex:i];
                SongInfos *info=[[SongInfos alloc] init];
                info.artist=theArtist;
                info.songTitle=theTitle;
                info.lyricURL=[songInfoDic objectForKey:@"lrc"];
                info.source=NSLocalizedString(@"GECIME", nil);
                [songs addObject:info];
                NSLog(@"GeciMe:%@,%@,%@",info.artist,info.songTitle,info.lyricURL);
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:GeciMeLrcLoadedNotification object:nil];
        }
    }];
    [dataTask resume];
}

@end
