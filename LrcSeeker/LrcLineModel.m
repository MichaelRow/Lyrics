//
//  LrcLineModel.m
//  LrcParser
//
//  Created by Eru on 15/10/29.
//  Copyright © 2015年 Eru. All rights reserved.
//

#import "LrcLineModel.h"

@implementation LrcLineModel 

@synthesize msecPosition;
@synthesize timeTag;
@synthesize lyricSentence;

-(void)setTimeTag:(NSString *)theTimeTag {
    timeTag=theTimeTag;
    NSRange colonRange=[timeTag rangeOfString:@":"];
    
    NSString *minuteStr=[timeTag substringWithRange:NSMakeRange(1, colonRange.location-1)];
    NSString *secondStr=[timeTag substringWithRange:NSMakeRange(colonRange.location+1, [timeTag length]-colonRange.length-colonRange.location-1)];
    int minute=[minuteStr intValue];
    float second=[secondStr floatValue];
    msecPosition=(int)(minute*60*1000+second*1000);
}

@end
