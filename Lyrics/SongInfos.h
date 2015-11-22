//
//  SongInfos.h
//  Test4LrcSeeker
//
//  Created by Eru on 15/10/20.
//  Copyright © 2015年 Eru. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *const LrcLoadedNotification;

@interface SongInfos : NSObject <NSCopying>

@property (nonatomic,copy) NSString *songTitle;
@property (nonatomic,copy) NSString *artist;
@property (nonatomic,copy) NSString *lyricURL;
@property (nonatomic,copy) NSString *songID;
@property (nonatomic,copy) NSString *lyric;

//-(void)setSongTitleWithUnicode:(NSString *) unicodeTitle artist:(NSString *) unicodeArtist;

@end
