//
//  iTunesBridge.h
//  Lyrics
//
//  Created by Eru on 15/11/16.
//  Copyright © 2015年 Eru. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "iTunes.h"

@interface iTunesBridge : NSObject

-(BOOL) running;
-(BOOL) playing;

-(NSString *) currentTitle;
-(NSString *) currentArtist;
-(NSString *) currentAlbum;
-(NSString *) currentPersistentID;
-(NSInteger) playerPosition;
-(NSData *) artwork;
-(void) setLyrics: (NSString *)lyrics;
-(BOOL) setAllLyrics: (BOOL)skip;
-(void) pause;
-(void) play;

@end
