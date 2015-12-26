//
//  MenuBarLyrics.swift
//  Lyrics
//
//  Created by Eru on 15/12/24.
//  Copyright © 2015年 Eru. All rights reserved.
//

import Cocoa

class MenuBarLyrics: NSObject {
    
    let attrs: [String:AnyObject]
    var statusItem: NSStatusItem!
    
    override init() {
        attrs = [NSFontNameAttribute : NSFont(name: "HiraginoSansGB-W3", size: 15)!,
                 NSForegroundColorAttributeName : NSColor.blackColor()]
        super.init()
        statusItem = NSStatusBar.systemStatusBar()._statusItemWithLength(0, withPriority: 0)
        statusItem.length = NSVariableStatusItemLength
        statusItem.highlightMode = false
    }
    
    deinit {
        NSStatusBar.systemStatusBar().removeStatusItem(statusItem)
        NSLog("Deint StatusBarLyrics")
    }
    
    func displayLyrics(lyrics: String?) {
        if #available(OSX 10.10, *) {
            if lyrics == nil {
                statusItem.button?.title = ""
            } else {
                statusItem.button?.title = lyrics!
            }
        } else {
            if lyrics == nil {
                statusItem.title = ""
            } else {
                statusItem.title = lyrics!
            }
        }
    }
}
