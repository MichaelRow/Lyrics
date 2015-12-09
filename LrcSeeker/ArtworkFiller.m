//
//  ArtworkFiller.m
//  LrcSeeker
//
//  Created by Eru on 15/10/28.
//  Copyright © 2015年 Eru. All rights reserved.
//

#import "ArtworkFiller.h"

@interface ArtworkFiller ()

@end

@implementation ArtworkFiller {
    iTunesArtwork *artwork;
}

-(id) init {
    self=[super initWithWindowNibName:@"ArtworkFiller"];
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

-(void)setNewArtworkWithData:(NSData *)theData artworkImage:(NSImage *)theImage name:(NSString *) theName andTempPath:(NSString *) thePath {
    [newArtwork setArtworkName:theName];
    [newArtwork setArtworkTempPath:thePath];
    [newArtwork setArtworkData:theData];
    [newArtwork setArtwork:theImage];
}

-(void)setTheITunesArtwork {
    @autoreleasepool {
        NSFileManager *fm=[NSFileManager defaultManager];
        NSString *cachesDir=[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
        NSString *tempDir=[cachesDir stringByAppendingPathComponent:@"LrcSeeker"];
        NSString *artworkTempPath=[tempDir stringByAppendingPathComponent:@"iTunes_Artwork_Temp.jpg"];
        if ([fm fileExistsAtPath:artworkTempPath isDirectory:nil]) {
            [fm removeItemAtPath:artworkTempPath error:nil];
        }
        [theITunesArtwork setArtworkTempPath:artworkTempPath];
        [theITunesArtwork setArtworkName:@"iTunes_Artwork_Temp"];
        iTunesApplication *iTunes=[SBApplication applicationWithBundleIdentifier:@"com.apple.iTunes"];
        [artistLabel setStringValue:[[iTunes currentTrack] artist]];
        [songTitleLabel setStringValue:[[iTunes currentTrack] name]];
        SBElementArray* theArtworks = [[iTunes currentTrack] artworks];
        NSInteger count=[theArtworks count];
        if (count > 0) {
            artwork = [theArtworks objectAtIndex:0];
            NSData *artworkData=[artwork rawData];
            NSImage *artworkImage = [[NSImage alloc] initWithData:artworkData];
            [theITunesArtwork setArtworkData:artworkData];
            [theITunesArtwork setArtwork:artworkImage];
        }
        else {
            [theITunesArtwork setArtworkData:nil];
            [theITunesArtwork setArtwork:nil];
        }
    }
}

-(IBAction)okAction:(id)sender {
    [artwork setRawData:[newArtwork artworkData]];
    [[[self window] sheetParent] endSheet:[self window] returnCode:NSModalResponseOK];
}

-(IBAction)cancelAction:(id)sender {
    [[[self window] sheetParent] endSheet:[self window] returnCode:NSModalResponseCancel];
}

@end
