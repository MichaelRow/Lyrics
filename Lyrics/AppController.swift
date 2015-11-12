//
//  AppController.swift
//  Lyrics
//
//  Created by Eru on 15/11/10.
//  Copyright © 2015年 Eru. All rights reserved.
//

import Cocoa
import ScriptingBridge

class AppController: NSObject {
    
    @IBOutlet weak var statusBarMenu: NSMenu!
    @IBOutlet weak var lyricsDelayView: NSView!
    @IBOutlet weak var delayMenuItem: NSMenuItem!
    
    var isTrackingRunning:Bool = false
    var lyricsWindow:LyricsWindowController!
    var statusBarItem:NSStatusItem!
    var lyrics:NSMutableArray!
    var operationQueue:NSOperationQueue!
    var iTunesSBA:SBApplication!
    var iTunes:iTunesApplication!
    var iTunesCurrentTrack:NSString!
    
    override init() {
        
        super.init()
        
        iTunesSBA = SBApplication(bundleIdentifier: "com.apple.iTunes")
        iTunes = iTunesSBA as iTunesApplication
        lyrics = NSMutableArray()
        
        NSBundle(forClass: object_getClass(self)).loadNibNamed("StatusMenu", owner: self, topLevelObjects: nil)
        setupStatusItem()
        
        if iTunesSBA.running == true && iTunes.playerState == iTunesEPlS.Playing {
            NSLog("Create new iTunesTrackingThead")
            isTrackingRunning = true
            iTunesCurrentTrack = (iTunes.currentTrack?.persistentID?.copy())! as! NSString
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { () -> Void in
                self.iTunesTrackingThread()
            }
        }
        
        NSDistributedNotificationCenter.defaultCenter().addObserver(self, selector: "iTunesPlayerInfoChanged:", name: "com.apple.iTunes.playerInfo", object: nil)
    }
    
    
    deinit {
        NSDistributedNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    
    func setupStatusItem() {
        let icon:NSImage=NSImage(named: "status_icon")!
        icon.template=true
        statusBarItem=NSStatusBar.systemStatusBar().statusItemWithLength(NSSquareStatusItemLength)
        statusBarItem.image=icon
        statusBarItem.highlightMode=true
        statusBarItem.menu=statusBarMenu
        lyricsWindow=LyricsWindowController()
        lyricsWindow.showWindow(self)
        delayMenuItem.view=lyricsDelayView
        lyricsDelayView.autoresizingMask=[.ViewWidthSizable]
    }
    
// MARK: - Interface Methods
    
    @IBAction func showPreferences(sender:AnyObject?) {
        let prefs = AppPrefsWindowController.sharedPrefsWindowController()
        if !(prefs.window?.visible)! {
            prefs.showWindow(nil)
        }
        prefs.window?.makeKeyAndOrderFront(nil)
        NSApp.activateIgnoringOtherApps(true)
    }
    
// MARK: - iTunes Events
    
    func iTunesTrackingThread() {
        var playerPosition: NSNumber
        // 坑爹的swift，撇开ScriptingBridge API没有swift版本不说，连Obj-C的iTunes.h在swift下都linker error
        // 自己生成了一个iTunes.swift 问题就是iTunesApplication虽说是SBApplication的子类，然而却因为swift的强
        // 类型，不能调用父类的方法，那就用两个变量吧。。。
        
        while true {
            if !iTunesSBA.running && NSUserDefaults.standardUserDefaults().boolForKey(LyricsQuitWithITunes) {
                NSApplication.sharedApplication().terminate(self)
            }
            if iTunes.playerState == iTunesEPlS.Playing {
                playerPosition = NSNumber(integer: Int(iTunes.playerPosition! * 1000))
                let dic:NSDictionary=NSDictionary(objects: ["iTunesPositionChanged", playerPosition], forKeys: ["Type", "CurrentPosition"])
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
                    self.handlingThead(dic)
                })
            }
            else {
                isTrackingRunning=false
                NSLog("Kill iTunesTrackingThread")
                return
            }
            NSThread.sleepForTimeInterval(0.15)
        }
    }
    
    
    func iTunesPlayerInfoChanged (n:NSNotification){
        let userInfo = n.userInfo
        if userInfo == nil {
            return
        }
        else {
            if userInfo!["Player State"] as! String == "Paused" {
                lyricsWindow.displayLyrics(nil, secondLyrics: nil)
                NSLog("iTunes Paused")
                return
            }
            else if userInfo!["Player State"] as! String == "Playing" {
                if !isTrackingRunning {
                    NSLog("Create new iTunesTrackingThead")
                    isTrackingRunning = true
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { () -> Void in
                        self.iTunesTrackingThread()
                    }
                }
                NSLog("iTunes Playing")
            }
            if iTunesCurrentTrack == nil {
                iTunesCurrentTrack = (iTunes.currentTrack?.persistentID?.copy())! as! NSString
                return
            }
            if iTunesCurrentTrack == iTunes.currentTrack?.persistentID {
                return
            } else {
                NSLog("Song Changed")
                iTunesCurrentTrack = (iTunes.currentTrack?.persistentID?.copy())! as! NSString
                let dic:NSDictionary = NSDictionary(objects: ["iTunesTrackChanged"], forKeys: ["Type"])
                self.handlingThead(dic)
            }
        }
    }

// MARK: - Lrc Methods
    
    func parsingLrc() {
        
    }
    
    func getLrc() {
        
    }

// MARK: - Handling Thead
    
    func handlingThead(dic:NSDictionary) {
        
    }
    
}








