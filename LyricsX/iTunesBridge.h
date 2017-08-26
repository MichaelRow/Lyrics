//
//  iTunesBridge.h
//  LyricX
//
//  Created by Eru on 2017/3/17.
//  Copyright © 2017年 Eru. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface iTunesBridge : NSObject

-(BOOL) running;
-(BOOL) playing;

-(NSString *) title;
-(NSString *) artist;
-(NSString *) album;
-(NSString *) persistentID;
-(NSInteger) playerPosition;
-(NSData *) artwork;
-(NSInteger) playerState;

-(void) setLyrics: (NSString *)lyrics;
-(void) pause;
-(void) play;

@end
