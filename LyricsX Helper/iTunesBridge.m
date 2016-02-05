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

@end
