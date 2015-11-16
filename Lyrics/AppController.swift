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
    var iTunes:iTunesBridge!
    var currentPlayingSongID:NSString!
    var loadingLrcSongID:NSString!
    var loadingLrcSongTitle:NSString!
    var loadingLrcArtist:NSString!
    var songList:[SongInfos]!
    var timeDly:Int!
    var qianqian:QianQianAPI!
    var ttpod:TTPodAPI!
    var geciMe:GeciMeAPI!
    var serverSongTitle:NSString!
    var lrcSourceHandleQueue:dispatch_queue_t!
    
// MARK: - Init & deinit
    
    override init() {
        
        super.init()
        iTunes = iTunesBridge()
        lyricsArray = Array()
        songList = Array()
        qianqian = QianQianAPI()
        ttpod = TTPodAPI()
        geciMe = GeciMeAPI()
        lrcSourceHandleQueue = dispatch_queue_create("HandleLrcSource", DISPATCH_QUEUE_CONCURRENT);
        
        NSBundle(forClass: object_getClass(self)).loadNibNamed("StatusMenu", owner: self, topLevelObjects: nil)
        setupStatusItem()
        
        currentPlayingSongID = ""
        currentLyrics = "LyricsX"
        if iTunes.running() && iTunes.playing() {
            currentPlayingSongID = iTunes.currentPersistentID().copy() as! NSString
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
        nc.addObserver(self, selector: "lrcURLLoadingCompleted", name: LrcLoadedNotification, object: nil)
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
//            if !iTunes.running() && NSUserDefaults.standardUserDefaults().boolForKey(LyricsQuitWithITunes) {
//                NSLog("Terminating")
//                NSApplication.sharedApplication().terminate(self)
//            }
            if iTunes.playing() {
                if lyricsArray.count != 0 {
                    playerPosition = iTunes.playerPosition()
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
            if currentPlayingSongID == nil {
                currentPlayingSongID = iTunes.currentPersistentID().copy() as! NSString
                return
            }
            if currentPlayingSongID == iTunes.currentPersistentID() {
                return
            } else {
                NSLog("Song Changed to: %@",iTunes.currentTitle())
                lyricsArray.removeAll()
                currentPlayingSongID = iTunes.currentPersistentID().copy() as! NSString
                loadingLyrics()
            }
        }
    }

// MARK: - Lrc Methods
    
    func parsingLrc(lrcContents:NSString) {
        
        // Parse lrc file to get lyrics, time-tags and time offset
        NSLog("Start to Parse lrc")
        lyricsArray.removeAll()
        
        let newLineCharSet: NSCharacterSet = NSCharacterSet.newlineCharacterSet()
        let lrcParagraphs: NSArray = lrcContents.componentsSeparatedByCharactersInSet(newLineCharSet)
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
        let savingPath:NSString = NSSearchPathForDirectoriesInDomains(.MusicDirectory, [.UserDomainMask], true).first! + "/Lyrics"
        let songTitle:String = iTunes.currentTitle()
        let artist:String = iTunes.currentArtist()
        let lrcFilePath = savingPath.stringByAppendingPathComponent("\(songTitle) - \(artist).lrc")
        if !NSFileManager.defaultManager().fileExistsAtPath(lrcFilePath) {
            loadingLrcSongID = currentPlayingSongID.copy() as! NSString
            loadingLrcArtist = artist.copy() as! NSString
            loadingLrcSongTitle = songTitle.copy() as! NSString
            serverSongTitle = nil
            qianqian.getLyricsWithTitle(convertToSC(songTitle) as String, artist: convertToSC(artist) as String)
            //            ttpod.getLyricsWithTitle(songTitle, artist: artist)
        } else {
            let lrcContents: NSString
            do {
                lrcContents = try NSString(contentsOfFile: lrcFilePath, encoding: NSUTF8StringEncoding)
            } catch {
                return
            }
            parsingLrc(lrcContents)
        }
    }
    
    func testLrc(lrcFileContents: NSString) -> Bool {
        
        // test whether the string is lrc
        let newLineCharSet: NSCharacterSet = NSCharacterSet.newlineCharacterSet()
        let lrcParagraphs: NSArray = lrcFileContents.componentsSeparatedByCharactersInSet(newLineCharSet)
        let regexForTimeTag: NSRegularExpression
        do {
            regexForTimeTag = try NSRegularExpression(pattern: "\\[[0-9]+:[0-9]+.[0-9]+\\]|\\[[0-9]+:[0-9]+\\]", options: [.CaseInsensitive])
        } catch let theError as NSError {
            NSLog("%@", theError.localizedDescription)
            return false
        }
        var numberOfMatched: Int = 0
        for str in lrcParagraphs {
            numberOfMatched = regexForTimeTag.numberOfMatchesInString(str as! String, options: [.ReportProgress], range: NSMakeRange(0, str.length))
            if numberOfMatched > 0 {
                return true
            }
        }
        return false
    }

// MARK: - Handling Thead
    
    func handlingPositionChange (playerPosition: Int) {
        var index: Int
        for index=0; index < lyricsArray.count; ++index {
            if playerPosition < lyricsArray[index].msecPosition {
                if index-1 == -1 {
                    if currentLyrics != nil {
                        currentLyrics = nil
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            if self.lyricsArray.count == 0{
                                return
                            }
                            self.lyricsWindow.displayLyrics(nil, secondLyrics: nil)
                        })
                    }
                    return
                }
                else {
                    if currentLyrics != self.lyricsArray[index-1].lyricsSentence {
                        currentLyrics = lyricsArray[index-1].lyricsSentence
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            if self.lyricsArray.count == 0{
                                return
                            }
                            self.lyricsWindow.displayLyrics(self.lyricsArray[index-1].lyricsSentence, secondLyrics: nil)
                        })
                    }
                    return
                }
            }
        }
        if index == lyricsArray.count {
            if currentLyrics != nil {
                currentLyrics = nil
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    if self.lyricsArray.count == 0{
                        return
                    }
                    self.lyricsWindow.displayLyrics(nil, secondLyrics: nil)
                })
            }
            return
        }
    }
    
    func handlingLyrics () {
        
    }
    
//MARK - Lyrics Source Loading Completion
    
    func isBetterLrc(serverSongTitle: NSString) -> Bool {
        if serverSongTitle.rangeOfString("中").location != NSNotFound || serverSongTitle.rangeOfString("对照").location != NSNotFound || serverSongTitle.rangeOfString("双").location != NSNotFound {
            return true
        }
        return false
    }
    
    func lrcURLLoadingCompleted() {
        if qianqian.songs.count == 0 {
            return
        }
        if serverSongTitle != nil {
            if true/* && (if need to replayce with better lyrics)*/ {
                if isBetterLrc(serverSongTitle) {
                    return
                }
            } else {
                return
            }
        }
        if lyricsArray.count != 0 {
            return
        }
        let savingPath:NSString = NSSearchPathForDirectoriesInDomains(.MusicDirectory, [.UserDomainMask], true).first! + "/Lyrics"
        var lyricsContents: NSString! = nil
        var betterLrc: SongInfos! = nil
        for lrc in qianqian.songs {
            if isBetterLrc(lrc.songTitle) {
                betterLrc = lrc as! SongInfos
                do {
                    lyricsContents = try NSString(contentsOfURL: NSURL(string: betterLrc.lyricURL)!, encoding: NSUTF8StringEncoding)
                } catch let theError as NSError{
                    NSLog("%@", theError.localizedDescription)
                }
                break
            }
        }
        if lyricsContents == nil || !testLrc(lyricsContents) {
            NSLog("File concidered better is not lrc file, trying others")
            for lrc in qianqian.songs {
                let theURL:NSURL = NSURL(string: lrc.lyricURL)!
                do {
                    lyricsContents = try NSString(contentsOfURL: theURL, encoding: NSUTF8StringEncoding)
                } catch let theError as NSError{
                    NSLog("%@", theError.localizedDescription)
                }
                if lyricsContents != nil || testLrc(lyricsContents) {
                    betterLrc = lrc as! SongInfos
                    break
                }
            }
        }
        if betterLrc != nil {
            if loadingLrcSongID == currentPlayingSongID {
                serverSongTitle = betterLrc.songTitle
                parsingLrc(lyricsContents)
            }
            let lrcFilePath = savingPath.stringByAppendingPathComponent("\(loadingLrcSongTitle) - \(loadingLrcArtist).lrc")
            do {
                try lyricsContents.writeToFile(lrcFilePath, atomically: false, encoding: NSUTF8StringEncoding)
            } catch let theError as NSError {
                NSLog("%@", theError.localizedDescription)
            }
        }
    }
    
    func lrcContentLoadingCompleted() {
        
    }
    
}








