//
//  SongListView.m
//  LrcSeeker
//
//  Created by Eru on 15/10/26.
//  Copyright © 2015年 Eru. All rights reserved.
//

#import "SongListView.h"

@implementation SongListView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

- (NSMenu*)menuForEvent:(NSEvent*)event
{
    NSPoint location = [self convertPoint:[event locationInWindow] fromView:nil];
    NSInteger row = [self rowAtPoint:location];
    if (!(row >= 0) || ([event type] != NSRightMouseDown)) {
        return [super menuForEvent:event];
    }
    NSIndexSet *selected = [self selectedRowIndexes];
    if (![selected containsIndex:row]) {
        selected = [NSIndexSet indexSetWithIndex:row];
        [self selectRowIndexes:selected byExtendingSelection:NO];
    }
    if ([[self delegate] respondsToSelector:@selector(tableView:menuForRows:)]) {
        return [(id)[self delegate] tableView:self menuForRows:selected];
    }
    return [super menuForEvent:event];
}

@end
