//
//  AppController.swift
//  Lyrics
//
//  Created by Eru on 15/11/10.
//  Copyright © 2015年 Eru. All rights reserved.
//

import Cocoa

class AppController: NSObject {
    
    @IBOutlet weak var statusBarMenu: NSMenu!
    @IBOutlet weak var lyricsDelayView: NSView!
    @IBOutlet weak var delayMenuItem: NSMenuItem!
    
    var lyricsWindow:LyricsWindowController!
    var statusBarItem:NSStatusItem!
    var lyrics:NSMutableArray!
    
    override init() {
        super.init()
        NSBundle(forClass: object_getClass(self)).loadNibNamed("StatusMenu", owner: self, topLevelObjects: nil)
        let icon:NSImage=NSImage(named: "status_icon")!
        icon.template=true
        statusBarItem=NSStatusBar.systemStatusBar().statusItemWithLength(NSSquareStatusItemLength)
        statusBarItem.image=icon
        statusBarItem.highlightMode=true
        statusBarItem.menu=statusBarMenu
        lyricsWindow=LyricsWindowController()
        lyricsWindow.showWindow(self)
        if delayMenuItem == nil {
            print(111)
        }
        delayMenuItem.view=lyricsDelayView
        lyricsDelayView.autoresizingMask=[.ViewWidthSizable]
        
        lyrics = NSMutableArray()
        NSDistributedNotificationCenter.defaultCenter().addObserver(self, selector: "iTunesPlayStateChanged:", name: "com.apple.iTunes.playerInfo", object: nil)
    }
    
    deinit {
        NSDistributedNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    @IBAction func showPreferences(sender:AnyObject?) {
        let prefs = AppPrefsWindowController.sharedPrefsWindowController()
        if !(prefs.window?.visible)! {
            prefs.showWindow(nil)
        }
        prefs.window?.makeKeyAndOrderFront(nil)
        NSApp.activateIgnoringOtherApps(true)
    }
    
    func iTunesTrackingThread() {
        
    }
    
    func parsingLrc() {
        
    }
    
    func downloadLrc() {
        
    }
    
    func iTunesPlayStateChanged (n:NSNotification){
        
    }
    
}
