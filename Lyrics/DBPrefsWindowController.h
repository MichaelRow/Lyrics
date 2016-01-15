//
//  DBPrefsWindowController.h
//
//  Created by Dave Batton
//  http://www.Mere-Mortal-Software.com/blog/
//
//  Updated by David Keegan
//  https://github.com/kgn/DBPrefsWindowController
//
//  Copyright 2007. Some rights reserved.
//  This work is licensed under a Creative Commons license:
//  http://creativecommons.org/licenses/by/3.0/
//
//  Modified by MichaelRow for needs of LyricsX on 1.12.2016

#import <Cocoa/Cocoa.h>

@interface DBPrefsWindowController : NSWindowController

@property (nonatomic) BOOL crossFade;
@property (nonatomic) BOOL shiftSlowsAnimation;

- (void)setupToolbar;
- (void)addFlexibleSpacer;
- (void)addView:(NSView *)view label:(NSString *)label;
- (void)addView:(NSView *)view label:(NSString *)label image:(NSImage *)image;

- (void)toggleActivePreferenceView:(NSToolbarItem *)toolbarItem;
- (void)displayViewForIdentifier:(NSString *)identifier animate:(BOOL)animate;
- (void)crossFadeView:(NSView *)oldView withView:(NSView *)newView;
- (NSRect)frameForView:(NSView *)view;

// select both the view & toolbar item for the given identifier
- (void)loadViewForIdentifier:(NSString *)identifier animate:(BOOL)animate;

@end
