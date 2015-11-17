//
//  AppDelegate.swift
//  Lyrics
//
//  Created by Eru on 15/11/6.
//  Copyright © 2015年 Eru. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    var applicationController: AppController!
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        
        let userSavingPath: NSString = NSSearchPathForDirectoriesInDomains(.DownloadsDirectory, [.UserDomainMask], true).first! 
        
        let userDefaults: [String:AnyObject] = [
            LyricsSavingPathPopUpIndex : NSNumber(integer: 0),
            LyricsUserSavingPath : userSavingPath,
            LyricsQuitWithITunes : NSNumber(bool: false),
            LyricsDisabledWhenPaused : NSNumber(bool: true),
            LyricsDisabledWhenSreenShot : NSNumber(bool: true),
            LyricsShadowModeEnable : NSNumber(bool: true),
            LyricsTwoLineMode : NSNumber(bool: false),
            LyricsSearchForBetterLrc : NSNumber(bool: true),
            LyricsDisplayInAllSpaces: NSNumber(bool: true),
            LyricsUseAutoLayout : NSNumber(bool: true),
            LyricsHeightFromDockToLyrics : NSNumber(integer: 25),
            LyricsConstToLeft : NSNumber(integer: 50),
            LyricsConstToBottom : NSNumber(integer: 70),
            LyricsConstWidth : NSNumber(integer: 1000),
            LyricsConstHeight : NSNumber(integer: 100),
            LyricsFontName : "Helvetica",
            LyricsFontSize : NSNumber(integer: 36),
            LyricsTextColor : NSKeyedArchiver.archivedDataWithRootObject(NSColor.redColor()),
            LyricsBackgroundColor : NSKeyedArchiver.archivedDataWithRootObject(NSColor.blackColor()),
            LyricsShadowColor : NSKeyedArchiver.archivedDataWithRootObject(NSColor.yellowColor()),
            LyricsShadowRadius : NSNumber(integer: 2)
        ]
        
        NSUserDefaults.standardUserDefaults().registerDefaults(userDefaults)
        
        applicationController = AppController()
        
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }

}

