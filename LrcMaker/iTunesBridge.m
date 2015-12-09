//
//  iTunesBridge.m
//  Lyrics
//
//  Created by Eru on 15/11/16.
//  Copyright © 2015年 Eru. All rights reserved.
//

#import "iTunesBridge.h"

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

-(NSString *) currentAlbum {
    @autoreleasepool {
        NSString *album = iTunes.currentTrack.album;
        if (!album) {
            album = @"";
        }
        return album;
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

-(void) pause {
    @autoreleasepool {
        if (iTunes.isRunning && iTunes.playerState == iTunesEPlSPlaying) {
            [iTunes pause];
        }
    }
}

@end
