//
//  VoxBridge.h
//  Lyrics
//
//  Created by Eru on 15/12/31.
//  Copyright © 2015年 Eru. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VoxBridge : NSObject

-(BOOL) running;
-(BOOL) playing;

-(NSString *) currentTitle;
-(NSString *) currentArtist;
-(NSString *) currentPersistentID;
-(NSInteger) playerPosition;

@end
