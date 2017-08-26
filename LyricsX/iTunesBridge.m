//
//  iTunesBridge.m
//  LyricX
//
//  Created by Eru on 2017/3/17.
//  Copyright © 2017年 Eru. All rights reserved.
//

#import "iTunesBridge.h"
#import "iTunes.h"

@interface iTunesBridge ()

@property (nonatomic,strong) iTunesApplication *iTunes;

@end

@implementation iTunesBridge

-(instancetype)init {
    self = [super init];
    if (self) {
        _iTunes = [SBApplication applicationWithBundleIdentifier:@"com.apple.iTunes"];
    }
    return _iTunes? self : nil;
}


-(BOOL) running {
    @autoreleasepool {
        return _iTunes.isRunning;
    }
}

-(BOOL) playing {
    @autoreleasepool {
        return (_iTunes.playerState == iTunesEPlSPlaying);
    }
}

-(NSString *) title {
    @autoreleasepool {
        NSString *title = _iTunes.currentTrack.name;
        if (!title) {
            title = @"";
        }
        return title;
    }
}

-(NSString *) artist {
    @autoreleasepool {
        NSString *artist = _iTunes.currentTrack.artist;
        if (!artist) {
            artist = @"";
        }
        return artist;
    }
}

-(NSString *) album {
    @autoreleasepool {
        NSString *album = _iTunes.currentTrack.album;
        if (!album) {
            album = @"";
        }
        return album;
    }
}

-(NSString *) persistentID {
    @autoreleasepool {
        NSString *persistentID = _iTunes.currentTrack.persistentID;
        if (!persistentID) {
            persistentID = @"";
        }
        return persistentID;
    }
}

-(NSInteger) playerPosition {
    @autoreleasepool {
        return (NSInteger)(_iTunes.playerPosition * 1000);
    }
}

-(NSData *) artwork {
    @autoreleasepool {
        SBElementArray* theArtworks = [[_iTunes currentTrack] artworks];
        if ([theArtworks count] > 0) {
            iTunesArtwork *artwork = [theArtworks objectAtIndex:0];
            return [artwork rawData];
        } else {
            return nil;
        }
    }
}

-(NSInteger) playerState {
    @autoreleasepool {
        
        iTunesEPlS state = _iTunes.playerState;
        switch (state) {
            case iTunesEPlSPlaying:
                return 1;
            case iTunesEPlSPaused:
                return 2;
            case iTunesEPlSStopped:
                return 3;
            default:
                return 0;
        }
    }
}

-(void) setLyrics: (NSString *)lyrics {
    if (!lyrics) return;
    @autoreleasepool {
        _iTunes.currentTrack.lyrics = lyrics;
    }
}

-(void) play {
    @autoreleasepool {
        if (_iTunes.playerState != iTunesEPlSPlaying) {
            [_iTunes playpause];
        }
    }
}

-(void) pause {
    @autoreleasepool {
        [_iTunes pause];
    }
}

@end
