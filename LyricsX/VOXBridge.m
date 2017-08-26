//
//  VOXBridge.m
//  LyricX
//
//  Created by Eru on 2017/3/17.
//  Copyright © 2017年 Eru. All rights reserved.
//

#import "VOXBridge.h"
#import "VOX.h"

@interface VOXBridge ()

@property(nonatomic,strong) VOXApplication *vox;

@end

@implementation VOXBridge

- (instancetype)init {
    self = [super init];
    if (self) {
        _vox = [SBApplication applicationWithBundleIdentifier:@"com.coppertino.Vox"];
    }
    return _vox? self : nil;
}

-(BOOL) running {
    @autoreleasepool {
       return _vox.isRunning;
    }
}

-(BOOL) playing {
    @autoreleasepool {
        return (_vox.playerState == 1);
    }
}

-(NSString *) title {
    @autoreleasepool {
        NSString *title = _vox.track;
        return title? title : @"";
    }
}

-(NSString *) artist {
    @autoreleasepool {
        NSString *artist = _vox.artist;
        return artist? artist : @"";
    }
}

-(NSString *) album {
    @autoreleasepool {
        NSString *album = _vox.album;
        return album? album : @"";
    }
}

-(NSString *) uniqueID {
    @autoreleasepool {
        NSString *uniqueID = _vox.uniqueID;
        return uniqueID? uniqueID : @"";
    }
}

-(NSInteger) playerPosition {
    @autoreleasepool {
        return (NSInteger)(_vox.currentTime * 1000);
    }
}

-(NSData *) artwork {
    @autoreleasepool {
        return _vox.tiffArtworkData;
    }
}

-(NSInteger) playerState {
    @autoreleasepool {
        if (!_vox.isRunning) {
            return 0;
        } else if (_vox.playerState == 1) {
            return 1;
        } else {
            return 2;
        }
    }
}

@end
