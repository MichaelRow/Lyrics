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
    var lyricsArray:[LyricsLineModel]!
    var currentLyrics: NSString!
    var operationQueue:NSOperationQueue!
    var iTunesSBA:SBApplication!
    var iTunes:iTunesApplication!
    var currentPersistentID:NSString!
    var loadingTrackPersistentID:NSString!
    var songList:[SongInfos]!
    var timeDly:Int!
    var qianqian:QianQianAPI!
    
// MARK: - Init & deinit
    
    override init() {
        
        super.init()
        
        iTunesSBA = SBApplication(bundleIdentifier: "com.apple.iTunes")
        iTunes = iTunesSBA as iTunesApplication
        lyricsArray = Array()
        songList = Array()
        qianqian = QianQianAPI()
        
        NSBundle(forClass: object_getClass(self)).loadNibNamed("StatusMenu", owner: self, topLevelObjects: nil)
        setupStatusItem()
        
        currentPersistentID = ""
        currentLyrics = "LyricsX"
        if iTunesSBA.running == true && iTunes.playerState == iTunesEPlS.Playing {
            currentPersistentID = (iTunes.currentTrack?.persistentID?.copy())! as! NSString
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { () -> Void in
                self.loadingLyrics()
            }
            NSLog("Create new iTunesTrackingThead")
            isTrackingRunning = true
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { () -> Void in
                self.iTunesTrackingThread()
            }
        }
        
        let nc = NSNotificationCenter.defaultCenter()
        nc.addObserver(self, selector: "qianqianLoadingCompleted", name: QianQianLrcLoadedNotification, object: nil)
        NSDistributedNotificationCenter.defaultCenter().addObserver(self, selector: "iTunesPlayerInfoChanged:", name: "com.apple.iTunes.playerInfo", object: nil)

    }
    
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
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
        var playerPosition: Int
        
        while true {
            if !iTunesSBA.running && NSUserDefaults.standardUserDefaults().boolForKey(LyricsQuitWithITunes) {
                NSLog("Terminating")
                NSApplication.sharedApplication().terminate(self)
            }
            if iTunes.playerState == iTunesEPlS.Playing {
                if lyricsArray.count != 0 {
                    playerPosition = Int(iTunes.playerPosition! * 1000)
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
                        self.handlingPositionChange(playerPosition)
                    })
                }
            }
            else {
                //No need to track iTunes PlayerPosition when it's paused, just kill the thread.
                NSLog("Kill iTunesTrackingThread")
                isTrackingRunning=false
                return
            }
            NSThread.sleepForTimeInterval(0.13)
        }
    }
    
    
    func iTunesPlayerInfoChanged (n:NSNotification){
        let userInfo = n.userInfo
        if userInfo == nil {
            return
        }
        else {
            if userInfo!["Player State"] as! String == "Paused" {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.lyricsWindow.displayLyrics(nil, secondLyrics: nil)
                })
                NSLog("iTunes Paused")
                return
            }
            else if userInfo!["Player State"] as! String == "Playing" {
                //iTunes is playing, we should create the tracking thread
                if !isTrackingRunning {
                    NSLog("Create new iTunesTrackingThead")
                    isTrackingRunning = true
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { () -> Void in
                        self.iTunesTrackingThread()
                    }
                }
                NSLog("iTunes Playing")
            }
            if currentPersistentID == nil {
                currentPersistentID = (iTunes.currentTrack?.persistentID?.copy())! as! NSString
                return
            }
            if currentPersistentID == iTunes.currentTrack?.persistentID {
                return
            } else {
                NSLog("Song Changed to: %@",(iTunes.currentTrack?.name)!)
                lyricsArray.removeAll()
                currentPersistentID = (iTunes.currentTrack?.persistentID?.copy())! as! NSString
                loadingTrackPersistentID = currentPersistentID.copy() as! NSString
                loadingLyrics()
            }
        }
    }

// MARK: - Lrc Methods
    
    func parsingLrc(songTitle: NSString, artist: NSString) {
        
        // Parse lrc file to get lyrics, time-tags and time offset
        NSLog("Start to Parse lrc")
        lyricsArray.removeAll()
        let defaultPath: NSString = NSSearchPathForDirectoriesInDomains(.DesktopDirectory, [.UserDomainMask], true).first!
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
                    let currentCount: Int = lyricsArray.count
                    var j: Int = 0
                    for j; j<currentCount; ++j {
                        if lrcLine.msecPosition < lyricsArray[j].msecPosition {
                            lyricsArray.insert(lrcLine, atIndex: j)
                            break
                        }
                    }
                    if j == currentCount {
                        lyricsArray.append(lrcLine)
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
    
    func loadingLyrics() {
        let desktop:NSString = NSSearchPathForDirectoriesInDomains(.DesktopDirectory, [.UserDomainMask], true).first!
        let songTitle:String = (iTunes.currentTrack?.name)! as String
        let artist:String = (iTunes.currentTrack?.artist)! as String
        loadingTrackPersistentID = currentPersistentID.copy() as! NSString
        if !NSFileManager.defaultManager().fileExistsAtPath("\(desktop)/\(songTitle) - \(artist).lrc") {
            qianqian.getLyricsWithTitle(convertToSC(songTitle) as String, artist: convertToSC(artist) as String)
        } else {
            parsingLrc(songTitle, artist: artist)
        }
        
    }

// MARK: - Handling Thead
    
    func handlingPositionChange (playerPosition: Int) {
        var index: Int
        for index=0; index < lyricsArray.count; ++index {
            if playerPosition < lyricsArray[index].msecPosition {
                if index-1 == -1 {
                    if currentLyrics != nil || currentLyrics != "" {
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            self.lyricsWindow.displayLyrics(nil, secondLyrics: nil)
                        })
                    }
                    return
                }
                else {
                    if currentLyrics != self.lyricsArray[index-1].lyricsSentence {
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            self.lyricsWindow.displayLyrics(self.lyricsArray[index-1].lyricsSentence, secondLyrics: nil)
                        })
                    }
                    return
                }
            }
        }
        if index == lyricsArray.count {
            if currentLyrics != nil || currentLyrics != "" {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.lyricsWindow.displayLyrics(nil, secondLyrics: nil)
                })
            }
            return
        }
    }
    
    func handlingLyrics () {
        
    }
    
//MARK - Lyrics Source Loading Completion
    
    func qianqianLoadingCompleted() {
        NSLog("QianQian Lrc loaded")
        if qianqian.songs.count > 0 {
            let songTitle:String = (iTunes.currentTrack?.name)! as String
            let artist:String = (iTunes.currentTrack?.artist)! as String
            let url:String=qianqian.songs.objectAtIndex(0).lyricURL
            let desktop:NSString = NSSearchPathForDirectoriesInDomains(.DesktopDirectory, [.UserDomainMask], true).first!
            let lyricsContents: NSString
            do {
                lyricsContents = try NSString(contentsOfURL: NSURL(string: url)!, encoding: NSUTF8StringEncoding)
            } catch {
                return
            }
            do {
                try lyricsContents.writeToFile("\(desktop)/\(songTitle) - \(artist).lrc", atomically: false, encoding: NSUTF8StringEncoding)
            } catch {
                return
            }
            parsingLrc(songTitle, artist: artist)
        }
    }
    
}








