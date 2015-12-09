//
//  PreferencesController.m
//  LrcSeeker
//
//  Created by Eru on 15/10/22.
//  Copyright © 2015年 Eru. All rights reserved.
//

#import "PreferencesController.h"

@interface PreferencesController ()

@end

@implementation PreferencesController

-(id) init {
    self=[super initWithWindowNibName:@"Preferences"];
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    defaults=[NSUserDefaults standardUserDefaults];
    [self initPopUpButton];
}

-(void)initPopUpButton {
    NSString *desktopPath=[NSSearchPathForDirectoriesInDomains(NSDesktopDirectory, NSUserDomainMask, YES) firstObject];
    NSString *musicPath=[NSSearchPathForDirectoriesInDomains(NSMusicDirectory, NSUserDomainMask, YES) firstObject];
    NSString *downloadPath=[NSSearchPathForDirectoriesInDomains(NSDownloadsDirectory, NSUserDomainMask, YES) firstObject];
    
    //set lrc pop up button
    NSString *userLrcPath=[defaults objectForKey:LSLrcPath];
    [[lrcPathButton itemAtIndex:0] setToolTip:desktopPath];
    [[lrcPathButton itemAtIndex:1] setToolTip:musicPath];
    [[lrcPathButton itemAtIndex:0] setImage:[[NSWorkspace sharedWorkspace] iconForFile:desktopPath]];
    [[lrcPathButton itemAtIndex:1] setImage:[[NSWorkspace sharedWorkspace] iconForFile:musicPath]];
    
    if ([userLrcPath isEqualToString:@""] || [userLrcPath isEqualToString:desktopPath] || [userLrcPath isEqualToString:musicPath]) {
        [[lrcPathButton itemAtIndex:2] setTitle:[downloadPath lastPathComponent]];
        [[lrcPathButton itemAtIndex:2] setToolTip:downloadPath];
        [[lrcPathButton itemAtIndex:2] setImage:[[NSWorkspace sharedWorkspace] iconForFile:downloadPath]];
    }
    else {
        [[lrcPathButton itemAtIndex:2] setTitle:[userLrcPath lastPathComponent]];
        [[lrcPathButton itemAtIndex:2] setToolTip:userLrcPath];
        [[lrcPathButton itemAtIndex:2] setImage:[[NSWorkspace sharedWorkspace] iconForFile:userLrcPath]];
    }

    //set artwork pop up button
    NSString *userArtworkPath=[defaults objectForKey:LSArtworkPath];
    [[artworkPathButton itemAtIndex:0] setToolTip:desktopPath];
    [[artworkPathButton itemAtIndex:1] setToolTip:musicPath];
    [[artworkPathButton itemAtIndex:0] setImage:[[NSWorkspace sharedWorkspace] iconForFile:desktopPath]];
    [[artworkPathButton itemAtIndex:1] setImage:[[NSWorkspace sharedWorkspace] iconForFile:musicPath]];
    
    if ([userArtworkPath isEqualToString:@""] || [userArtworkPath isEqualToString:desktopPath] || [userArtworkPath isEqualToString:musicPath]) {
        [[artworkPathButton itemAtIndex:2] setTitle:[downloadPath lastPathComponent]];
        [[artworkPathButton itemAtIndex:2] setToolTip:downloadPath];
        [[artworkPathButton itemAtIndex:2] setImage:[[NSWorkspace sharedWorkspace] iconForFile:downloadPath]];
    }
    else {
        [[artworkPathButton itemAtIndex:2] setTitle:[userArtworkPath lastPathComponent]];
        [[artworkPathButton itemAtIndex:2] setToolTip:userArtworkPath];
        [[artworkPathButton itemAtIndex:2] setImage:[[NSWorkspace sharedWorkspace] iconForFile:userArtworkPath]];
    }
}

#pragma mark - Actions

-(IBAction)setLrcDownloadPath:(id)sender {
    __block NSOpenPanel *panel=[NSOpenPanel openPanel];
    [panel setCanChooseFiles:NO];
    [panel setCanChooseDirectories:YES];
    [panel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result) {
        if (result==NSFileHandlingPanelOKButton) {
            NSURL *url=[panel URL];
            NSString *newPath=[url path];
            NSLog(@"PC: the new lrc path is %@",newPath);
            [defaults setObject:newPath forKey:LSLrcPath];
            int i=0;
            for (i=0; i<2; ++i) {
                if ([[[lrcPathButton itemAtIndex:i] toolTip] isEqualToString:newPath] ) {
                    NSString *downloadPath=[NSSearchPathForDirectoriesInDomains(NSDownloadsDirectory, NSUserDomainMask, YES) firstObject];
                    [[lrcPathButton itemAtIndex:2] setTitle:[downloadPath lastPathComponent]];
                    [[lrcPathButton itemAtIndex:2] setToolTip:downloadPath];
                    [[lrcPathButton itemAtIndex:2] setImage:[[NSWorkspace sharedWorkspace] iconForFile:downloadPath]];
                    
                    [lrcPathButton selectItemAtIndex:i];
                    
                    break;
                }
            }
            if (i==2) {
                [[lrcPathButton itemAtIndex:2] setTitle:[newPath lastPathComponent]];
                [[lrcPathButton itemAtIndex:2] setToolTip:newPath];
                [[lrcPathButton itemAtIndex:2] setImage:[[NSWorkspace sharedWorkspace] iconForFile:newPath]];
                [lrcPathButton selectItemAtIndex:2];
            }
        }
        panel=nil;
    }];
}

-(IBAction)setArtworkDownloadPath:(id)sender {
    __block NSOpenPanel *panel=[NSOpenPanel openPanel];
    [panel setCanChooseFiles:NO];
    [panel setCanChooseDirectories:YES];
    [panel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result) {
        if (result==NSFileHandlingPanelOKButton) {
            NSURL *url=[panel URL];
            NSString *newPath=[url path];
            NSLog(@"PC: the new lrc path is %@",newPath);
            [defaults setObject:newPath forKey:LSArtworkPath];
            int i=0;
            for (i=0; i<2; ++i) {
                if ([[[artworkPathButton itemAtIndex:i] toolTip] isEqualToString:newPath] ) {
                    NSString *downloadPath=[NSSearchPathForDirectoriesInDomains(NSDownloadsDirectory, NSUserDomainMask, YES) firstObject];
                    [[artworkPathButton itemAtIndex:2] setTitle:[downloadPath lastPathComponent]];
                    [[artworkPathButton itemAtIndex:2] setToolTip:downloadPath];
                    [[artworkPathButton itemAtIndex:2] setImage:[[NSWorkspace sharedWorkspace] iconForFile:downloadPath]];
                    
                    [artworkPathButton selectItemAtIndex:i];
                    
                    break;
                }
            }
            if (i==2) {
                [[artworkPathButton itemAtIndex:2] setTitle:[newPath lastPathComponent]];
                [[artworkPathButton itemAtIndex:2] setToolTip:newPath];
                [[artworkPathButton itemAtIndex:2] setImage:[[NSWorkspace sharedWorkspace] iconForFile:newPath]];
                [artworkPathButton selectItemAtIndex:2];
            }
        }
        panel=nil;
    }];
}

-(IBAction)setLrcDownloadPathByPopUp:(id)sender {
    NSNumber *index=[NSNumber numberWithInteger:[sender indexOfSelectedItem]];
    NSString *newPath=[[sender selectedItem] toolTip];
    [defaults setObject:newPath forKey:LSLrcPath];
    [defaults setObject:index forKey:LSLrcPathIndex];
    NSLog(@"PC: the new lrc path is %@",newPath);
}

-(IBAction)setArtworkDownloadPathbyPopUp:(id)sender {
    NSNumber *index=[NSNumber numberWithInteger:[sender indexOfSelectedItem]];
    NSString *newPath=[[sender selectedItem] toolTip];
    [defaults setObject:newPath forKey:LSArtworkPath];
    [defaults setObject:index forKey:LSArtworkPathIndex];
    NSLog(@"PC: the new artwork path is %@",newPath);
}

@end
