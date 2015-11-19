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
            LyricsAutoConvertChinese : NSNumber(bool: false),
            LyricsChineseTypeIndex : NSNumber(integer: 0),
            LyricsQuitWithITunes : NSNumber(bool: false),
            LyricsDisabledWhenPaused : NSNumber(bool: true),
            LyricsDisabledWhenSreenShot : NSNumber(bool: true),
            LyricsShadowModeEnable : NSNumber(bool: true),
            LyricsTwoLineMode : NSNumber(bool: true),
            LyricsSearchForBetterLrc : NSNumber(bool: true),
            LyricsDisplayInAllSpaces: NSNumber(bool: true),
            LyricsUseAutoLayout : NSNumber(bool: true),
            LyricsHeightFromDockToLyrics : NSNumber(integer: 15),
            LyricsConstToLeft : NSNumber(integer: 50),
            LyricsConstToBottom : NSNumber(integer: 100),
            LyricsConstWidth : NSNumber(integer: 1000),
            LyricsConstHeight : NSNumber(integer: 60),
            LyricsFontName : "HannotateSC-W7",
            LyricsFontSize : NSNumber(float: 36),
            LyricsTextColor : NSKeyedArchiver.archivedDataWithRootObject(NSColor.whiteColor()),
            LyricsBackgroundColor : NSKeyedArchiver.archivedDataWithRootObject(NSColor(calibratedWhite: 0, alpha: 0.5)),
            LyricsShadowColor : NSKeyedArchiver.archivedDataWithRootObject(NSColor.yellowColor()),
            LyricsShadowRadius : NSNumber(float: 4)
        ]
        
        NSUserDefaults.standardUserDefaults().registerDefaults(userDefaults)
        
        NSColorPanel.sharedColorPanel().showsAlpha = true
        
        applicationController = AppController()
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }

}

