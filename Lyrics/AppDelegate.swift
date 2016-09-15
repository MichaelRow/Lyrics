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
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let userSavingPath: NSString = NSSearchPathForDirectoriesInDomains(.downloadsDirectory, [.userDomainMask], true).first! as NSString 
        
        // Filter
        let directFilterData = generateDirectFilterData()
        let conditionalFilterData = generateConditionalFilterData()
        
        let registerDefaultsDic: [String:AnyObject] = [
            //Menu
            LyricsDesktopLyricsEnabled : NSNumber(value: true as Bool),
            LyricsMenuBarLyricsEnabled : NSNumber(value: false as Bool),
            LyricsIsVerticalLyrics : NSNumber(value: false as Bool),
            
            //General Preferences Defaults
            LyricsSavingPathPopUpIndex : NSNumber(value: 0 as Int),
            LyricsUserSavingPath : userSavingPath,
            LyricsAutoLaunches : NSNumber(value: true as Bool),
            LyricsLaunchTpyePopUpIndex : NSNumber(value: 2 as Int),
            LyricsServerIndex : NSNumber(value: 0 as Int),
            LyricsQuitWithITunes : NSNumber(value: false as Bool),
            LyricsDisableAllAlert : NSNumber(value: false as Bool),
            LyricsUseAutoLayout : NSNumber(value: true as Bool),
            LyricsHeightFromDockToLyrics : NSNumber(value: 10 as Int),
            LyricsConstWidth : NSNumber(value: 1000 as Int),
            LyricsConstHeight : NSNumber(value: 60 as Int),
            
            //Lyrics Preferences Defaults
            LyricsAutoConvertChinese : NSNumber(value: false as Bool),
            LyricsVerticalLyricsPosition : NSNumber(value: 1 as Int),
            LyricsChineseTypeIndex : NSNumber(value: 0 as Int),
            LyricsTwoLineMode : NSNumber(value: true as Bool),
            LyricsTwoLineModeIndex : NSNumber(value: 0 as Int),
            LyricsDisabledWhenPaused : NSNumber(value: true as Bool),
            LyricsDisabledWhenSreenShot : NSNumber(value: true as Bool),
            LyricsSearchForDiglossiaLrc : NSNumber(value: true as Bool),
            LyricsDisplayInAllSpaces: NSNumber(value: true as Bool),
            
            //Font and Color Preferences Defaults
            LyricsFontName : "HannotateSC-W7" as AnyObject,
            LyricsFontSize : NSNumber(value: 26 as Float),
            LyricsShadowModeEnable : NSNumber(value: true as Bool),
            LyricsTextColor : NSKeyedArchiver.archivedData(withRootObject: NSColor.white) as AnyObject,
            LyricsBackgroundColor : NSKeyedArchiver.archivedData(withRootObject: NSColor(calibratedWhite: 0, alpha: 0.5)) as AnyObject,
            LyricsShadowColor : NSKeyedArchiver.archivedData(withRootObject: NSColor.orange) as AnyObject,
            LyricsShadowRadius : NSNumber(value: 2 as Float),
            LyricsBgHeightINCR : NSNumber(value: 0 as Float),
            LyricsYOffset : NSNumber(value: 0 as Float),
            
            //Filter Preferences Defaults
            LyricsDirectFilterKey : directFilterData as AnyObject,
            LyricsConditionalFilterKey : conditionalFilterData as AnyObject,
            LyricsEnableFilter : NSNumber(value: false as Bool),
            LyricsEnableSmartFilter : NSNumber(value: true as Bool)
        ]
        
        let userDefaults = UserDefaults.standard

        userDefaults.register(defaults: registerDefaultsDic)
        
        let lyricsXHelpers = NSRunningApplication.runningApplications(withBundleIdentifier: "Eru.LyricsX-Helper")
        for helper in lyricsXHelpers {
            helper.forceTerminate()
        }
        
        AppController.initSharedAppController()
        
        // Force Prefs to load presets
        let prefs = AppPrefsWindowController.sharedPrefsWindowController
        prefs.showWindow(nil)
        prefs.window?.close()
        
        //Check if login item hasn't be enabled
        let identifier: String = "Eru.LyricsX-Helper"
        if userDefaults.bool(forKey: LyricsAutoLaunches) {
            if !SMLoginItemSetEnabled(identifier as CFString, true) {
                NSLog("Failed to enable login item")
            }
        }
        
        NSColorPanel.shared().showsAlpha = true
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        
        //Save time delay
        let appController = AppController.sharedController
        if appController.timeDly != appController.timeDlyInFile {
            NSLog("App terminating, saveing lrc time delay change...")
            appController.handleLrcDelayChange()
        }
        
        //Terminate LrcSeeker
        let lrcSeekers = NSRunningApplication.runningApplications(withBundleIdentifier: "Eru.LrcSeeker")
        for ls in lrcSeekers {
            ls.terminate()
        }
        
        let userDefaults = UserDefaults.standard
        
        //Save window state in constant layout mode
        if !userDefaults.bool(forKey: LyricsUseAutoLayout) {
            DesktopLyricsController.sharedController.storeWindowSize()
        }
        
        //Launch helper
        if userDefaults.bool(forKey: LyricsAutoLaunches) {
            if userDefaults.integer(forKey: LyricsLaunchTpyePopUpIndex) != 0 {
                let helperPath = Bundle.main.bundlePath + "/Contents/Library/LoginItems/LyricsX Helper.app"
                NSWorkspace.shared().launchApplication(helperPath)
            }
        }
    }

    fileprivate func generateDirectFilterData() -> Data {
        let caseInsensitiveStr = ["作詞","作词","作曲","編曲","编曲","収録","收录","演唱","歌手","歌曲","制作","製作","歌词","歌詞","翻譯","翻译","插曲","插入歌","主题歌","主題歌","片頭曲","片头曲","片尾曲","Lrc","QQ","アニメ","CV","LyricsBy","CharacterSong","InsertSong","SoundTrack"]
        let caseSensitiveStr = ["PC","OP","ED","OVA","BGM"]
        var directFilter = [FilterString]()
        for str in caseInsensitiveStr {
            directFilter.append(FilterString(keyword: str, caseSensitive: false))
        }
        for str in caseSensitiveStr {
            directFilter.append(FilterString(keyword: str, caseSensitive: true))
        }
        return NSKeyedArchiver.archivedData(withRootObject: directFilter)
    }
    
    fileprivate func generateConditionalFilterData() -> Data {
        let caseInsensitiveStr = ["by","歌","唄","曲","作","唱","詞","词","編","编"]
        var conditionalFilter = [FilterString]()
        for str in caseInsensitiveStr {
            conditionalFilter.append(FilterString(keyword: str, caseSensitive: false))
        }
        return NSKeyedArchiver.archivedData(withRootObject: conditionalFilter)
    }
}

