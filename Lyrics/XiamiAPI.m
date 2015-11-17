//
//  XiamiAPI.m
//  Test4LrcSeeker
//
//  Created by Eru on 15/10/20.
//  Copyright © 2015年 Eru. All rights reserved.
//

#import "XiamiAPI.h"

@implementation XiamiAPI

@synthesize songs;

-(id)init {
    self=[super init];
    if (self) {
        songs=[[NSMutableArray alloc]init];
    }
    return self;
}

-(void)getLyricsWithTitle:(NSString *)theTitle artist:(NSString *)theArtist{
    
    //Tow Steps：
    //1.Searching for songs using title and artist，and it will return json format which we can get song ID needed.
    //2.Get song info XML using song ID, and then parse for lrc and artwork URL.
        
    [songs removeAllObjects];
    songSearchResultData=nil;
    currentString=nil;
    currentField=nil;
    
    NSString *urlString=[NSString stringWithFormat:@"http://www.xiami.com/web/search-songs?key=%@ %@",theTitle,theArtist];
    NSString *convertedURLString = [urlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLFragmentAllowedCharacterSet]];
    NSURL *urlToGetSongID=[NSURL URLWithString:convertedURLString];
    NSMutableURLRequest *req=[NSMutableURLRequest requestWithURL:urlToGetSongID cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:15];
    [req setHTTPMethod:@"GET"];
    [req addValue:@"text/xml" forHTTPHeaderField: @"Content-Type"];
    NSURLSession *sessionToGetSongID=[NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:nil];
    NSURLSessionDataTask *dataTask=[sessionToGetSongID dataTaskWithRequest:req];
    [dataTask resume];
}

-(void)getLrcURL {
    parseNumber=0;
    int songsCount=(int)[songs count];
    for (int i=0; i<songsCount; ++i) {
        NSURL *songInfoURL=[NSURL URLWithString:[NSString stringWithFormat:@"http://www.xiami.com/song/playlist/id/%@",[[songs objectAtIndex:i] songID]]];
        NSMutableURLRequest *req=[NSMutableURLRequest requestWithURL:songInfoURL cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:15];
        [req setHTTPMethod:@"GET"];
        [req addValue:@"text/xml" forHTTPHeaderField: @"Content-Type"];
        NSURLSession *session=[NSURLSession sharedSession];
        NSURLSessionDataTask *dataTask=[session dataTaskWithRequest:req completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            if (!data) {
                NSLog(@"XiamiAPI:Failed to get song IDs.No Internet access.");
                ++parseNumber;
                if (parseNumber==[songs count]) {
                    NSDictionary *userInfo=[NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:2] forKey:@"source"];
                    [[NSNotificationCenter defaultCenter] postNotificationName:LrcLoadedNotification object:self userInfo:userInfo];
                }
                return;
            }
            if (error) {
                NSLog(@"%@",[error localizedDescription]);
                ++parseNumber;
                if (parseNumber==[songs count]) {
                    NSDictionary *userInfo=[NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:2] forKey:@"source"];
                    [[NSNotificationCenter defaultCenter] postNotificationName:LrcLoadedNotification object:self userInfo:userInfo];
                }
                return;
            }
            else {
                XMLParserForXiami *parser=[[XMLParserForXiami alloc]init];
                NSDictionary *dictionary=[parser dictionaryWithData:data];
                if (dictionary) {
                    [[songs objectAtIndex:i] setLyricURL:[dictionary objectForKey:@"lyricURL"]];
                    ++parseNumber;
                    if (parseNumber==[songs count]) {
                        NSDictionary *userInfo=[NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:2] forKey:@"source"];
                        [[NSNotificationCenter defaultCenter] postNotificationName:LrcLoadedNotification object:self userInfo:userInfo];
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

    
#pragma mark - NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    NSHTTPURLResponse *httpResponse=(NSHTTPURLResponse*)response;
    int statusCode=(int)[httpResponse statusCode];
    if (!(statusCode>=200 && statusCode<300)) {
        return;
    }
    songSearchResultData=[[NSMutableData alloc] init];
    completionHandler(NSURLSessionResponseAllow);
}

-(void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    [songSearchResultData appendData:data];
}

-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if (!songSearchResultData || error) {
        return;
    }
    NSError *jsonError;
    NSArray *jsonArray=[NSJSONSerialization JSONObjectWithData:songSearchResultData options:NSJSONReadingMutableContainers error:&jsonError];
    if (jsonError) {
        NSLog(@"XiamiAPI:%@",[jsonError localizedDescription]);
        return;
    }
    for (int i=0; i<[jsonArray count]; ++i) {
        SongInfos *anInfo=[[SongInfos alloc] init];
        [anInfo setSongTitle:[[jsonArray objectAtIndex:i]objectForKey:@"title"]];
        [anInfo setArtist:[[jsonArray objectAtIndex:i]objectForKey:@"author"]];
        [anInfo setSongID:[[jsonArray objectAtIndex:i]objectForKey:@"id"]];
        [songs addObject:anInfo];
    }

    [self getLrcURL];
}

@end
