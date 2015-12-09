//
//  ErrorView.m
//  LrcSeeker
//
//  Created by Eru on 15/10/31.
//  Copyright © 2015年 Eru. All rights reserved.
//

#import "ErrorView.h"

@implementation ErrorView {
    NSMutableDictionary *attributes;
}

@synthesize string;

- (id) initWithCoder:(NSCoder *)coder {
    self=[super initWithCoder:coder];
    if (self) {
        string=@"";
        attributes=[NSMutableDictionary dictionary];
        [attributes setObject:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
        NSFont* font=[NSFont userFontOfSize:17];
        [attributes setObject:font forKey:NSFontAttributeName];
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect {
    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:dirtyRect xRadius:20.0 yRadius:20.0];
    NSColor *color = [[NSColor blackColor] colorWithAlphaComponent:0.65];
    [color set];
    [path fill];
    [[NSColor whiteColor] set];
    NSSize strSize=[string sizeWithAttributes:attributes];
    NSPoint strOrigin;
    strOrigin.x=self.bounds.origin.x+(self.bounds.size.width-strSize.width)/2;
    strOrigin.y=self.bounds.origin.y+(self.bounds.size.height-strSize.height)/2;
    [string drawAtPoint:strOrigin withAttributes:attributes];
}

-(void)setString:(NSString *)theString {
    string=theString;
    [self setNeedsDisplay:YES];
}

@end
