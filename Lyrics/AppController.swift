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
    var xiami:XiamiAPI!
    var ttpod:TTPodAPI!
    var geciMe:GeciMeAPI!
    var serverSongInfo:NSString!
    var lrcSourceHandleQueue:dispatch_queue_t!
    var userDefaults:NSUserDefaults!
    var timer: NSTimer!
    
// MARK: - Init & deinit
    
    override init() {
        
        super.init()
        iTunes = iTunesBridge()
        lyricsArray = Array()
        songList = Array()
        qianqian = QianQianAPI()
        xiami = XiamiAPI()
        ttpod = TTPodAPI()
        geciMe = GeciMeAPI()
        lrcSourceHandleQueue = dispatch_queue_create("HandleLrcSource", DISPATCH_QUEUE_CONCURRENT);
        userDefaults = NSUserDefaults.standardUserDefaults()
        
        NSBundle(forClass: object_getClass(self)).loadNibNamed("StatusMenu", owner: self, topLevelObjects: nil)
        setupStatusItem()
        
        if !checkSavingPath() {
            let alert: NSAlert = NSAlert()
            alert.messageText = "An error occured"
            alert.informativeText = "The default path which used to save lrc files is not a directory.\nIn this case no lrc can be saved."
            alert.addButtonWithTitle("Open Preferences and set")
            alert.addButtonWithTitle("Ignore")
            let response: NSModalResponse = alert.runModal()
            if response == NSAlertFirstButtonReturn {
                showPreferences(nil)
            }
        }
        
        currentPlayingSongID = ""
        currentLyrics = "LyricsX"
        if iTunes.running() && iTunes.playing() {
            currentPlayingSongID = iTunes.currentPersistentID().copy() as! NSString
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { () -> Void in
                self.handlingSongChange()
            }
            NSLog("Create new iTunesTrackingThead")
            isTrackingRunning = true
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { () -> Void in
                self.iTunesTrackingThread()
            }
        }
        
        let nc = NSNotificationCenter.defaultCenter()
        nc.addObserver(self, selector: "lrcLoadingCompleted:", name: LrcLoadedNotification, object: nil)
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
    
    func checkSavingPath() -> Bool{
        let savingPath:NSString
        if userDefaults.integerForKey(LyricsSavingPathPopUpIndex) == 0 {
            savingPath = NSSearchPathForDirectoriesInDomains(.MusicDirectory, [.UserDomainMask], true).first! + "/LyricsX"
        } else {
            savingPath = userDefaults.stringForKey(LyricsUserSavingPath)!
        }
        let fm: NSFileManager = NSFileManager.defaultManager()
        
        var isDir: ObjCBool = false
        if fm.fileExistsAtPath(savingPath as String, isDirectory: &isDir) {
            if !isDir {
                return false
            }
        } else {
            do {
                try fm.createDirectoryAtPath(savingPath as String, withIntermediateDirectories: true, attributes: nil)
            } catch let theError as NSError{
                NSLog("%@", theError.localizedDescription)
            }
        }
        return true
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
                if userDefaults.boolForKey(LyricsDisabledWhenPaused) {
                    currentLyrics = nil
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.lyricsWindow.displayLyrics(nil, secondLyrics: nil)
                    })
                }
                NSLog("iTunes Paused")
                if userDefaults.boolForKey(LyricsQuitWithITunes) {
                    if timer != nil {
                        timer.invalidate()
                    }
                    timer = NSTimer.scheduledTimerWithTimeInterval(3, target: self, selector: "terminate", userInfo: nil, repeats: false)
                }
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
                lyricsWindow.displayLyrics(nil, secondLyrics: nil)
                currentPlayingSongID = iTunes.currentPersistentID().copy() as! NSString
                handlingSongChange()
            }
        }
    }

    func terminate() {
        if !iTunes.running() {
            NSApplication.sharedApplication().terminate(self)
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
        let tempLyricsArray = lyricsArray
        var index: Int
        for index=0; index < tempLyricsArray.count; ++index {
            if playerPosition < tempLyricsArray[index].msecPosition {
                if index-1 == -1 {
                    if currentLyrics != nil {
                        currentLyrics = nil
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            self.lyricsWindow.displayLyrics(nil, secondLyrics: nil)
                        })
                    }
                    return
                }
                else {
                    if currentLyrics != tempLyricsArray[index-1].lyricsSentence {
                        currentLyrics = tempLyricsArray[index-1].lyricsSentence
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            self.lyricsWindow.displayLyrics(tempLyricsArray[index-1].lyricsSentence, secondLyrics: nil)
                        })
                    }
                    return
                }
            }
        }
        if index == tempLyricsArray.count {
            if currentLyrics != nil {
                currentLyrics = nil
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.lyricsWindow.displayLyrics(nil, secondLyrics: nil)
                })
            }
            return
        }
    }
    
    func handlingSongChange() {
        let savingPath: NSString
        if userDefaults.integerForKey(LyricsSavingPathPopUpIndex) == 0 {
            savingPath = NSSearchPathForDirectoriesInDomains(.MusicDirectory, [.UserDomainMask], true).first! + "/LyricsX"
        } else {
            savingPath = userDefaults.stringForKey(LyricsUserSavingPath)!
        }
        let songTitle:String = iTunes.currentTitle().stringByReplacingOccurrencesOfString("/", withString: "&")
        let artist:String = iTunes.currentArtist().stringByReplacingOccurrencesOfString("/", withString: "&")
        let lrcFilePath = savingPath.stringByAppendingPathComponent("\(songTitle) - \(artist).lrc")
        if  NSFileManager.defaultManager().fileExistsAtPath(lrcFilePath) {
            let lrcContents: NSString
            do {
                lrcContents = try NSString(contentsOfFile: lrcFilePath, encoding: NSUTF8StringEncoding)
            } catch {
                NSLog("Failed to load lrc")
                return
            }
            parsingLrc(lrcContents)
            if lyricsArray.count != 0 {
                return
            }
        }
        loadingLrcSongID = currentPlayingSongID.copy() as! NSString
        loadingLrcArtist = artist.copy() as! NSString
        loadingLrcSongTitle = songTitle.copy() as! NSString
        serverSongInfo = nil
        
        let titleForSearch: String = delSpecificSymbol(songTitle) as String
        let artistForSearch: String = delSpecificSymbol(artist) as String
        qianqian.getLyricsWithTitle(convertToSC(titleForSearch) as String, artist: convertToSC(artistForSearch) as String)
        xiami.getLyricsWithTitle(titleForSearch, artist: artistForSearch)
        ttpod.getLyricsWithTitle(titleForSearch, artist: artistForSearch)
        geciMe.getLyricsWithTitle(titleForSearch, artist: artistForSearch)
    }
    
    func delSpecificSymbol(input: NSString) -> NSString {
        let specificSymbol: [String] = [
            ",", ".", "'", "\"", "`", "~", "!", "@", "#", "$", "%", "^", "&", "*", "(", ")", "（", "）", "，",
            "。", "“", "”", "‘", "’", "?", "？", "！", "/", "[", "]", "{", "}", "<", ">", "=", "-", "+", "×",
            "☆", "★", "√", "～"
        ]
        let output: NSMutableString = input.mutableCopy() as! NSMutableString
        for symbol in specificSymbol {
            output.replaceOccurrencesOfString(symbol, withString: " ", options: [], range: NSMakeRange(0, output.length))
        }
        return output
    }
    
// MARK: - Lyrics Source Loading Completion
    
    func isBetterLrc(serverSongTitle: NSString) -> Bool {
        if serverSongTitle.rangeOfString("中").location != NSNotFound || serverSongTitle.rangeOfString("对照").location != NSNotFound || serverSongTitle.rangeOfString("双").location != NSNotFound {
            return true
        }
        return false
    }
    
    func lrcLoadingCompleted(n: NSNotification) {
        let source: Int = n.userInfo!["source"]!.integerValue
        switch source {
        case 1:
            dispatch_barrier_async(lrcSourceHandleQueue, { () -> Void in
                self.handleLrcURL(self.qianqian.songs)
            })
        case 2:
            dispatch_barrier_async(lrcSourceHandleQueue, { () -> Void in
                self.handleLrcURL(self.xiami.songs)
            })
        case 3:
            dispatch_barrier_async(lrcSourceHandleQueue, { () -> Void in
                self.handleLrcContents(self.ttpod.songInfo.lyric)
            })
        case 4:
            dispatch_barrier_async(lrcSourceHandleQueue, { () -> Void in
                self.handleLrcURL(self.geciMe.songs)
            })
        default:
            return;
        }
    }
    
    func handleLrcURL(serverLrcs: NSArray) {
        if serverLrcs.count == 0 {
            return
        }
        if serverSongInfo != nil {
            if userDefaults.boolForKey(LyricsSearchForBetterLrc) {
                if isBetterLrc(serverSongInfo) {
                    return
                }
            } else {
                return
            }
        }
        var lyricsContents: NSString! = nil
        var betterLrc: SongInfos! = nil
        for lrc in serverLrcs {
            if isBetterLrc(lrc.songTitle + lrc.artist) {
                betterLrc = lrc as! SongInfos
                do {
                    lyricsContents = try NSString(contentsOfURL: NSURL(string: betterLrc.lyricURL)!, encoding: NSUTF8StringEncoding)
                } catch let theError as NSError{
                    NSLog("%@", theError.localizedDescription)
                }
                break
            }
        }
        if betterLrc == nil && serverSongInfo != nil {
            return
        }
        if lyricsContents == nil || !testLrc(lyricsContents) {
            NSLog("better lrc not found or it's not lrc file,trying others")
            for lrc in serverLrcs {
                let theURL:NSURL = NSURL(string: lrc.lyricURL)!
                do {
                    lyricsContents = try NSString(contentsOfURL: theURL, encoding: NSUTF8StringEncoding)
                } catch let theError as NSError{
                    NSLog("%@", theError.localizedDescription)
                }
                if lyricsContents != nil && testLrc(lyricsContents) {
                    betterLrc = lrc as! SongInfos
                    break
                }
            }
        }
        if betterLrc != nil {
            if loadingLrcSongID == currentPlayingSongID {
                serverSongInfo = betterLrc.songTitle
                parsingLrc(lyricsContents)
            }
            saveLrcToLocal(lyricsContents)
        }
    }
    
    func handleLrcContents(lyricsContents: NSString) {
        if serverSongInfo != nil {
            return
        }
        if !testLrc(lyricsContents) {
            return
        }
        serverSongInfo = iTunes.currentTitle()
        parsingLrc(lyricsContents)
        if lyricsArray.count  == 0 {
            return
        }
        saveLrcToLocal(lyricsContents)
    }
    
    func saveLrcToLocal (lyricsContents: NSString) {
        let savingPath:NSString
        if userDefaults.integerForKey(LyricsSavingPathPopUpIndex) == 0 {
            savingPath = NSSearchPathForDirectoriesInDomains(.MusicDirectory, [.UserDomainMask], true).first! + "/LyricsX"
        } else {
            savingPath = userDefaults.stringForKey(LyricsUserSavingPath)!
        }
        let fm: NSFileManager = NSFileManager.defaultManager()
        
        var isDir: ObjCBool = false
        if fm.fileExistsAtPath(savingPath as String, isDirectory: &isDir) {
            if !isDir {
                return
            }
        } else {
            do {
                try fm.createDirectoryAtPath(savingPath as String, withIntermediateDirectories: true, attributes: nil)
            } catch let theError as NSError{
                NSLog("%@", theError.localizedDescription)
                return
            }
        }
        
        let titleForSaving = loadingLrcSongTitle.stringByReplacingOccurrencesOfString("/", withString: "&")
        let artistForSaving = loadingLrcArtist.stringByReplacingOccurrencesOfString("/", withString: "&")
        let lrcFilePath = savingPath.stringByAppendingPathComponent("\(titleForSaving) - \(artistForSaving).lrc")
        
        if fm.fileExistsAtPath(lrcFilePath) {
            do {
                try fm.removeItemAtPath(lrcFilePath)
            } catch let theError as NSError {
                NSLog("%@", theError.localizedDescription)
                return
            }
        }
        do {
            try lyricsContents.writeToFile(lrcFilePath, atomically: false, encoding: NSUTF8StringEncoding)
        } catch let theError as NSError {
            NSLog("%@", theError.localizedDescription)
        }
    }
    
}








