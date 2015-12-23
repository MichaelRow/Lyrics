//
//  MainWindowController.swift
//  LrcMaker
//
//  Created by Eru on 15/12/7.
//  Copyright © 2015年 Eru. All rights reserved.
//

import Cocoa
import AVFoundation
import QuartzCore

class MainWindowController: NSWindowController, NSXMLParserDelegate {
    
    var iTunes: iTunesBridge!
    
    // xml parser
    var persistentID: String!
    var currentKey: String!
    var currentString: String!
    var whetherGetPath: Bool = false
    
    // player
    var player: AVAudioPlayer!
    var duration: Int = 0
    var currentPosition: Int = 0
    var timeTagUpdateTimer: NSTimer!
    @IBOutlet weak var playPauseButton: NSButton!
    @IBOutlet weak var playerSlider: NSSlider!
    @IBOutlet weak var positionLabel: NSTextField!
    
    // lyrics Making
    var lyricsArray: [String]!
    var lrcLineArray: [LyricsLineModel]!
    var lyricsView: LyricsView!
    var currentLine: Int = -1
    var isSaved: Bool = false
    
    var currentView: Int = 1
    @IBOutlet var textView: TextView!
    @IBOutlet weak var scrollView: NSScrollView!
    @IBOutlet weak var box: NSBox!
    @IBOutlet weak var firstView: NSView!
    @IBOutlet weak var secondView: NSView!
    @IBOutlet weak var songTitle: NSTextField!
    @IBOutlet weak var artist: NSTextField!
    @IBOutlet weak var album: NSTextField!
    @IBOutlet weak var maker: NSTextField!
    @IBOutlet weak var path: NSPathControl!
    @IBOutlet weak var lyricsXButton: NSButton!
    @IBOutlet weak var saveButton: NSButton!
    
    convenience init() {
        self.init(windowNibName:"MainWindow")
        self.window?.makeMainWindow()
        iTunes = iTunesBridge()
        switchToView(firstView, animated: false)
        lrcLineArray = [LyricsLineModel]()
        
        lyricsView = LyricsView(frame: scrollView.frame)
        scrollView.documentView = lyricsView
        let musicPath = NSSearchPathForDirectoriesInDomains(.MusicDirectory, [.UserDomainMask], true).first!
        path.URL = NSURL(string: musicPath)
        
        self.showWindow(nil)
    }
    
    override func windowDidLoad() {
        self.window?.makeKeyAndOrderFront(nil)
    }
    
    //MARK: - Switch Views
    
    func switchToView(view: NSView, animated: Bool) {
        let boxSize:NSSize = box.contentView!.frame.size
        let newSize:NSSize = view.frame.size
        let deltaW:CGFloat = newSize.width - boxSize.width
        let deltaH:CGFloat = newSize.height - boxSize.height
        var windowFrame:NSRect = self.window!.frame
        let y:CGFloat = box.frame.origin.y
        
        windowFrame.size.height += deltaH
        windowFrame.size.width += deltaW
        windowFrame.origin.y -= deltaH
        
        box.contentView = nil
        box.frame.size = newSize
        self.window!.setFrame(windowFrame, display: true, animate: animated)
        box.contentView = view
        box.contentView?.frame.size=newSize
        box.frame.origin.y = y
    }
    
    @IBAction func switchToFirstView(sender: AnyObject) {
        if currentView == 2 {
            if lrcLineArray.count > 0 && !isSaved {
                let alert: NSAlert = NSAlert()
                alert.messageText = NSLocalizedString("NOT_SAVE", comment: "")
                alert.informativeText = NSLocalizedString("CHECK_LEAVE", comment: "")
                alert.addButtonWithTitle(NSLocalizedString("CANCEL", comment: ""))
                alert.addButtonWithTitle(NSLocalizedString("LEAVE", comment: ""))
                alert.beginSheetModalForWindow(self.window!, completionHandler: { (response) -> Void in
                    if response == NSAlertSecondButtonReturn {
                        self.switchToView(self.firstView, animated: true)
                        self.currentView = 1
                        self.lrcLineArray.removeAll()
                    }
                })
                return
            }
        }
        switchToView(firstView, animated: true)
        currentView = 1
        lrcLineArray.removeAll()
    }
    
    @IBAction func switchSecondView(sender: AnyObject) {
        if player == nil {
            NSBeep()
            ErrorWindowController.sharedErrorWindow.displayError(NSLocalizedString("NO_SONG", comment: ""))
            return
        }
        if songTitle.stringValue.stringByReplacingOccurrencesOfString(" ", withString: "") == "" {
            NSBeep()
            ErrorWindowController.sharedErrorWindow.displayError(NSLocalizedString("NO_TITLE", comment: ""))
            return
        }
        lyricsArray = textView.string!.componentsSeparatedByCharactersInSet(NSCharacterSet.newlineCharacterSet())
        var isEmpty: Bool = true
        var i: Int = 0
        while i < lyricsArray.count {
            if lyricsArray[i].stringByReplacingOccurrencesOfString(" ", withString: "") == "" {
                lyricsArray.removeAtIndex(i)
                continue
            } else {
                isEmpty = false
            }
            ++i
        }
        if isEmpty {
            ErrorWindowController.sharedErrorWindow.displayError(NSLocalizedString("NO_LYRICS", comment: ""))
            return
        }
        lyricsView.setLyricsLayerWithArray(lyricsArray)
        scrollView.contentView.scrollToPoint(lyricsView.frame.origin)
        switchToView(secondView, animated: true)
        currentView = 2
        currentLine = -1
        lyricsXButton.enabled = false
        saveButton.enabled = false
        isSaved = false
        player.currentTime = 0
        play()
    }
    
    //MARK: - Player Controller
    
    @IBAction func playPause(sender: AnyObject?) {
        if player == nil {
            return
        }
        if player.playing {
            pause()
        } else {
            play()
        }
    }
    
    func play() {
        NSLog("Player is playing")
        iTunes.pause()
        player.play()
        if timeTagUpdateTimer == nil {
            timeTagUpdateTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: "updateTimeTag", userInfo: nil, repeats: true)
        } else {
            timeTagUpdateTimer.fireDate = NSDate()
        }
        playPauseButton.image = NSImage(named: "pause_icon")
        playPauseButton .toolTip = NSLocalizedString("PAUSE", comment: "")
    }
    
    func pause() {
        NSLog("Player paused")
        player.pause()
        if timeTagUpdateTimer != nil {
            timeTagUpdateTimer.fireDate = NSDate.distantFuture()
        }
        playPauseButton.image = NSImage(named: "play_icon")
        playPauseButton .toolTip = NSLocalizedString("PLAY", comment: "")
    }
    
    @IBAction func jumpToTime(sender: AnyObject) {
        let timePoint: Int = Int((sender as! NSSlider).doubleValue)
        player.currentTime = Double(timePoint) / 1000
        updateTimeTag()
        
        // In the 2nd View
        if currentView == 2 && lrcLineArray.count > 0 {
            if timePoint < lrcLineArray.last?.msecPosition {
                lyricsXButton.enabled = false
                saveButton.enabled = false
                isSaved = false
                
                var i: Int = 0
                var lrcCount: Int = 0
                while i < lrcLineArray.count {
                    if lrcLineArray[i].msecPosition > timePoint {
                        lrcLineArray.removeRange(i...lrcLineArray.count-1)
                        break
                    }
                    else {
                        if lrcLineArray[i].lyricsSentence != "" {
                            lrcCount++
                        }
                    }
                    i++
                }
                if lrcLineArray.count > 0 {
                    currentLine = lrcCount - 1
                    if lrcLineArray.last?.lyricsSentence == "" {
                        lyricsView.setHighlightedAtIndex(currentLine, andStyle: 2)
                    }
                    else {
                        lyricsView.setHighlightedAtIndex(currentLine, andStyle: 1)
                    }
                }
                else {
                    currentLine = -1
                    lyricsView.unsetHighlighted()
                }
            }
            scrollViewToFit()
        }
    }
    
    func updateTimeTag() {
        self.setValue(Int(player.currentTime * 1000), forKey: "currentPosition")
        
        let currentSec = currentPosition / 1000 % 60
        let currentMin = currentPosition / 60000
        let durationSec = duration / 1000 % 60
        let durationMin = duration / 60000
        
        let currentSecStr: String
        let currentMinStr: String
        let durationSecStr: String
        let durationMinStr: String
        
        if currentSec < 10 {
            currentSecStr = "0\(currentSec)"
        } else {
            currentSecStr = "\(currentSec)"
        }
        
        if currentMin < 10 {
            currentMinStr = "0\(currentMin)"
        } else {
            currentMinStr = "\(currentMin)"
        }
        
        if durationSec < 10 {
            durationSecStr = "0\(durationSec)"
        } else {
            durationSecStr = "\(durationSec)"
        }
        
        if durationMin < 10 {
            durationMinStr = "0\(durationMin)"
        } else {
            durationMinStr = "\(durationMin)"
        }
        
        positionLabel.stringValue = currentMinStr + ":" + currentSecStr + "/" + durationMinStr + ":" + durationSecStr
        
        if !player.playing {
            pause()
        }
    }
    
    //MARK: - Music Source
    
    @IBAction func setSongFromiTunes(sender: AnyObject) {
        (sender as! NSButton).enabled = false
        if iTunes.running() {
            songTitle.stringValue = iTunes.currentTitle()
            artist.stringValue = iTunes.currentArtist()
            album.stringValue = iTunes.currentAlbum()
            
            persistentID = (iTunes.currentPersistentID() as NSString).copy() as! String
            if persistentID == "" {
                (sender as! NSButton).enabled = true
                return
            }
            playPause(nil)
            let fm: NSFileManager = NSFileManager.defaultManager()
            let iTunesLibrary: String = NSSearchPathForDirectoriesInDomains(.MusicDirectory, [.UserDomainMask], true).first! + "/iTunes/iTunes Music Library.xml"
            if fm.fileExistsAtPath(iTunesLibrary) {
                let data: NSData = NSData(contentsOfFile: iTunesLibrary)!
                let parser: NSXMLParser = NSXMLParser(data: data)
                parser.delegate = self
                whetherGetPath = false
                currentKey = ""
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
                    if parser.parse() == false {
                        NSLog("%@", parser.parserError!)
                    }
                    
                    do {
                        self.player = try AVAudioPlayer(contentsOfURL: self.path.URL!)
                    } catch let theError as NSError {
                        NSLog("%@", theError.localizedDescription)
                        (sender as! NSButton).enabled = true
                        return
                    }
                    self.player.prepareToPlay()
                    NSLog("Song changed")
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.setValue(Int(self.player.duration * 1000), forKeyPath: "self.duration")
                        self.setValue(0, forKey: "currentPosition")
                        self.updateTimeTag()
                        if NSUserDefaults.standardUserDefaults().boolForKey("LMPlayWhenAdded") {
                            self.play()
                        }
                        (sender as! NSButton).enabled = true
                    })
                })
            }
        }
    }
    
    @IBAction func setSongInOpenPanel(sender: AnyObject) {
        let openPanel = NSOpenPanel()
        openPanel.allowedFileTypes = ["mp3", "m4a", "wav", "aiff"]
        openPanel.extensionHidden = false
        openPanel.beginSheetModalForWindow(self.window!) { (response) -> Void in
            if response == NSFileHandlingPanelOKButton {
                self.songTitle.stringValue = ""
                self.artist.stringValue = ""
                self.album.stringValue = ""
                self.path.URL = openPanel.URL
                do {
                    self.player = try AVAudioPlayer(contentsOfURL: openPanel.URL!)
                } catch let theError as NSError {
                    NSLog("%@", theError.localizedDescription)
                    return
                }
                NSLog("Song changed")
                let asset = AVURLAsset(URL: self.path.URL!, options: nil)
                asset.loadValuesAsynchronouslyForKeys(["commonMetadata"], completionHandler: { () -> Void in
                    let metadatas: [AVMetadataItem]
                    if openPanel.URL?.pathExtension == "mp3" {
                        metadatas = AVMetadataItem.metadataItemsFromArray(asset.commonMetadata, withKey: nil, keySpace: AVMetadataKeySpaceID3)
                    }
                    else {
                        metadatas = AVMetadataItem.metadataItemsFromArray(asset.commonMetadata, withKey: nil, keySpace: AVMetadataKeySpaceiTunes)
                    }
                    for md in metadatas {
                        switch md.commonKey! {
                        case "title":
                            self.songTitle.stringValue = md.value as! String
                        case "artist":
                            self.artist.stringValue = md.value as! String
                        case "albumName":
                            self.album.stringValue = md.value as! String
                        default:
                            break
                        }
                    }
                })
                self.setValue(Int(self.player.duration * 1000), forKey: "duration")
                self.setValue(0, forKey: "currentPosition")
                self.player.prepareToPlay()
                self.updateTimeTag()
                if NSUserDefaults.standardUserDefaults().boolForKey("LMPlayWhenAdded") {
                    self.play()
                }
            }
        }
    }
    
    //MARK: - Save lrc
    
    @IBAction func saveLrc(sender: AnyObject) {
        let panel = NSSavePanel()
        panel.allowedFileTypes = ["lrc"]
        panel.nameFieldStringValue = songTitle.stringValue + " - " + artist.stringValue + ".lrc"
        panel.extensionHidden = false
        panel.beginSheetModalForWindow(self.window!) { (response) -> Void in
            if response == NSFileHandlingPanelOKButton {
                let lrcContent: NSString = self.generateLrc()
                let fm = NSFileManager.defaultManager()
                if fm.fileExistsAtPath(panel.URL!.path!) {
                    do {
                        try fm.removeItemAtPath(panel.URL!.path!)
                    } catch let theError as NSError {
                        NSLog("%@", theError.localizedDescription)
                        return
                    }
                }
                do {
                    try lrcContent.writeToURL(panel.URL!, atomically: false, encoding: NSUTF8StringEncoding)
                } catch let theError as NSError {
                    NSLog("%@", theError.localizedDescription)
                    return
                }
                self.isSaved = true
            }
        }
    }
    
    @IBAction func sendLrcToLyricsX(sender: AnyObject) {
        let lrcContent: NSString = generateLrc()
        let userInfo: [String:AnyObject] = ["SongTitle" : songTitle.stringValue,
            "Artist" : artist.stringValue,
            "Sender" : "LrcMaker",
            "LyricsContents" : lrcContent]
        NSDistributedNotificationCenter.defaultCenter().postNotificationName("ExtenalLyricsEvent", object: nil, userInfo: userInfo, deliverImmediately: true)
    }
    
    func generateLrc() -> NSString {
        let lrcContent: NSMutableString = NSMutableString()
        if self.songTitle.stringValue.stringByReplacingOccurrencesOfString(" ", withString: "") != "" {
            lrcContent.appendString("[ti:" + self.songTitle.stringValue + "]\n")
        }
        if self.artist.stringValue.stringByReplacingOccurrencesOfString(" ", withString: "") != "" {
            lrcContent.appendString("[ar:" + self.artist.stringValue + "]\n")
        }
        if self.album.stringValue.stringByReplacingOccurrencesOfString(" ", withString: "") != "" {
            lrcContent.appendString("[al:" + self.album.stringValue + "]\n")
        }
        if self.maker.stringValue.stringByReplacingOccurrencesOfString(" ", withString: "") != "" {
            lrcContent.appendString("[by:" + self.maker.stringValue + "]\n")
        }
        lrcContent.appendString("[tool:LrcMaker]\n")
        for lrcLine in self.lrcLineArray {
            let str = NSString(format: "%@%@\n", lrcLine.timeTag!,lrcLine.lyricsSentence)
            lrcContent.appendString(str as String)
        }
        return lrcContent
    }
    
    // MARK: - Keyboard Events
    
    override func keyDown(theEvent: NSEvent) {
        if currentView == 1 {
            super.keyDown(theEvent)
        }
        else {
            switch theEvent.keyCode {
            case 123: //left arrow
                endCurrentLine()
            case 125: //down arrow
                nextLine()
            case 126: //up arrow
                previousLine()
            default:
                super.keyDown(theEvent)
            }
        }
    }
    
    // Lyrics Making Methods
    func nextLine() {
        let msecPosition: Int = Int(player.currentTime * 1000)
        // Not allow two lyrics in the same time point
        if lrcLineArray.count > 0 && lrcLineArray.last!.msecPosition == msecPosition {
            ErrorWindowController.sharedErrorWindow.displayError(NSLocalizedString("DUPLICATE_IN_T_PT", comment: ""))
            NSBeep()
            return
        }
        // Current line is last line
        if currentLine == lyricsArray.count - 1 {
            endCurrentLine()
            return
        }
        NSLog("Add New Lrc Line")
        currentLine++
        let lrcLine = LyricsLineModel()
        lrcLine.lyricsSentence = lyricsArray[currentLine]
        lrcLine.setTimeTagWithMsecPosition(msecPosition)
        lrcLineArray.append(lrcLine)
        lyricsView.setHighlightedAtIndex(currentLine, andStyle: 1)
        
        scrollViewToFit()
    }
    
    func endCurrentLine() {
        if lrcLineArray.count == 0 || lrcLineArray.last!.lyricsSentence == "" {
            NSBeep()
            return
        }
        NSLog("End Current Lyrics")
        if currentLine == lyricsArray.count - 1 {
            lyricsXButton.enabled = true
            saveButton.enabled = true
        }
        let msecPosition: Int = Int(player.currentTime * 1000)
        let lrcLine: LyricsLineModel = LyricsLineModel()
        lrcLine.lyricsSentence = ""
        lrcLine.setTimeTagWithMsecPosition(msecPosition)
        lrcLineArray.append(lrcLine)
        lyricsView.setHighlightedAtIndex(currentLine, andStyle: 2)
    }
    
    func previousLine() {
        if lrcLineArray.count == 0 {
            NSBeep()
            return
        }
        var timePoint: Int = (lrcLineArray.last?.msecPosition)! - 2000
        if lrcLineArray.last?.lyricsSentence != "" {
            currentLine--
        }
        
        lrcLineArray.removeLast()
        lyricsXButton.enabled = false
        saveButton.enabled = false
        isSaved = false
        
        if timePoint < 0 {
            timePoint = 0
        }
        if lrcLineArray.count > 0 {
            let tp: Int = lrcLineArray.last!.msecPosition!
            if tp > timePoint {
                timePoint = tp
            }
            if lrcLineArray.last!.lyricsSentence == "" {
                lyricsView.setHighlightedAtIndex(currentLine, andStyle: 2)
            }
            else {
                lyricsView.setHighlightedAtIndex(currentLine, andStyle: 1)
            }
        }
        else {
            lyricsView.unsetHighlighted()
        }
        player.currentTime = Double(timePoint/1000)
        player.play()
        
        scrollViewToFit()
    }
    
    func scrollViewToFit() {
        let viewOrigin: NSPoint = lyricsView.frame.origin
        if currentLine < 4 {
            scrollView.contentView.scrollToPoint(viewOrigin)
        }
        else if lyricsArray.count-currentLine < 5 {
            scrollView.contentView.scrollToPoint(NSMakePoint(viewOrigin.x, viewOrigin.y+CGFloat(lyricsArray.count-7)*lyricsView.height))
        }
        else {
            scrollView.contentView.scrollToPoint(NSMakePoint(viewOrigin.x, viewOrigin.y+CGFloat(currentLine-3)*lyricsView.height))
        }
    }
    
    //MARK: - XML Parser Delegate
    func parser(parser: NSXMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "key" {
            let trimmed = currentString.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
            currentKey = trimmed
        } else if currentString != nil {
            let trimmed = currentString.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
            if currentKey == "Persistent ID" && trimmed == persistentID {
                whetherGetPath = true
            }
            if whetherGetPath && currentKey == "Location" {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.path.URL = NSURL(string: trimmed)
                })
                whetherGetPath = false
            }
        }
        currentString = nil
    }
    
    func parser(parser: NSXMLParser, foundCharacters string: String) {
        if currentString == nil {
            currentString = String()
        }
        currentString = currentString + string
    }
    
}
