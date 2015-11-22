//
//  QianQian.h
//  LrcSeeker
//
//  Created by Eru on 15/10/23.
//  Copyright © 2015年 Eru. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SongInfos.h"
#import "XMLParserForQianQian.h"

@interface QianQian : NSObject {
    @private
    NSDate *date;
}

@property NSMutableArray *currentSongs;

-(void)getLyricsWithTitle:(NSString *)theTitle artist:(NSString *)theArtist songID:(NSString *)songID titleForSearching:(NSString *)titleForSearching andArtistForSearching:(NSString *) artistForSearching;

@end
