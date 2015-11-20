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
    var lyricsEidtWindow:LyricsEditWindowController!
    var statusBarItem:NSStatusItem!
    var lyricsArray:[LyricsLineModel]!
    var idTagsArray:[NSString]!
    var operationQueue:NSOperationQueue!
    var iTunes:iTunesBridge!
    var currentLyrics: NSString!
    var currentSongID:NSString!
    var currentSongTitle:NSString!
    var currentArtist:NSString!
    var loadingLrcSongID:NSString!
    var loadingLrcSongTitle:NSString!
    var loadingLrcArtist:NSString!
    var serverSongInfo:NSString!
    var songList:[SongInfos]!
    var qianqian:QianQianAPI!
    var xiami:XiamiAPI!
    var ttpod:TTPodAPI!
    var geciMe:GeciMeAPI!
    var lrcSourceHandleQueue:dispatch_queue_t!
    var userDefaults:NSUserDefaults!
    var timer: NSTimer!
    var timeDly:Int = 0
    var timeDlyInFile:Int = 0
    
// MARK: - Init & deinit
    override init() {
        super.init()
        iTunes = iTunesBridge()
        lyricsArray = Array()
        idTagsArray = Array()
        songList = Array()
        qianqian = QianQianAPI()
        xiami = XiamiAPI()
        ttpod = TTPodAPI()
        geciMe = GeciMeAPI()
        lrcSourceHandleQueue = dispatch_queue_create("HandleLrcSource", DISPATCH_QUEUE_CONCURRENT);
        userDefaults = NSUserDefaults.standardUserDefaults()
        
        NSBundle(forClass: object_getClass(self)).loadNibNamed("StatusMenu", owner: self, topLevelObjects: nil)
        setupStatusItem()
        
        lyricsWindow=LyricsWindowController()
        lyricsWindow.showWindow(nil)
        
        // check lrc saving path
        if !checkSavingPath() {
            let alert: NSAlert = NSAlert()
            alert.messageText = NSLocalizedString("ERROR_OCCUR", comment: "")
            alert.informativeText = NSLocalizedString("PATH_IS_NOT_DIR", comment: "")
            alert.addButtonWithTitle(NSLocalizedString("OPEN_PREFS", comment: ""))
            alert.addButtonWithTitle(NSLocalizedString("IGNORE", comment: ""))
            let response: NSModalResponse = alert.runModal()
            if response == NSAlertFirstButtonReturn {
                showPreferences(nil)
            }
        }
    
        currentLyrics = "LyricsX"
        if iTunes.running() && iTunes.playing() {
            
            currentSongID = iTunes.currentPersistentID().copy() as! NSString
            currentSongTitle = iTunes.currentTitle().copy() as! NSString
            currentArtist = iTunes.currentArtist().copy() as! NSString
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { () -> Void in
                self.handleSongChange()
            }
            
            NSLog("Create new iTunesTrackingThead")
            isTrackingRunning = true
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { () -> Void in
                self.iTunesTrackingThread()
            }
        } else {
            currentSongID = ""
            currentSongTitle = ""
            currentArtist = ""
        }
        
        let nc = NSNotificationCenter.defaultCenter()
        nc.addObserver(self, selector: "lrcLoadingCompleted:", name: LrcLoadedNotification, object: nil)
        nc.addObserver(self, selector: "handleUserEditLyrics:", name: LyricsUserEditLyricsNotification, object: nil)
        
        let ndc = NSDistributedNotificationCenter.defaultCenter()
        ndc.addObserver(self, selector: "iTunesPlayerInfoChanged:", name: "com.apple.iTunes.playerInfo", object: nil)
        ndc.addObserver(self, selector: "handleLrcSeekerEvent:", name: "LrcSeekerEvents", object: nil)
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
    
    @IBAction func checkForUpdate(sender: AnyObject) {
        NSWorkspace.sharedWorkspace().openURL(NSURL(string: "https://github.com/MichaelRow/Lyrics/releases")!)
    }
    
    @IBAction func exportArtwork(sender: AnyObject) {
        let panel = NSSavePanel()
        panel.allowedFileTypes = ["png",  "jpg", "jpf", "bmp", "gif", "tiff"]
        panel.nameFieldStringValue = (currentSongTitle as String) + " - " + (currentArtist as String)
        panel.extensionHidden = true
        if panel.runModal() == NSFileHandlingPanelOKButton {
            iTunes.artwork().writeToURL(panel.URL!, atomically: false)
        }
    }
    
    @IBAction func searchLyricsAndArtworks(sender: AnyObject) {
        let appPath: NSURL = NSBundle.mainBundle().URLForResource("LrcSeeker", withExtension: "app")!
        NSWorkspace.sharedWorkspace().launchApplication(appPath.path!)
    }
    
    @IBAction func copyLyricsToPb(sender: AnyObject) {
        if lyricsArray.count == 0 {
            return
        }
        let theLyrics: NSMutableString = NSMutableString()
        for lrc in lyricsArray {
            theLyrics.appendString(lrc.lyricsSentence as String + "\n")
        }
        let pb = NSPasteboard.generalPasteboard()
        pb.clearContents()
        pb.writeObjects([theLyrics])
    }
    
    @IBAction func copyLyricsWithTagsToPb(sender: AnyObject) {
        let lrcContents = readLocalLyrics()
        if lrcContents != nil {
            let pb = NSPasteboard.generalPasteboard()
            pb.clearContents()
            pb.writeObjects([lrcContents!])
        }
    }
    
    @IBAction func editLyrics(sender: AnyObject) {
        var lrcContents = readLocalLyrics()
        if lrcContents == nil {
            lrcContents = ""
        }
        if lyricsEidtWindow == nil {
            lyricsEidtWindow = LyricsEditWindowController()
        }
        lyricsEidtWindow.setLyricsContents(lrcContents! as String, songID: currentSongID, songTitle: currentSongTitle, andArtist: currentArtist)
        if !(lyricsEidtWindow.window?.visible)! {
            lyricsEidtWindow.showWindow(nil)
        }
        lyricsEidtWindow.window?.makeKeyAndOrderFront(nil)
        NSApp.activateIgnoringOtherApps(true)
    }
    
    @IBAction func importLrcFile(sender: AnyObject) {
        let panel: NSOpenPanel = NSOpenPanel()
        panel.allowedFileTypes = ["lrc", "txt"]
        panel.extensionHidden = false
        if panel.runModal() == NSFileHandlingPanelOKButton {
            let lrcContents: NSString!
            do {
                lrcContents = try NSString(contentsOfURL: panel.URL!, encoding: NSUTF8StringEncoding)

            } catch let theError as NSError {
                lrcContents = nil
                NSLog("%@", theError.localizedDescription)
                return
            }
            if lrcContents != nil && testLrc(lrcContents) {
                parsingLrc(lrcContents)
                saveLrcToLocal(lrcContents, songTitle: currentSongTitle, artist: currentArtist)
            }
        }
    }
    
    @IBAction func exportLrcFile(sender: AnyObject) {
        let savingPath: NSString
        if userDefaults.integerForKey(LyricsSavingPathPopUpIndex) == 0 {
            savingPath = NSSearchPathForDirectoriesInDomains(.MusicDirectory, [.UserDomainMask], true).first! + "/LyricsX"
        } else {
            savingPath = userDefaults.stringForKey(LyricsUserSavingPath)!
        }
        let songTitle:String = currentSongTitle.stringByReplacingOccurrencesOfString("/", withString: "&")
        let artist:String = currentArtist.stringByReplacingOccurrencesOfString("/", withString: "&")
        let lrcFilePath = savingPath.stringByAppendingPathComponent("\(songTitle) - \(artist).lrc")
        
        let panel: NSSavePanel = NSSavePanel()
        panel.allowedFileTypes = ["lrc","txt"]
        panel.nameFieldStringValue = (lrcFilePath as NSString).lastPathComponent as String
        panel.extensionHidden = false
        
        if panel.runModal() == NSFileHandlingPanelOKButton {
            do {
                try NSFileManager.defaultManager().copyItemAtPath(lrcFilePath, toPath: panel.URL!.path!)
            } catch let theError as NSError {
                NSLog("%@", theError.localizedDescription)
            }
        }
    }
    
    @IBAction func writeLyricsToiTunes(sender: AnyObject) {
        if lyricsArray.count == 0 {
            return
        } else {
            let theLyrics: NSMutableString = NSMutableString()
            for lrc in lyricsArray {
                theLyrics.appendString(lrc.lyricsSentence as String + "\n")
            }
            iTunes.setLyrics(theLyrics as String)
        }
    }
    
    
// MARK: - iTunes Events
    
    func iTunesTrackingThread() {
        
        // side node: iTunes update playerPosition once per second.
        var iTunesPosition: Int = 0
        var currentPosition: Int = 0
        
        while true {
            if iTunes.playing() {
                if lyricsArray.count != 0 {
                    iTunesPosition = iTunes.playerPosition()
                    if (currentPosition < iTunesPosition) || ((currentPosition / 1000) != (iTunesPosition / 1000) && currentPosition % 1000 < 850) {
                        currentPosition = iTunesPosition
                    }
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
                        self.handlePositionChange(iTunesPosition)
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
            currentPosition += 150
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
                    
                    // iTunes would paused before quited, so we should check whether iTunes is running
                    // seconds later.
                    if timer != nil {
                        timer.invalidate()
                    }
                    timer = NSTimer.scheduledTimerWithTimeInterval(3, target: self, selector: "terminate", userInfo: nil, repeats: false)
                }
                return
            }
            else if userInfo!["Player State"] as! String == "Playing" {
                
                //iTunes is playing now, we should create the tracking thread if not exists.
                if !isTrackingRunning {
                    NSLog("Create new iTunesTrackingThead")
                    isTrackingRunning = true
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { () -> Void in
                        self.iTunesTrackingThread()
                    }
                }
                NSLog("iTunes Playing")
            }
            
            // check whether song is changed
            if currentSongID == iTunes.currentPersistentID() {
                return
            } else {
                
                //if time-Delay for the previous song is changed, we should save the change to lrc file.
                //Save time-Delay laziely for better I/O performance.
                if timeDly != timeDlyInFile {
                    handleLrcDelayChange()
                }
                
                lyricsArray.removeAll()
                idTagsArray.removeAll()
                self.setValue(0, forKey: "timeDly")
                timeDlyInFile = 0
                lyricsWindow.displayLyrics(nil, secondLyrics: nil)
                currentSongID = iTunes.currentPersistentID().copy() as! NSString
                currentSongTitle = iTunes.currentTitle().copy() as! NSString
                currentArtist = iTunes.currentArtist().copy() as! NSString
                NSLog("Song Changed to: %@",currentSongTitle)
                handleSongChange()
            }
        }
    }

    
// MARK: - Lrc Methods
    
    func parsingLrc(theLrcContents:NSString) {
        
        // Parse lrc file to get lyrics, time-tags and time offset
        NSLog("Start to Parse lrc")
        lyricsArray.removeAll()
        idTagsArray.removeAll()
        self.setValue(0, forKey: "timeDly")
        timeDlyInFile = 0
        let lrcContents: NSString
        
        // whether convert Chinese type
        if userDefaults.boolForKey(LyricsAutoConvertChinese) {
            switch userDefaults.integerForKey(LyricsChineseTypeIndex) {
            case 0:
                lrcContents = convertToSC(theLrcContents)
            case 1:
                lrcContents = convertToTC(theLrcContents)
            case 2:
                lrcContents = convertToTC_Taiwan(theLrcContents)
            case 3:
                lrcContents = convertToTC_HK(theLrcContents)
            default:
                lrcContents = theLrcContents
                break
            }
        } else {
            lrcContents = theLrcContents
        }
        let newLineCharSet: NSCharacterSet = NSCharacterSet.newlineCharacterSet()
        let lrcParagraphs: NSArray = lrcContents.componentsSeparatedByCharactersInSet(newLineCharSet)
        let regexForTimeTag: NSRegularExpression
        let regexForIDTag: NSRegularExpression
        do {
            regexForTimeTag = try NSRegularExpression(pattern: "\\[[0-9]+:[0-9]+.[0-9]+\\]|\\[[0-9]+:[0-9]+\\]", options: [])
        } catch let theError as NSError {
            NSLog("%@", theError.localizedDescription)
            return
        }
        
        do {
            regexForIDTag = try NSRegularExpression(pattern: "\\[.*:.*\\]", options: [])
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
                if idStr != "offset".stringByReplacingOccurrencesOfString(" ", withString: "") {
                    idTagsArray.append(str as! NSString)
                    continue
                }
                else {
                    let delayStr: NSString=theIDTag.substringWithRange(NSMakeRange(colonRange.location+1, theIDTag.length-colonRange.length-colonRange.location-1))
                    self.setValue(delayStr.integerValue, forKey: "timeDly")
                    timeDlyInFile = timeDly
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

// MARK: - Handle Events
    
    func handlePositionChange (playerPosition: Int) {
        let tempLyricsArray = lyricsArray
        var index: Int
        for index=0; index < tempLyricsArray.count; ++index {
            if playerPosition < tempLyricsArray[index].msecPosition - timeDly {
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
                    var secondLyrics: NSString!
                    if currentLyrics != tempLyricsArray[index-1].lyricsSentence {
                        currentLyrics = tempLyricsArray[index-1].lyricsSentence
                        if userDefaults.boolForKey(LyricsTwoLineMode) && index < tempLyricsArray.count {
                            if tempLyricsArray[index].lyricsSentence != "" {
                                secondLyrics = tempLyricsArray[index].lyricsSentence
                            }
                        }
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            self.lyricsWindow.displayLyrics(tempLyricsArray[index-1].lyricsSentence, secondLyrics: secondLyrics)
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
    
    
    func handleSongChange() {
        //load lyrics for the song which is about to play
        let lrcContents: NSString? = readLocalLyrics()
        if lrcContents != nil {
            parsingLrc(lrcContents!)
            if lyricsArray.count != 0 {
                return
            }
        }
        
        //Search in the net if local lrc is nil or invalid
        loadingLrcSongID = currentSongID.copy() as! NSString
        loadingLrcArtist = currentArtist.copy() as! NSString
        loadingLrcSongTitle = currentSongTitle.copy() as! NSString
        serverSongInfo = nil
        
        let titleForSearch: String = delSpecificSymbol(currentSongTitle) as String
        let artistForSearch: String = delSpecificSymbol(currentArtist) as String
        qianqian.getLyricsWithTitle(convertToSC(titleForSearch) as String, artist: convertToSC(artistForSearch) as String)
        xiami.getLyricsWithTitle(titleForSearch, artist: artistForSearch)
        ttpod.getLyricsWithTitle(titleForSearch, artist: artistForSearch)
        geciMe.getLyricsWithTitle(titleForSearch, artist: artistForSearch)
    }
    
    
    func handleUserEditLyrics(n: NSNotification) {
        let userInfo: [NSObject:AnyObject] = n.userInfo!
        if (userInfo["SongID"] as! String) == currentSongID {
            parsingLrc(lyricsEidtWindow.textView.string!)
        }
        saveLrcToLocal(lyricsEidtWindow.textView.string!, songTitle: userInfo["SongTitle"] as! String, artist: userInfo["SongArtist"] as! String)
    }
    
    
    func handleLrcDelayChange () {
        if lyricsArray.count == 0{
            return
        }
        let theLyrics: NSMutableString = NSMutableString()
        for idtag in idTagsArray {
            theLyrics.appendString((idtag as String) + "\n")
        }
        theLyrics.appendString("[offset:\(timeDly)]\n")
        for lrc in lyricsArray {
            theLyrics.appendString((lrc.timeTag as String) + (lrc.lyricsSentence as String) + "\n")
        }
        if lyricsArray.count > 0 {
            theLyrics.deleteCharactersInRange(NSMakeRange(theLyrics.length-1, 1))
        }
        NSLog("Writing the time delay to file")
        saveLrcToLocal(theLyrics, songTitle: currentSongTitle, artist: currentArtist)
    }
    
    func handleLrcSeekerEvent (n:NSNotification) {
        NSLog("Recieved notification from LrcSeeker")
        let userInfo = n.userInfo
        dispatch_barrier_async(lrcSourceHandleQueue, { () -> Void in
            let lyricsContents: String = userInfo!["LyricsContents"] as! String
            if self.testLrc(lyricsContents) {
                self.parsingLrc(lyricsContents)
                self.serverSongInfo = (userInfo!["SongTitle"] as! String) + (userInfo!["Artist"] as! String)
                self.saveLrcToLocal(lyricsContents, songTitle: self.currentSongTitle, artist: self.currentArtist)
            }
        })
    }
    
// MARK: - Lyrics Source Loading Completion
    
    func isBetterLrc(serverSongTitle: NSString) -> Bool {
        if serverSongTitle.rangeOfString("中").location != NSNotFound || serverSongTitle.rangeOfString("对照").location != NSNotFound || serverSongTitle.rangeOfString("双").location != NSNotFound {
            return true
        }
        return false
    }
    
    
    func lrcLoadingCompleted(n: NSNotification) {
        
        // we should run the handle thread one by one using dispatch_barrier_async()
        let source: Int = n.userInfo!["source"]!.integerValue
        switch source {
        case 1:
            dispatch_barrier_async(lrcSourceHandleQueue, { () -> Void in
                self.handleLrcURLDownloaded(self.qianqian.songs)
            })
        case 2:
            dispatch_barrier_async(lrcSourceHandleQueue, { () -> Void in
                self.handleLrcURLDownloaded(self.xiami.songs)
            })
        case 3:
            dispatch_barrier_async(lrcSourceHandleQueue, { () -> Void in
                self.handleLrcContentsDownloaded(self.ttpod.songInfo.lyric)
            })
        case 4:
            dispatch_barrier_async(lrcSourceHandleQueue, { () -> Void in
                self.handleLrcURLDownloaded(self.geciMe.songs)
            })
        default:
            return;
        }
    }
    
    
    func handleLrcURLDownloaded(serverLrcs: NSArray) {
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
            betterLrc = nil
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
            if loadingLrcSongID == currentSongID {
                serverSongInfo = betterLrc.songTitle + betterLrc.artist
                parsingLrc(lyricsContents)
            }
            saveLrcToLocal(lyricsContents, songTitle: loadingLrcSongTitle, artist: loadingLrcArtist)
        }
    }
    
    
    func handleLrcContentsDownloaded(lyricsContents: NSString) {
        if serverSongInfo != nil {
            return
        }
        if !testLrc(lyricsContents) {
            return
        }
        serverSongInfo = loadingLrcSongTitle
        if loadingLrcSongID == currentSongID {
            parsingLrc(lyricsContents)
        }
        if lyricsArray.count  == 0 {
            return
        }
        saveLrcToLocal(lyricsContents, songTitle: loadingLrcSongTitle, artist: loadingLrcArtist)
    }
    
// MARK: Other Methods
    
    func terminate() {
        if !iTunes.running() {
            NSApplication.sharedApplication().terminate(self)
        }
    }
    
    
    func saveLrcToLocal (lyricsContents: NSString, songTitle: NSString, artist: NSString) {
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
        
        let titleForSaving = songTitle.stringByReplacingOccurrencesOfString("/", withString: "&")
        let artistForSaving = artist.stringByReplacingOccurrencesOfString("/", withString: "&")
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
    
    
    func delSpecificSymbol(input: NSString) -> NSString {
        let specificSymbol: [String] = [
            ",", ".", "'", "\"", "`", "~", "!", "@", "#", "$", "%", "^", "&", "＆", "*", "(", ")", "（", "）", "，",
            "。", "“", "”", "‘", "’", "?", "？", "！", "/", "[", "]", "{", "}", "<", ">", "=", "-", "+", "×",
            "☆", "★", "√", "～"
        ]
        let output: NSMutableString = input.mutableCopy() as! NSMutableString
        for symbol in specificSymbol {
            output.replaceOccurrencesOfString(symbol, withString: " ", options: [], range: NSMakeRange(0, output.length))
        }
        return output
    }
    
    
    func readLocalLyrics() -> NSString? {
        let savingPath: NSString
        if userDefaults.integerForKey(LyricsSavingPathPopUpIndex) == 0 {
            savingPath = NSSearchPathForDirectoriesInDomains(.MusicDirectory, [.UserDomainMask], true).first! + "/LyricsX"
        } else {
            savingPath = userDefaults.stringForKey(LyricsUserSavingPath)!
        }
        let songTitle:String = currentSongTitle.stringByReplacingOccurrencesOfString("/", withString: "&")
        let artist:String = currentArtist.stringByReplacingOccurrencesOfString("/", withString: "&")
        let lrcFilePath = savingPath.stringByAppendingPathComponent("\(songTitle) - \(artist).lrc")
        if  NSFileManager.defaultManager().fileExistsAtPath(lrcFilePath) {
            let lrcContents: NSString?
            do {
                lrcContents = try NSString(contentsOfFile: lrcFilePath, encoding: NSUTF8StringEncoding)
            } catch {
                lrcContents = nil
                NSLog("Failed to load lrc")
            }
            return lrcContents
        } else {
            return nil
        }
    }
    
}

