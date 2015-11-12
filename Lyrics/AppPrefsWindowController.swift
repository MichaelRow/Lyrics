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
    @IBOutlet var fontPrefsView: NSView!
    
    override func setupToolbar () {
        self.addView(generalPrefsView, label: "General", image: NSImage(named: "general_icon"))
        self.addView(lyricsPrefsView, label: "Lyrics", image: NSImage(named: "lyrics_icon"))
        self.addView(fontPrefsView, label: "Font", image: NSImage(named: "font_icon"))
        self.addFlexibleSpacer()
        self.addView(donateView, label: "Donate", image: NSImage(named: "donate_icon"))
        self.crossFade=true
        self.shiftSlowsAnimation=true
    }
}
