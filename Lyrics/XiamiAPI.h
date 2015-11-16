//
//  XiamiAPI.h
//  Test4LrcSeeker
//
//  Created by Eru on 15/10/20.
//  Copyright © 2015年 Eru. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SongInfos.h"
#import "XMLParserForXiami.h"


@interface XiamiAPI : NSObject <NSXMLParserDelegate,NSURLSessionDataDelegate> {
    
    int parseNumber;
    NSMutableData *songSearchResultData;
    NSString *currentString;
    NSMutableDictionary *currentField;
}

@property (copy) NSMutableArray *songs;

-(void)getLyricsWithTitle:(NSString *)theTitle artist:(NSString *)theArtist;

@end
