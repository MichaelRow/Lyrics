//
//  SongListView.h
//  LrcSeeker
//
//  Created by Eru on 15/10/26.
//  Copyright © 2015年 Eru. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol ContextMenuDelegate <NSObject>

- (NSMenu*)tableView:(NSTableView*)aTableView menuForRows:(NSIndexSet*)rows;

@end

@interface SongListView : NSTableView

@end
