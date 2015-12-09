//
//  HUDController.m
//  LrcSeeker
//
//  Created by Eru on 15/10/26.
//  Copyright © 2015年 Eru. All rights reserved.
//

#import "HUDController.h"

NSString *const LSFontSize=@"LSFontSize";
NSString *const LSFontName=@"LSFontName";

@interface HUDController ()

@end

@implementation HUDController

@synthesize textView;

-(id) init {
    self=[super initWithWindowNibName:@"HUDPreview"];
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    [[self window] setLevel:NSNormalWindowLevel];
    NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
    NSFont *font=[NSFont fontWithName:[defaults stringForKey:LSFontName] size:[defaults floatForKey:LSFontSize]];
    [textView setTextColor:[NSColor whiteColor]];
    [textView setFont:font];
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

#pragma mark - copy

-(IBAction)copy:(id)sender {
    NSPasteboard *pb=[NSPasteboard generalPasteboard];
    [pb clearContents];
    [pb writeObjects:[NSArray arrayWithObject:[textView string]]];
}

#pragma mark - Fonts

-(IBAction)showFontPanel:(id)sender {
    NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
    NSFontManager *fontManager=[NSFontManager sharedFontManager];
    NSFontPanel *fontPanel=[NSFontPanel sharedFontPanel];
    [fontManager setTarget:self];
    [fontManager setSelectedFont:[NSFont fontWithName:[defaults stringForKey:LSFontName] size:[defaults floatForKey:LSFontSize]] isMultiple:NO];
    [fontPanel makeKeyAndOrderFront:self];
    [fontPanel setDelegate:self];
}

-(void)changeFont:(id)sender {
    NSFont *font=[NSFont userFontOfSize:10];
    font=[sender convertFont:font];
    NSLog(@"set font:%@",font);
    NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
    [defaults setObject:[font fontName] forKey:LSFontName];
    [defaults setObject:[NSNumber numberWithFloat:[font pointSize]] forKey:LSFontSize];
    [textView setFont:font];
    
}

- (NSUInteger)validModesForFontPanel:(NSFontPanel *)fontPanel
{
    return  NSFontPanelSizeModeMask | NSFontPanelCollectionModeMask | NSFontPanelFaceModeMask;
}

@end
