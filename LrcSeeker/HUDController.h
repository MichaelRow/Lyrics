//
//  HUDController.h
//  LrcSeeker
//
//  Created by Eru on 15/10/26.
//  Copyright © 2015年 Eru. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern NSString *const LSFontName;
extern NSString *const LSFontSize;

@interface HUDController : NSWindowController <NSWindowDelegate>


@property IBOutlet NSTextView *textView;

-(IBAction)showFontPanel:(id)sender;
-(IBAction)copy:(id)sender;

@end
