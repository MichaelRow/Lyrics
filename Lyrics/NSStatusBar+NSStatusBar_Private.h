//
//  NSStatusBar+NSStatusBar_Private.h
//  Lyrics
//
//  Created by Eru on 15/12/26.
//  Copyright © 2015年 Eru. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSStatusBar (NSStatusBar_Private)

// Apple's private API
- (NSStatusItem *)_statusItemWithLength:(float)length withPriority:(int)priority;
- (id)_insertStatusItem:(NSStatusItem *)item withPriority:(int)priority;

@end
