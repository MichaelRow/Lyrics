//
//  AppDelegate.h
//  LrcSeeker
//
//  Created by Eru on 15/10/20.
//  Copyright © 2015年 Eru. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "iTunes.h"
#import "Xiami.h"
#import "TTPod.h"
#import "AlbumView.h"
#import "QianQian.h"
#import "PreferencesController.h"
#import "SongListView.h"
#import "GeCiMe.h"
#import "HUDController.h"
#import "ArtworkFiller.h"
#import "LrcLineModel.h"
#import "ErrorWindow.h"
#import "ErrorView.h"
#import "ChineseConverter.h"

@interface AppDelegate : NSObject <NSApplicationDelegate,ContextMenuDelegate> {
    
    NSMutableArray *songs;
    NSUserDefaults *defaults;
    NSTimer *timer;
    
    iTunesApplication *iTunes;
    Xiami *xiami;
    TTPod *ttpod;
    QianQian *qianqian;
    GeCiMe *geciMe;
    
    HUDController *hudWindow;
    ArtworkFiller *artworkFiller;
    PreferencesController *preferencesWindow;
    
    
    __weak IBOutlet NSMenuItem *sendToLyricsXMenuItem;
    IBOutlet ErrorWindow *errorWindow;
    IBOutlet NSTextField *songTileTextField;
    IBOutlet NSTextField *artistTextField;
    IBOutlet SongListView *songListView;
    IBOutlet AlbumView *albumView;
    IBOutlet NSMenu *tableViewMenu;
}

@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;

-(IBAction)searchLyrics:(id)sender;
-(IBAction)downloadLyrics:(id)sender;
-(IBAction)autofillSongTitleAndArtist:(id)sender;
-(IBAction)showPreferences:(id)sender;
-(IBAction)downloadArtwork:(id)sender;
-(IBAction)checkForUpdate:(id)sender;
-(IBAction)showLyricPreview:(id)sender;
-(IBAction)fillInArtwork:(id)sender;
- (IBAction)sendLrcToLyricsX:(id)sender;

@end

