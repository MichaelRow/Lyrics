//
//  XMLParserForQianQian.h
//  LrcSeeker
//
//  Created by Eru on 15/11/21.
//  Copyright © 2015年 Eru. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SongInfos.h"

@interface XMLParserForQianQian : NSObject <NSXMLParserDelegate> {
    @private
    NSMutableArray *resultArray;
}

-(NSArray *)arrayWithData: (NSData *)data;

@end
