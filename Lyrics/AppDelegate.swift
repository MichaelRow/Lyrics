//
//  AppDelegate.swift
//  Lyrics
//
//  Created by Eru on 15/11/6.
//  Copyright © 2015年 Eru. All rights reserved.
//

import Cocoa
import ServiceManagement

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        let userSavingPath: NSString = NSSearchPathForDirectoriesInDomains(.DownloadsDirectory, [.UserDomainMask], true).first! 
        
        // Filter
        let directFilterData = generateDirectFilterData()
        let conditionalFilterData = generateConditionalFilterData()
        
        let registerDefaultsDic: [String:AnyObject] = [
            //Menu
            LyricsDesktopLyricsEnabled : NSNumber(bool: true),
            LyricsMenuBarLyricsEnabled : NSNumber(bool: false),
            LyricsIsVerticalLyrics : NSNumber(bool: false),
            
            //General Preferences Defaults
            LyricsSavingPathPopUpIndex : NSNumber(integer: 0),
            LyricsUserSavingPath : userSavingPath,
            LyricsAutoLaunches : NSNumber(bool: true),
            LyricsLaunchTpyePopUpIndex : NSNumber(integer: 2),
            LyricsServerIndex : NSNumber(integer: 0),
            LyricsQuitWithITunes : NSNumber(bool: false),
            LyricsDisableAllAlert : NSNumber(bool: false),
            LyricsUseAutoLayout : NSNumber(bool: true),
            LyricsHeightFromDockToLyrics : NSNumber(integer: 10),
            LyricsConstWidth : NSNumber(integer: 1000),
            LyricsConstHeight : NSNumber(integer: 60),
            
            //Lyrics Preferences Defaults
            LyricsAutoConvertChinese : NSNumber(bool: false),
            LyricsVerticalLyricsPosition : NSNumber(integer: 1),
            LyricsChineseTypeIndex : NSNumber(integer: 0),
            LyricsTwoLineMode : NSNumber(bool: true),
            LyricsTwoLineModeIndex : NSNumber(integer: 0),
            LyricsDisabledWhenPaused : NSNumber(bool: true),
            LyricsDisabledWhenSreenShot : NSNumber(bool: true),
            LyricsSearchForDiglossiaLrc : NSNumber(bool: true),
            LyricsDisplayInAllSpaces: NSNumber(bool: true),
            
            //Font and Color Preferences Defaults
            LyricsFontName : "HannotateSC-W7",
            LyricsFontSize : NSNumber(float: 26),
            LyricsShadowModeEnable : NSNumber(bool: true),
            LyricsTextColor : NSKeyedArchiver.archivedDataWithRootObject(NSColor.whiteColor()),
            LyricsBackgroundColor : NSKeyedArchiver.archivedDataWithRootObject(NSColor(calibratedWhite: 0, alpha: 0.5)),
            LyricsShadowColor : NSKeyedArchiver.archivedDataWithRootObject(NSColor.orangeColor()),
            LyricsShadowRadius : NSNumber(float: 2),
            LyricsBgHeightINCR : NSNumber(float: 0),
            LyricsYOffset : NSNumber(float: 0),
            
            //Filter Preferences Defaults
            LyricsDirectFilterKey : directFilterData,
            LyricsConditionalFilterKey : conditionalFilterData,
            LyricsEnableFilter : NSNumber(bool: false),
            LyricsEnableSmartFilter : NSNumber(bool: true)
        ]
        
        let userDefaults = NSUserDefaults.standardUserDefaults()

        userDefaults.registerDefaults(registerDefaultsDic)
        
        let lyricsXHelpers = NSRunningApplication.runningApplicationsWithBundleIdentifier("Eru.LyricsX-Helper")
        for helper in lyricsXHelpers {
            helper.forceTerminate()
        }
        
        // Force singleton to init
        AppController.sharedController
        
        // Force Prefs to load presets
        let prefs = AppPrefsWindowController.sharedPrefsWindowController
        prefs.showWindow(nil)
        prefs.window?.close()
        
        //Check if login item hasn't be enabled
        let identifier: String = "Eru.LyricsX-Helper"
        if userDefaults.boolForKey(LyricsAutoLaunches) {
            if !SMLoginItemSetEnabled(identifier, true) {
                NSLog("Failed to enable login item")
            }
        }
        
        NSColorPanel.sharedColorPanel().showsAlpha = true
    }
    
    func applicationWillTerminate(aNotification: NSNotification) {
        
        //Save time delay
        let appController = AppController.sharedController
        if appController.timeDly != appController.timeDlyInFile {
            NSLog("App terminating, saveing lrc time delay change...")
            appController.handleLrcDelayChange()
        }
        
        //Terminate LrcSeeker
        let lrcSeekers = NSRunningApplication.runningApplicationsWithBundleIdentifier("Eru.LrcSeeker")
        for ls in lrcSeekers {
            ls.terminate()
        }
        
        let userDefaults = NSUserDefaults.standardUserDefaults()
        
        //Save window state in constant layout mode
        if !userDefaults.boolForKey(LyricsUseAutoLayout) {
            DesktopLyricsController.sharedController.storeWindowSize()
        }
        
        //Launch helper
        if userDefaults.boolForKey(LyricsAutoLaunches) {
            if userDefaults.integerForKey(LyricsLaunchTpyePopUpIndex) != 0 {
                let helperPath = NSBundle.mainBundle().bundlePath + "/Contents/Library/LoginItems/LyricsX Helper.app"
                NSWorkspace.sharedWorkspace().launchApplication(helperPath)
            }
        }
    }

    private func generateDirectFilterData() -> NSData {
        let caseInsensitiveStr = ["作詞","作词","作曲","編曲","编曲","収録","收录","演唱","歌手","歌曲","制作","製作","歌词","歌詞","翻譯","翻译","插曲","插入歌","主题歌","主題歌","片頭曲","片头曲","片尾曲","Lrc","QQ","アニメ","CV","LyricsBy","CharacterSong","InsertSong","SoundTrack"]
        let caseSensitiveStr = ["PC","OP","ED","OVA","BGM"]
        var directFilter = [FilterString]()
        for str in caseInsensitiveStr {
            directFilter.append(FilterString(keyword: str, caseSensitive: false))
        }
        for str in caseSensitiveStr {
            directFilter.append(FilterString(keyword: str, caseSensitive: true))
        }
        return NSKeyedArchiver.archivedDataWithRootObject(directFilter)
    }
    
    private func generateConditionalFilterData() -> NSData {
        let caseInsensitiveStr = ["by","歌","唄","曲","作","唱","詞","词","編","编"]
        var conditionalFilter = [FilterString]()
        for str in caseInsensitiveStr {
            conditionalFilter.append(FilterString(keyword: str, caseSensitive: false))
        }
        return NSKeyedArchiver.archivedDataWithRootObject(conditionalFilter)
    }
}

