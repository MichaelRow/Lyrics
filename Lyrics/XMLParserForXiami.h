//
//  XMLParserForXiami.h
//  LrcSeeker
//
//  Created by Eru on 15/10/20.
//  Copyright © 2015年 Eru. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XMLParserForXiami : NSObject <NSXMLParserDelegate> {
    NSMutableString *currentString;
    NSMutableDictionary *currentField;
}

-(NSDictionary*)dictionaryWithData:(NSData *) theData;

@end
