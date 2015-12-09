//
//  ErrorWindow.h
//  LrcSeeker
//
//  Created by Eru on 15/11/1.
//  Copyright © 2015年 Eru. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ErrorView.h"

@interface ErrorWindow : NSWindow

- (void)fadeInAndMakeKeyAndOrderFront:(BOOL)orderFront;

- (void)fadeOutAndOrderOut:(BOOL)orderOut;

- (void)setStringValue:(NSString*)str;

@end
