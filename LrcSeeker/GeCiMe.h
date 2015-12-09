//
//  GeCiMe.h
//  LrcSeeker
//
//  Created by Eru on 15/11/21.
//  Copyright © 2015年 Eru. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SongInfos.h"

@interface GeCiMe : NSObject {
    @private
    NSDate *date;
}

@property NSArray *currentSongs;

-(void)getLyricsWithTitle:(NSString *)theTitle artist:(NSString *)theArtist;

@end
