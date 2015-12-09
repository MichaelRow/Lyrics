//
//  XMLParserForXiami.m
//  LrcSeeker
//
//  Created by Eru on 15/10/20.
//  Copyright © 2015年 Eru. All rights reserved.
//

#import "XMLParserForXiami.h"

@implementation XMLParserForXiami

-(NSDictionary *)dictionaryWithData:(NSData *)theData {
    NSXMLParser *parser=[[NSXMLParser alloc]initWithData:theData];
    [parser setDelegate:self];
    BOOL success=[parser parse];
    if (!success) {
        NSLog(@"%@",[parser parserError]);
        return nil;
    }
    return currentField;
}

#pragma mark - NSXMLParserDelegate

-(void)parser:(NSXMLParser *)parser didStartElement:(nonnull NSString *)elementName namespaceURI:(nullable NSString *)namespaceURI qualifiedName:(nullable NSString *)qName attributes:(nonnull NSDictionary<NSString *,NSString *> *)attributeDict {
    if ([elementName isEqualToString:@"track"]) {
        currentField=[[NSMutableDictionary alloc]init];
    }
}

-(void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
    if (currentField && currentString) {
        NSString *trimmed;
        if ([elementName isEqualToString:@"lyric"]) {
            trimmed=[currentString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            [currentField setObject:trimmed forKey:@"lyricURL"];
        }
        else if ([elementName isEqualToString:@"album_pic"]) {
            trimmed=[currentString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            [currentField setObject:trimmed forKey:@"artWorkURL"];
        }
    }
    currentString=nil;
}

-(void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    if (!currentString) {
        currentString=[[NSMutableString alloc]init];
    }
    [currentString appendString:string];
}

@end
