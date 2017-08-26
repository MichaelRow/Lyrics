//
//  VOXBridge.h
//  LyricX
//
//  Created by Eru on 2017/3/17.
//  Copyright © 2017年 Eru. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VOXBridge : NSObject

-(BOOL) running;
-(BOOL) playing;

-(NSString *) title;
-(NSString *) artist;
-(NSString *) album;
-(NSString *) uniqueID;
-(NSInteger) playerPosition;
-(NSData *) artwork;
-(NSInteger) playerState;

@end
