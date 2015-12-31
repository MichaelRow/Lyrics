//
//  VoxBridge.m
//  Lyrics
//
//  Created by Eru on 15/12/31.
//  Copyright © 2015年 Eru. All rights reserved.
//

#import "VoxBridge.h"
#import "Vox.h"

@implementation VoxBridge {
    VoxApplication *vox;
}

-(id)init {
    self = [super init];
    if (self) {
        vox = [SBApplication applicationWithBundleIdentifier:@"com.coppertino.Vox"];
    }
    return self;
}

-(BOOL) running {
    @autoreleasepool {
        return vox.isRunning;
    }
}

-(BOOL) playing {
    @autoreleasepool {
        return (vox.playerState == 1);
    }
}

-(NSString *) currentTitle {
    @autoreleasepool {
        NSString *title = vox.track;
        if (!title) {
            title = @"";
        }
        return title;
    }
}

-(NSString *) currentArtist {
    @autoreleasepool {
        NSString *artist = vox.artist;
        if (!artist) {
            artist = @"";
        }
        return artist;
    }
}

-(NSString *) currentPersistentID {
    @autoreleasepool {
        NSString *persistentID = vox.uniqueID;
        if (!persistentID) {
            persistentID = @"";
        }
        return persistentID;
    }
}

-(NSInteger) playerPosition {
    @autoreleasepool {
        return (NSInteger)(vox.currentTime * 1000);
    }
}

@end
