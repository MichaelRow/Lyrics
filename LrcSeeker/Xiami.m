//
//  XiamiAPI.m
//  Test4LrcSeeker
//
//  Created by Eru on 15/10/20.
//  Copyright © 2015年 Eru. All rights reserved.
//

#import "Xiami.h"

@implementation Xiami

@synthesize currentSongs;

-(void)getLyricsWithTitle:(NSString *)theTitle artist:(NSString *)theArtist{
    
    //Tow Steps：
    //1.Searching for songs using title and artist，and it will return json format which we can get song ID needed.
    //2.Get song info XML using song ID, and then parse for lrc and artwork URL.
    date = [NSDate date];
    NSDate *dateWhenSearch = date;
    currentSongs = nil;
    
    NSLog(@"Xiami starting searching lrcs");
    NSString *urlString=[NSString stringWithFormat:@"http://www.xiami.com/web/search-songs?key=%@ %@",theTitle,theArtist];
    NSString *convertedURLString = [urlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLFragmentAllowedCharacterSet]];
    NSURL *urlToGetSongID=[NSURL URLWithString:convertedURLString];
    NSMutableURLRequest *req=[NSMutableURLRequest requestWithURL:urlToGetSongID cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:15];
    [req setHTTPMethod:@"GET"];
    [req addValue:@"text/xml" forHTTPHeaderField: @"Content-Type"];
    
    NSURLSession *session=[NSURLSession sharedSession];
    NSURLSessionDataTask *dataTask=[session dataTaskWithRequest:req completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSHTTPURLResponse *httpResponse=(NSHTTPURLResponse *)response;
        int statusCode=(int)[httpResponse statusCode];
        if (!(statusCode>=200 && statusCode<300) || error || !data) {
            NSString *errorStr=[NSString stringWithFormat:@"%@:%@",NSLocalizedString(@"XIAMI", nil),NSLocalizedString(@"NET_CONNECTION_ERROR", nil)];
            NSDictionary *userInfo=[NSDictionary dictionaryWithObject:errorStr forKey:ErrorOccuredNotification];
            [[NSNotificationCenter defaultCenter] postNotificationName:ErrorOccuredNotification object:nil userInfo:userInfo];
            return;
        }
        
        NSError *jsonError;
        NSArray *jsonArray=[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&jsonError];
        if (jsonError) {
            NSLog(@"XiamiAPI:%@",[jsonError localizedDescription]);
            NSString *errorStr=[NSString stringWithFormat:@"%@:%@",NSLocalizedString(@"XIAMI", nil),NSLocalizedString(@"PARSE_ERROR", nil)];
            NSDictionary *userInfo=[NSDictionary dictionaryWithObject:errorStr forKey:ErrorOccuredNotification];
            [[NSNotificationCenter defaultCenter] postNotificationName:ErrorOccuredNotification object:nil userInfo:userInfo];
            return;
        }
        NSMutableArray *resultArray = [[NSMutableArray alloc] init];
        for (int i=0; i<[jsonArray count]; ++i) {
            SongInfos *anInfo=[[SongInfos alloc] init];
            [anInfo setSongTitle:[[jsonArray objectAtIndex:i]objectForKey:@"title"]];
            [anInfo setArtist:[[jsonArray objectAtIndex:i]objectForKey:@"author"]];
            [anInfo setSongID:[[jsonArray objectAtIndex:i]objectForKey:@"id"]];
            [anInfo setSource:NSLocalizedString(@"XIAMI", nil)];
            [resultArray addObject:anInfo];
        }
        if ([resultArray count]>0) {
            [self getLrcURLWithArray:resultArray andDate:dateWhenSearch];
        }
    }];
    [dataTask resume];
}

-(void)getLrcURLWithArray:(NSArray *) resultArray andDate:(NSDate *)theDate{
    parseNumber=0;
    int songsCount=(int)[resultArray count];
    for (int i=0; i<songsCount; ++i) {
        NSURL *songInfoURL=[NSURL URLWithString:[NSString stringWithFormat:@"http://www.xiami.com/song/playlist/id/%@",[[resultArray objectAtIndex:i] songID]]];
        NSMutableURLRequest *req=[NSMutableURLRequest requestWithURL:songInfoURL cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:15];
        [req setHTTPMethod:@"GET"];
        [req addValue:@"text/xml" forHTTPHeaderField: @"Content-Type"];
        
        NSURLSession *session=[NSURLSession sharedSession];
        NSURLSessionDataTask *dataTask=[session dataTaskWithRequest:req completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            if (!data) {
                NSLog(@"XiamiAPI:Failed to get song IDs.No Internet access.");
                ++parseNumber;
                if (parseNumber==songsCount) {
                    if ([date isEqualToDate:theDate]) {
                        currentSongs = resultArray;
                        [[NSNotificationCenter defaultCenter] postNotificationName:LSXiamiLoadedNotification object:nil];
                    }
                }
                return;
            }
            if (error) {
                NSLog(@"XiamiAPI:At getLrcURL datatask handler:%@",[error localizedDescription]);
                ++parseNumber;
                if (parseNumber==songsCount) {
                    if ([date isEqualToDate:theDate]) {
                        currentSongs = resultArray;
                        [[NSNotificationCenter defaultCenter] postNotificationName:LSXiamiLoadedNotification object:nil];
                    }
                }
                return;
            }
            else {
                XMLParserForXiami *parser=[[XMLParserForXiami alloc] init];
                NSDictionary *dictionary=[parser dictionaryWithData:data];
                if (dictionary) {
                    [[resultArray objectAtIndex:i] setLyricURL:[dictionary objectForKey:@"lyricURL"]];
                    [[resultArray objectAtIndex:i] setArtWorkURL:[dictionary objectForKey:@"artWorkURL"]];
                    ++parseNumber;
                    if (parseNumber==[resultArray count]) {
                        if ([date isEqualToDate:theDate]) {
                            currentSongs = resultArray;
                            [[NSNotificationCenter defaultCenter] postNotificationName:LSXiamiLoadedNotification object:nil];
                        }
                    }
                }
            }
        }];
        [dataTask resume];
    }
}


//-(void)removeDuplicate {

//    Remove duplicated items and post notification to inform table view to update.
//    ps: Songs with the same artwork and lrc but different mp3 URL is considered
//     "duplicate".
    
//    int i=0;
//    int j=1;
//    while (i<[songs count]-1) {
//        while (j<[songs count]) {
//            if ([[[songs objectAtIndex:i] lyricURL] isEqualToString:[[songs objectAtIndex:j] lyricURL]] && [[[songs objectAtIndex:i] artWorkURL] isEqualToString:[[songs objectAtIndex:j] artWorkURL]]) {
//                if ([[[[songs objectAtIndex:i] songDownloadURLs ] firstObject] isNotEqualTo:[[[songs objectAtIndex:j] songDownloadURLs ] firstObject]]) {
//                    [[songs objectAtIndex:i] addSongDownloadURL:[[[songs objectAtIndex:j] songDownloadURLs ] firstObject]];
//                }
//                NSLog(@"XiamiAPI:remove a duplicate item");
//                [songs removeObjectAtIndex:j];
//            }
//            else {
//                ++j;
//            }
//        }
//        ++i;
//    }
//}

@end
