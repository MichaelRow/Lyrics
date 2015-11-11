//
//  Controller.swift
//  Lyrics
//
//  Created by Eru on 15/11/11.
//  Copyright © 2015年 Eru. All rights reserved.
//

import Cocoa

class AppPrefsWindowController: DBPrefsWindowController {
    
    @IBOutlet var generalPrefsView:NSView!
    @IBOutlet var lyricsPrefsView:NSView!
    @IBOutlet var donateView:NSView!
    
    override func setupToolbar () {
        self.addView(generalPrefsView, label: "General", image: NSImage(named: "General"))
        self.addView(lyricsPrefsView, label: "Lyrics", image: NSImage(named: "Lyrics"))
        self.addFlexibleSpacer()
        self.addView(donateView, label: "Donate", image: NSImage(named: "Donate"))
        self.crossFade=true
        self.shiftSlowsAnimation=true
    }
}
