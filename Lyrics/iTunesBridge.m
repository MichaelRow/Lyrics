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
        return iTunes.currentTrack.name;
    }
}

-(NSString *) currentArtist {
    @autoreleasepool {
        return iTunes.currentTrack.artist;
    }
}

-(NSString *) currentPersistentID {
    @autoreleasepool {
        return iTunes.currentTrack.persistentID;
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

@end
