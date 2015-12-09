//
//  AlbumView.h
//  LrcSeeker
//
//  Created by Eru on 15/10/21.
//  Copyright © 2015年 Eru. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PreferencesController.h"

@interface AlbumView : NSView <NSPasteboardItemDataProvider,NSDraggingSource>{
    NSImage* artwork;
    NSImage* snapshotArtwork;
    NSData* artworkData;
    NSString* artworkName;
    NSString* artworkTempPath;
    NSString* tempDir;
    NSEvent* mouseDownEvent;
    NSUserDefaults *defaults;
    NSDate* date;
    NSRect drawingRect;
}

@property (nonatomic) NSImage *artwork;
@property (nonatomic) NSData *artworkData;
@property (nonatomic) NSString *artworkTempPath;
@property (nonatomic) NSString *artworkName;

-(void)noSelectionImage;
-(void)noFoundImage;
-(void)setArtWorkWithURL:(NSURL *)theURL andArtworkName:(NSString *) theName;

@end
