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
            LyricsAutoLaunches : NSNumber(bool: true),
            LyricsLaunchTpyePopUpIndex : NSNumber(integer: 2),
            LyricsAutoConvertChinese : NSNumber(bool: false),
            LyricsChineseTypeIndex : NSNumber(integer: 0),
            LyricsQuitWithITunes : NSNumber(bool: false),
            LyricsDisabledWhenPaused : NSNumber(bool: true),
            LyricsDisabledWhenSreenShot : NSNumber(bool: true),
            LyricsShadowModeEnable : NSNumber(bool: true),
            LyricsIsVerticalLyrics : NSNumber(bool: false),
            LyricsVerticalLyricsPosition : NSNumber(integer: 1),
            LyricsTwoLineMode : NSNumber(bool: true),
            LyricsSearchForBetterLrc : NSNumber(bool: true),
            LyricsDisableAllAlert : NSNumber(bool: false),
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
        
        let lyricsXHelpers = NSRunningApplication.runningApplicationsWithBundleIdentifier("Eru.LyricsX-Helper")
        for helper in lyricsXHelpers {
            helper.terminate()
        }
        
        applicationController = AppController()
    }
    
    func applicationWillTerminate(aNotification: NSNotification) {
        if applicationController.timeDly != applicationController.timeDlyInFile {
            NSLog("App terminating, saveing lrc time delay change...")
            applicationController.handleLrcDelayChange()
        }
        
        let userDefaults = NSUserDefaults.standardUserDefaults()
        if userDefaults.boolForKey(LyricsAutoLaunches) {
            if userDefaults.integerForKey(LyricsLaunchTpyePopUpIndex) != 0 {
                let helperPath = NSBundle.mainBundle().bundlePath + "/Contents/Library/LoginItems/LyricsX Helper.app"
                NSWorkspace.sharedWorkspace().launchApplication(helperPath)
            }
        }
        
        //Terminate LrcSeeker
        let lrcSeekers = NSRunningApplication.runningApplicationsWithBundleIdentifier("Eru.LrcSeeker")
        for ls in lrcSeekers {
            ls.terminate()
        }
    }

}

