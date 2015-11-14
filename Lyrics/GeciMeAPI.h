//
//  GeciMeAPI.h
//  LrcSeeker
//
//  Created by Eru on 15/10/26.
//  Copyright © 2015年 Eru. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SongInfos.h"

extern NSString *const GeciMeLrcLoadedNotification;

@interface GeciMeAPI : NSObject

@property NSMutableArray *songs; 

-(void)getLyricsWithTitle:(NSString *)theTitle artist:(NSString *)theArtist;

@end
