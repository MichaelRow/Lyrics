//
//  LrcLineModel.h
//  LrcParser
//
//  Created by Eru on 15/10/29.
//  Copyright © 2015年 Eru. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LrcLineModel : NSObject

@property int msecPosition;
@property (nonatomic,copy)NSString *lyricSentence;
@property (nonatomic,copy) NSString *timeTag;

@end
