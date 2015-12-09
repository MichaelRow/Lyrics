//
//  SongInfos.m
//  Test4LrcSeeker
//
//  Created by Eru on 15/10/20.
//  Copyright © 2015年 Eru. All rights reserved.
//

#import "SongInfos.h"

@implementation SongInfos

@synthesize songTitle;
@synthesize artist;
@synthesize lyricURL;
@synthesize artWorkURL;
@synthesize songID;
@synthesize lyric;
@synthesize source;

-(id) copyWithZone:(NSZone *)zone {
    SongInfos *info = [[SongInfos allocWithZone:zone] init];
    info.songTitle = songTitle;
    info.artist = artist;
    info.lyricURL = lyricURL;
    info.artWorkURL = artWorkURL;
    info.songID = songID;
    info.lyric = lyric;
    info.source = source;
    return info;
}

//-(void)setSongTitleWithUnicode:(NSString *) unicodeTitle artist:(NSString *) unicodeArtist {
//    songTitle=[self unicodeToCharacter:unicodeTitle];
//    artist=[self unicodeToCharacter:unicodeArtist];
//}
//
//-(NSString *)unicodeToCharacter:(NSString *)unicodeString {
//    
//    NSString *tempStr1 = [unicodeString stringByReplacingOccurrencesOfString:@"\\u" withString:@"\\U"];
//    NSString *tempStr2 = [tempStr1 stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
//    NSString *tempStr3 = [[@"\"" stringByAppendingString:tempStr2] stringByAppendingString:@"\""];
//    NSData *tempData = [tempStr3 dataUsingEncoding:NSUTF8StringEncoding];
//    NSString* returnStr = [NSPropertyListSerialization propertyListWithData:tempData options:NSPropertyListImmutable format:NULL error:nil];
//    NSLog(@"Convert \"%@\" to \"%@\"",unicodeString,returnStr);
//    return returnStr;
//}

@end
