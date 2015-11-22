//
//  Xiami.h
//  Test4LrcSeeker
//
//  Created by Eru on 15/10/20.
//  Copyright © 2015年 Eru. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SongInfos.h"
#import "XMLParserForXiami.h"

@interface Xiami : NSObject <NSXMLParserDelegate,NSURLSessionDataDelegate> {
    
    @private
    NSDate *date;
}

@property NSMutableArray *currentSongs;

-(void)getLyricsWithTitle:(NSString *)theTitle artist:(NSString *)theArtist songID:(NSString *)songID titleForSearching:(NSString *)titleForSearching andArtistForSearching:(NSString *) artistForSearching;

@end
