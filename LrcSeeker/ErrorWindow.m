//
//  ErrorWindow.m
//  LrcSeeker
//
//  Created by Eru on 15/11/1.
//  Copyright © 2015年 Eru. All rights reserved.
//

#import "ErrorWindow.h"

@implementation ErrorWindow

- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)windowStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)deferCreation {
    
    if (self = [super initWithContentRect:contentRect
                                styleMask:NSBorderlessWindowMask
                                  backing:NSBackingStoreBuffered defer:deferCreation]) {
        [self setBackgroundColor:[NSColor clearColor]];
    }
    self.ignoresMouseEvents = YES;
    return self;
}

- (void)setStringValue:(NSString *)str {
    ErrorView *errorView=(ErrorView *)[self contentView];
    [errorView setString:str];
}

- (void)fadeInAndMakeKeyAndOrderFront:(BOOL)orderFront {
    [self setAlphaValue:0.0];
    if (orderFront) {
        [self makeKeyAndOrderFront:nil];
    }
    [[self animator] setAlphaValue:1.0];
}

- (void)fadeOutAndOrderOut:(BOOL)orderOut {
    if (orderOut) {
        NSTimeInterval delay = [[NSAnimationContext currentContext] duration] + 0.1;
        [self performSelector:@selector(orderOut:) withObject:nil afterDelay:delay];
    }
    [[self animator] setAlphaValue:0.0];
}

@end
