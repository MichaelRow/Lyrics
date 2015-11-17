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
    @IBOutlet weak var savingPathPopUp: NSPopUpButton!
    
    override func setupToolbar () {
        self.addView(generalPrefsView, label: "General", image: NSImage(named: "general_icon"))
        self.addView(lyricsPrefsView, label: "Lyrics", image: NSImage(named: "lyrics_icon"))
        self.addView(donateView, label: "Donate", image: NSImage(named: "donate_icon"))
        self.crossFade=true
        self.shiftSlowsAnimation=true
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
        let defaultSavingPath: String = NSSearchPathForDirectoriesInDomains(.MusicDirectory, [.UserDomainMask], true).first! + "/LyricsX"
        let userSavingPath: NSString = NSUserDefaults.standardUserDefaults().stringForKey(LyricsUserSavingPath)!
        savingPathPopUp.itemAtIndex(0)?.toolTip = defaultSavingPath
        savingPathPopUp.itemAtIndex(1)?.toolTip = userSavingPath as String
        savingPathPopUp.itemAtIndex(1)?.title = userSavingPath.lastPathComponent
    }
    
    @IBAction func changeSavingPath(sender: AnyObject) {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.beginSheetModalForWindow(self.window!) { (result) -> Void in
            if result == NSFileHandlingPanelOKButton {
                let newPath: NSString = (openPanel.URL?.path)!
                let userDefaults = NSUserDefaults.standardUserDefaults()
                userDefaults.setObject(newPath, forKey: LyricsUserSavingPath)
                userDefaults.setObject(NSNumber(integer: 1), forKey: LyricsSavingPathPopUpIndex)
                self.savingPathPopUp.itemAtIndex(1)?.title = newPath.lastPathComponent
                self.savingPathPopUp.itemAtIndex(1)?.toolTip = newPath as String
            }
        }
    }
    
}
