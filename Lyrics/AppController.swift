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
    var lyrics:[LyricsLineModel]!
    var operationQueue:NSOperationQueue!
    var iTunesSBA:SBApplication!
    var iTunes:iTunesApplication!
    var iTunesCurrentTrack:NSString!
    var timeDly:Int!
    
    override init() {
        
        super.init()
        
        iTunesSBA = SBApplication(bundleIdentifier: "com.apple.iTunes")
        iTunes = iTunesSBA as iTunesApplication
        lyrics = Array()
        
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
        parsingLrc("遥か彼方", artist: "Rita")
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
    
    func parsingLrc(songTitle: NSString, artist: NSString) {
        lyrics.removeAll()
        let defaultPath: NSString = "/volumes/ramdisk"
        let lrcFilePath: String = defaultPath.stringByAppendingPathComponent("\(songTitle) - \(artist).lrc")
        let lrcExists: Bool = NSFileManager.defaultManager().fileExistsAtPath(lrcFilePath)
        if !lrcExists {
            NSLog("lrc File doesn't exist")
            return
        }
        let lrcFileContents: NSString
        do {
            lrcFileContents = try NSString(contentsOfFile: lrcFilePath, encoding: NSUTF8StringEncoding)
        } catch let theError as NSError {
            NSLog("%@", theError.localizedDescription)
            return
        }
        let newLineCharSet: NSCharacterSet = NSCharacterSet.newlineCharacterSet()
        let lrcParagraphs: NSArray = lrcFileContents.componentsSeparatedByCharactersInSet(newLineCharSet)
        let regexForTimeTag: NSRegularExpression
        let regexForIDTag: NSRegularExpression
        do {
            regexForTimeTag = try NSRegularExpression(pattern: "\\[[0-9]+:[0-9]+.[0-9]+\\]|\\[[0-9]+:[0-9]+\\]", options: [.CaseInsensitive])
        } catch let theError as NSError {
            NSLog("%@", theError.localizedDescription)
            return
        }
        
        do {
            regexForIDTag = try NSRegularExpression(pattern: "\\[.*:.*\\]", options: [.CaseInsensitive])
        } catch let theError as NSError {
            NSLog("%@", theError.localizedDescription)
            return
        }
        
        for str in lrcParagraphs {
            let timeTagsMatched: NSArray = regexForTimeTag.matchesInString(str as! String, options: [.ReportProgress], range: NSMakeRange(0, str.length))
            if timeTagsMatched.count > 0 {
                let index: Int = (timeTagsMatched.lastObject?.range.location)! + (timeTagsMatched.lastObject?.range.length)!
                let lyricsSentenceRange: NSRange = NSMakeRange(index, str.length-index)
                let lyricsSentence: NSString = str.substringWithRange(lyricsSentenceRange)
                for result in timeTagsMatched {
                    let matched:NSRange = result.range
                    let lrcLine: LyricsLineModel = LyricsLineModel()
                    lrcLine.lyricsSentence = lyricsSentence
                    lrcLine.setMsecPositionWithTimeTag(str.substringWithRange(matched))
                    print(lrcLine.msecPosition)
                    let currentCount: Int = lyrics.count
                    var j: Int = 0
                    for j; j<currentCount; ++j {
                        if lrcLine.msecPosition < lyrics[j].msecPosition {
                            lyrics.insert(lrcLine, atIndex: j)
                            break
                        }
                    }
                    if j == currentCount {
                        lyrics.append(lrcLine)
                    }
                }
            }
            else {
                let theMatchedRange: NSRange = regexForIDTag.rangeOfFirstMatchInString(str as! String, options: [.ReportProgress], range: NSMakeRange(0, str.length))
                if theMatchedRange.length == 0 {
                    continue
                }
                let theIDTag: NSString = str.substringWithRange(theMatchedRange)
                let colonRange: NSRange = theIDTag.rangeOfString(":")
                let idStr: NSString = theIDTag.substringWithRange(NSMakeRange(1, colonRange.location-1))
                if idStr != "offset" {
                    continue
                }
                else {
                    let delayStr: NSString=theIDTag.substringWithRange(NSMakeRange(colonRange.location+1, theIDTag.length-colonRange.length-colonRange.location-1))
                    timeDly = delayStr.integerValue
                }
            }
            
        }
    }
    
    func getLrc() {
        
    }

// MARK: - Handling Thead
    
    func handlingThead(dic:NSDictionary) {
        
    }
    
}








