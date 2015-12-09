//
//  PreferencesController.h
//  LrcSeeker
//
//  Created by Eru on 15/10/22.
//  Copyright © 2015年 Eru. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PreferencesController : NSWindowController {
    
    NSUserDefaults *defaults;
    
    IBOutlet NSPopUpButton *lrcPathButton;
    IBOutlet NSPopUpButton *artworkPathButton;

}

@end
