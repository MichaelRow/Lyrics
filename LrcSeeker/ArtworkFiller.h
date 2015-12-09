//
//  ArtworkFiller.h
//  LrcSeeker
//
//  Created by Eru on 15/10/28.
//  Copyright © 2015年 Eru. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AlbumView.h"
#import "iTunes.h"

@interface ArtworkFiller : NSWindowController {
    
    IBOutlet AlbumView *newArtwork;
    IBOutlet AlbumView *theITunesArtwork;
    IBOutlet NSTextField *artistLabel;
    IBOutlet NSTextField *songTitleLabel;

}

-(void)setNewArtworkWithData:(NSData *)theData artworkImage:(NSImage *)theImage name:(NSString *) theName andTempPath:(NSString *) thePath;
-(void)setTheITunesArtwork;
-(IBAction)okAction:(id)sender;
-(IBAction)cancelAction:(id)sender;

@end
