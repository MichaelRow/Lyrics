//
//  StatusMenuController.swift
//  LyricX
//
//  Created by Eru on 2017/3/17.
//  Copyright © 2017年 Eru. All rights reserved.
//

import Cocoa

class StatusMenuController {
    
    private var statusItem: NSStatusItem?
    
    @IBOutlet weak var statusMenu: NSMenu!
    @IBOutlet weak var presetMenuItem: NSMenuItem!
    @IBOutlet weak var lyricHeightMenuItem: NSMenuItem!
    @IBOutlet weak var delayMenuItem: NSMenuItem!
    @IBOutlet weak var lyricDelayView: NSView!
    
    init() {
        
    }
    
    func setupStatusMenu() {
        Bundle(for: object_getClass(self)!).loadNibNamed(NSNib.Name(rawValue: "StatusMenu"), owner: self, topLevelObjects: nil)
        lyricDelayView.autoresizingMask = [NSView.AutoresizingMask.width]
        delayMenuItem.view = lyricDelayView;
        
        //添加到状态栏
        let icon = #imageLiteral(resourceName: "StatusLyrics")
        icon.isTemplate = true
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem?.menu = statusMenu
        statusItem?.button?.image = icon
    }
}
