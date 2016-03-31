//
//  iTunesBridge.m
//  Lyrics
//
//  Created by Eru on 15/11/16.
//  Copyright © 2015年 Eru. All rights reserved.
//

#import "iTunesBridge.h"
#import "LyricsX-Swift.h"

@implementation iTunesBridge {
    iTunesApplication *iTunes;
}

-(id)init {
    self = [super init];
    if (self) {
        iTunes = [SBApplication applicationWithBundleIdentifier:@"com.apple.iTunes"];
    }
    return self;
}

-(BOOL) running {
    @autoreleasepool {
        return iTunes.isRunning;
    }
}

-(BOOL) playing {
    @autoreleasepool {
        return (iTunes.playerState == iTunesEPlSPlaying);
    }
}

-(void) setLyrics: (NSString *)lyrics {
    @autoreleasepool {
        iTunes.currentTrack.lyrics = lyrics;
    }
}

-(BOOL) setAllLyrics: (BOOL)skip {
    @autoreleasepool {
        if (iTunes.playerState == iTunesEPlSPlaying) {
            SBElementArray *allTracks = iTunes.currentPlaylist.tracks;
            if (allTracks.count == 0) {
                return NO;
            }
            else {
                LrcParser *parser = [[LrcParser alloc] init];
                NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
                for (iTunesTrack *track in allTracks) {
                    if (skip && ![[track.lyrics stringByReplacingOccurrencesOfString:@" " withString:@""] isEqualToString:@""]) {
                        continue;
                    }
                    NSString *title = track.name;
                    NSString *artist = track.artist;
                    NSString *lrcContents = [[AppController sharedController] readLocalLyrics:title theArtist:artist];
                    if ([userDefaults boolForKey:@"LyricsEnableFilter"]) {
                        [parser parseWithFilter:lrcContents];
                    }
                    else {
                        [parser parseForLyrics:lrcContents];
                    }
                    if (parser.lyrics.count == 0) {
                        continue;
                    }
                    BOOL hasSpace = NO;
                    NSMutableString *lyrics = [[NSMutableString alloc] init];
                    for (LyricsLineModel *lrcLine in parser.lyrics) {
                        if ([[lrcLine.lyricsSentence stringByReplacingOccurrencesOfString:@" " withString:@""] isEqualToString:@""]) {
                            if (hasSpace) {
                                continue;
                            }
                            else {
                                hasSpace = YES;
                            }
                        }
                        else if (hasSpace) {
                            hasSpace = NO;
                        }
                        [lyrics appendString:lrcLine.lyricsSentence];
                        [lyrics appendString:@"\n"];
                    }
                    track.lyrics = lyrics;
                }
                return YES;
            }
        }
        else {
            return NO;
        }
    }
}

-(NSString *) currentTitle {
    @autoreleasepool {
        NSString *title = iTunes.currentTrack.name;
        if (!title) {
            title = @"";
        }
        return title;
    }
}

-(NSString *) currentArtist {
    @autoreleasepool {
        NSString *artist = iTunes.currentTrack.artist;
        if (!artist) {
            artist = @"";
        }
        return artist;
    }
}

-(NSString *) currentPersistentID {
    @autoreleasepool {
        NSString *persistentID = iTunes.currentTrack.persistentID;
        if (!persistentID) {
            persistentID = @"";
        }
        return persistentID;
    }
}

-(NSInteger) playerPosition {
    @autoreleasepool {
        return (NSInteger)(iTunes.playerPosition * 1000);
    }
}

-(NSData *) artwork {
    @autoreleasepool {
        SBElementArray* theArtworks = [[iTunes currentTrack] artworks];
        if ([theArtworks count] > 0) {
            iTunesArtwork *artwork = [theArtworks objectAtIndex:0];
            return [artwork rawData];
        } else {
            return nil;
        }
    }
}

-(void) play {
    @autoreleasepool {
        if (iTunes.playerState != iTunesEPlSPlaying) {
            [iTunes playpause];
        }
    }
}

-(void) pause {
    @autoreleasepool {
        [iTunes pause];
    }
}

@end
