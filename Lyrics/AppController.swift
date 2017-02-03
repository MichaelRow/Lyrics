//
//  AppController.swift
//  Lyrics
//
//  Created by Eru on 15/11/10.
//  Copyright © 2015年 Eru. All rights reserved.
//

import Cocoa
import ScriptingBridge

class AppController: NSObject, NSUserNotificationCenterDelegate {
    
    //Singleton
    static let sharedController = AppController()
    
    @IBOutlet weak var statusBarMenu: NSMenu!
    @IBOutlet weak var lyricsDelayView: NSView!
    @IBOutlet weak var delayMenuItem: NSMenuItem!
    @IBOutlet weak var presetMenuItem: NSMenuItem!
    
    var timeDly: Int = 0
    var timeDlyInFile: Int = 0
    var lockFloatingWindow: Bool = false
    
    fileprivate var isTrackingRunning: Bool = false
    fileprivate var hasDiglossiaLrc: Bool = false
    fileprivate var lyricsWindow: DesktopLyricsController!
    fileprivate var menuBarLyrics: MenuBarLyrics!
    fileprivate var statusItem: NSStatusItem!
    fileprivate var lyricsArray: [LyricsLineModel]!
    fileprivate var idTagsArray: [String]!
    fileprivate var iTunes: iTunesBridge!
    fileprivate var currentLyrics: String!
    fileprivate var currentSongID: String!
    fileprivate var currentSongTitle: String!
    fileprivate var currentArtist: String!
    fileprivate var lrcParser: LrcParser!
    fileprivate var songList: [SongInfos]!
    fileprivate var qianqian: QianQian!
    fileprivate var xiami: Xiami!
    fileprivate var ttpod: TTPod!
    fileprivate var geciMe: GeCiMe!
    fileprivate var qqMusic: QQMusic!
    fileprivate var lrcSourceHandleQueue: OperationQueue!
    fileprivate var userDefaults: UserDefaults!
    fileprivate var timer: Timer!

    static func initSharedAppController() {
        _ = self.sharedController
    }

// MARK: - Init & deinit
    override fileprivate init() {
        super.init()
        iTunes = iTunesBridge()
        lrcParser = LrcParser()
        lyricsArray = Array()
        idTagsArray = Array()
        songList = Array()
        qianqian = QianQian()
        xiami = Xiami()
        ttpod = TTPod()
        geciMe = GeCiMe()
        qqMusic = QQMusic()
        userDefaults = UserDefaults.standard
        lrcSourceHandleQueue = OperationQueue()
        lrcSourceHandleQueue.maxConcurrentOperationCount = 1
        
        Bundle(for: object_getClass(self)).loadNibNamed("StatusMenu", owner: self, topLevelObjects: nil)
        
        // init desktop lyrics and menu lyrics
        lyricsWindow = DesktopLyricsController.sharedController
        lyricsWindow.showWindow(nil)
        if userDefaults.bool(forKey: LyricsMenuBarLyricsEnabled) {
            menuBarLyrics = MenuBarLyrics()
        }
        
        setupStatusItem()
        checkLrcSavingPath()
        setupShortcuts()
        addNotificationObserver()
        trackingStatusInitiation()
    }
    
    deinit {
        NSStatusBar.system().removeStatusItem(statusItem)
        NotificationCenter.default.removeObserver(self)
        DistributedNotificationCenter.default().removeObserver(self)
    }
    
    fileprivate func setupStatusItem() {
        let icon:NSImage = NSImage(named: "status_icon")!
        icon.isTemplate = true
        statusItem = NSStatusBar.system().statusItem(withLength: NSSquareStatusItemLength)
        statusItem.menu = statusBarMenu
        if #available(OSX 10.10, *) {
            statusItem.button?.image = icon
        } else {
            statusItem.image = icon
            statusItem.highlightMode = true
        }
    
        delayMenuItem.view = lyricsDelayView
        lyricsDelayView.autoresizingMask = [.viewWidthSizable]
    }
    
    fileprivate func checkLrcSavingPath() {
        if !userDefaults.bool(forKey: LyricsDisableAllAlert) {
            let savingPath: String
            if userDefaults.integer(forKey: LyricsSavingPathPopUpIndex) == 0 {
                savingPath = NSSearchPathForDirectoriesInDomains(.musicDirectory, [.userDomainMask], true).first! + "/LyricsX"
            } else {
                savingPath = userDefaults.string(forKey: LyricsUserSavingPath)!
            }
            
            let fm: FileManager = FileManager.default
            var isDir = ObjCBool(true)
            if fm.fileExists(atPath: savingPath, isDirectory: &isDir) {
                //歌词保存路径是非文件夹，弹出警示
                if !isDir.boolValue {
                    userDefaults.removeObject(forKey: LyricsUserSavingPath)
                    userDefaults.removeObject(forKey: LyricsSavingPathPopUpIndex)
                    let alert: NSAlert = NSAlert()
                    alert.messageText = NSLocalizedString("ERROR_OCCUR", comment: "")
                    alert.informativeText = NSLocalizedString("PATH_IS_NOT_DIR", comment: "")
                    alert.addButton(withTitle: NSLocalizedString("OPEN_PREFS", comment: ""))
                    let response: NSModalResponse = alert.runModal()
                    if response == NSAlertFirstButtonReturn {
                        DispatchQueue.main.async(execute: {
                            self.showPreferences(nil)
                        })
                    }
                }
            } else {
                //歌词保存路径没有文件夹，创建一个
                do {
                    try fm.createDirectory(atPath: savingPath, withIntermediateDirectories: true, attributes: nil)
                } catch let theError as NSError{
                    NSLog("%@", theError.localizedDescription)
                }
            }
        }
    }
    
    fileprivate func addNotificationObserver() {
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(lrcLoadingCompleted(_:)), name: NSNotification.Name.LrcLoaded, object: nil)
        nc.addObserver(self, selector: #selector(handleUserEditLyrics(_:)), name: NSNotification.Name(rawValue: LyricsUserEditLyricsNotification), object: nil)
        nc.addObserver(self, selector: #selector(handlePresetDidChanged), name: NSNotification.Name(rawValue: LyricsPresetDidChangedNotification), object: nil)
        
        let ndc = DistributedNotificationCenter.default()
        ndc.addObserver(self, selector: #selector(iTunesPlayerInfoChanged(_:)), name: NSNotification.Name(rawValue: "com.apple.iTunes.playerInfo"), object: nil)
        ndc.addObserver(self, selector: #selector(handleExtenalLyricsEvent(_:)), name: NSNotification.Name(rawValue: "ExtenalLyricsEvent"), object: nil)
    }
    
    fileprivate func trackingStatusInitiation() {
        currentLyrics = "LyricsX"
        if iTunes.running() && iTunes.playing() {
            currentSongID = iTunes.currentPersistentID()
            currentSongTitle = iTunes.currentTitle()
            currentArtist = iTunes.currentArtist()
            
            if currentSongID == "" {
                // If iTunes is playing Apple Music, nothing can get from API,
                // so, we should pause and then play to force iTunes send
                // distributed notification.
                iTunes.pause()
                iTunes.play()
            }
            else {
                DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.default).async { () -> Void in
                    self.handleSongChange()
                }
                
                NSLog("Create new iTunesTrackingThead")
                isTrackingRunning = true
                DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.default).async { () -> Void in
                    self.iTunesTrackingThread()
                }
            }
        }
        else {
            currentSongID = ""
            currentSongTitle = ""
            currentArtist = ""
        }
    }
    
// MARK: - Shortcut Events
    
    fileprivate func setupShortcuts() {
        // Default shortcuts
        let offsetIncr: MASShortcut = MASShortcut(keyCode: UInt(kVK_ANSI_Equal), modifierFlags: NSEventModifierFlags.command.rawValue | NSEventModifierFlags.option.rawValue)
        let offsetDecr: MASShortcut = MASShortcut(keyCode: UInt(kVK_ANSI_Minus), modifierFlags: NSEventModifierFlags.command.rawValue | NSEventModifierFlags.option.rawValue)
        let defaultShortcuts = [ShortcutOffsetIncr : offsetIncr,
                                ShortcutOffsetDecr : offsetDecr]
        MASShortcutBinder.shared().registerDefaultShortcuts(defaultShortcuts)
        
        //Bind actions to User Default keys
        MASShortcutBinder.shared().bindShortcut(withDefaultsKey: ShortcutOffsetIncr) {
            self.increaseTimeDly()
        }
        MASShortcutBinder.shared().bindShortcut(withDefaultsKey: ShortcutOffsetDecr) {
            self.decreaseTimeDly()
        }
        MASShortcutBinder.shared().bindShortcut(withDefaultsKey: ShortcutLyricsModeSwitch) { () -> Void in
            let userDefaults = UserDefaults.standard
            userDefaults.set(!userDefaults.bool(forKey: LyricsIsVerticalLyrics), forKey: LyricsIsVerticalLyrics)
            DispatchQueue.main.async(execute: { () -> Void in
                DesktopLyricsController.sharedController.reflash()
            })
        }
        MASShortcutBinder.shared().bindShortcut(withDefaultsKey: ShortcutDesktopMenubarSwitch) { () -> Void in
            self.switchDesktopMenuBarMode()
        }
        MASShortcutBinder.shared().bindShortcut(withDefaultsKey: ShortcutOpenLrcSeeker) { () -> Void in
            self.searchLyricsAndArtworks(nil)
        }
        MASShortcutBinder.shared().bindShortcut(withDefaultsKey: ShortcutCopyLrcToPb) { () -> Void in
            self.copyLyricsToPb(nil)
        }
        MASShortcutBinder.shared().bindShortcut(withDefaultsKey: ShortcutEditLrc) { () -> Void in
            self.editLyrics(nil)
        }
        MASShortcutBinder.shared().bindShortcut(withDefaultsKey: ShortcutMakeLrc) { () -> Void in
            self.makeLrc(nil)
        }
        MASShortcutBinder.shared().bindShortcut(withDefaultsKey: ShortcutWriteLrcToiTunes) { () -> Void in
            self.writeLyricsToiTunes(nil)
        }
    }
    
    fileprivate func increaseTimeDly() {
        self.willChangeValue(forKey: "timeDly")
        timeDly += 100
        if timeDly > 10000 {
            timeDly = 10000
        }
        self.didChangeValue(forKey: "timeDly")
        let message: String = String(format: NSLocalizedString("OFFSET", comment: ""), timeDly)
        MessageWindowController.sharedMsgWindow.displayMessage(message)
    }
    
    fileprivate func decreaseTimeDly() {
        self.willChangeValue(forKey: "timeDly")
        timeDly -= 100
        if timeDly < -10000 {
            timeDly = -10000
        }
        self.didChangeValue(forKey: "timeDly")
        let message: String = String(format: NSLocalizedString("OFFSET", comment: ""), timeDly)
        MessageWindowController.sharedMsgWindow.displayMessage(message)
    }
    
    fileprivate func switchDesktopMenuBarMode() {
        let isDesktopLyricsOn = userDefaults.bool(forKey: LyricsDesktopLyricsEnabled)
        let isMenuBarLyricsOn = userDefaults.bool(forKey: LyricsMenuBarLyricsEnabled)
        if isDesktopLyricsOn && isMenuBarLyricsOn {
            userDefaults.set(false, forKey: LyricsMenuBarLyricsEnabled)
            MessageWindowController.sharedMsgWindow.displayMessage(NSLocalizedString("DESKTOP_ON", comment: ""))
            menuBarLyrics = nil
        }
        else if isDesktopLyricsOn && !isMenuBarLyricsOn {
            userDefaults.set(false, forKey: LyricsDesktopLyricsEnabled)
            userDefaults.set(true, forKey: LyricsMenuBarLyricsEnabled)
            MessageWindowController.sharedMsgWindow.displayMessage(NSLocalizedString("MENU_BAR_ON", comment: ""))
            menuBarLyrics = MenuBarLyrics()
            DispatchQueue.main.async(execute: {
                self.lyricsWindow.displayLyrics(nil, secondLyrics: nil)
                self.menuBarLyrics.displayLyrics(self.currentLyrics)
            })
        }
        else {
            userDefaults.set(true, forKey: LyricsDesktopLyricsEnabled)
            MessageWindowController.sharedMsgWindow.displayMessage(NSLocalizedString("BOTH_ON", comment: ""))
            // Force update both
            currentLyrics = nil
        }
    }
    
// MARK: - Interface Methods
    
    @IBAction func enableDesktopLyrics(_ sender:AnyObject?) {
        if (sender as! NSMenuItem).state == NSOnState {
            DispatchQueue.main.async(execute: { () -> Void in
                self.lyricsWindow.displayLyrics(nil, secondLyrics: nil)
            })
        } else {
            //Force lyrics to show(handlePositionChange method will update it if lyrics changed.)
            currentLyrics = nil
        }
    }
    
    @IBAction func enableMenuBarLyrics(_ sender:AnyObject?) {
        if (sender as! NSMenuItem).state == NSOnState {
            menuBarLyrics = nil
        } else {
            menuBarLyrics = MenuBarLyrics()
            DispatchQueue.main.async(execute: { 
                self.menuBarLyrics.displayLyrics(self.currentLyrics)
            })
        }
    }
    
    @IBAction func changeLyricsMode(_ sender:AnyObject?) {
        DispatchQueue.main.async { () -> Void in
            self.lyricsWindow.reflash()
        }
    }
    
    @IBAction func showAboutWindow(_ sender: AnyObject?) {
        AboutWindowController.sharedController.showWindow(nil)
    }
    
    @IBAction func showDonate(_ sender: AnyObject?) {
        let windowController = AboutWindowController.sharedController
        windowController.showWindow(nil)
        windowController.showDonate(nil)
    }
    
    @IBAction func showPreferences(_ sender:AnyObject?) {
        let prefs = AppPrefsWindowController.sharedPrefsWindowController
        if !(prefs.window?.isVisible)! {
            prefs.showWindow(nil)
        }
        prefs.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @IBAction func checkForUpdate(_ sender: AnyObject) {
        NSWorkspace.shared().open(URL(string: "https://github.com/MichaelRow/Lyrics/releases")!)
    }
    
    @IBAction func exportArtwork(_ sender: AnyObject) {
        let artworkData: Data? = iTunes.artwork()
        if artworkData == nil {
            MessageWindowController.sharedMsgWindow.displayMessage(NSLocalizedString("NO_ARTWORK", comment: ""))
            return
        }
        let panel = NSSavePanel()
        panel.allowedFileTypes = ["png",  "jpg", "jpf", "bmp", "gif", "tiff"]
        panel.nameFieldStringValue = currentSongTitle + " - " + currentArtist
        panel.isExtensionHidden = true
        if panel.runModal() == NSFileHandlingPanelOKButton {
            try? artworkData!.write(to: panel.url!, options: [])
        }
    }
    
    @IBAction func searchLyricsAndArtworks(_ sender: AnyObject?) {
        let appPath = Bundle.main.bundlePath + "/Contents/Library/LrcSeeker.app"
        NSWorkspace.shared().launchApplication(appPath)
    }
    
    @IBAction func copyLyricsToPb(_ sender: AnyObject?) {
        if lyricsArray.count == 0 {
            MessageWindowController.sharedMsgWindow.displayMessage(NSLocalizedString("OPERATION_FAILED", comment: ""))
            return
        }
        var theLyrics: String = String()
        var hasSpace: Bool = false
        for lrc in lyricsArray {
            if lrc.lyricsSentence.replacingOccurrences(of: " ", with: "") == "" {
                if hasSpace {
                    continue
                }
                else {
                    hasSpace = true
                }
            }
            else if hasSpace {
                hasSpace = false
            }
            if lrc.enabled {
                theLyrics.append(lrc.lyricsSentence + "\n")
            }
        }
        let pb = NSPasteboard.general()
        pb.clearContents()
        pb.writeObjects([theLyrics as NSPasteboardWriting])
        MessageWindowController.sharedMsgWindow.displayMessage(NSLocalizedString("COPYED_TO_PB", comment: ""))
    }
    
    @IBAction func copyLyricsWithTagsToPb(_ sender: AnyObject) {
        let lrcContents = readLocalLyrics(currentSongTitle, theArtist: currentArtist)
        if lrcContents != nil && lrcContents != "" {
            let pb = NSPasteboard.general()
            pb.clearContents()
            pb.writeObjects([lrcContents! as NSPasteboardWriting])
            MessageWindowController.sharedMsgWindow.displayMessage(NSLocalizedString("COPYED_TO_PB", comment: ""))
        } else {
            MessageWindowController.sharedMsgWindow.displayMessage(NSLocalizedString("OPERATION_FAILED", comment: ""))
        }
    }
    
    @IBAction func makeLrc(_ sender: AnyObject?) {
        let appPath = Bundle.main.bundlePath + "/Contents/Library/LrcMaker.app"
        NSWorkspace.shared().launchApplication(appPath)
    }
    
    @IBAction func mergeLrc(_ sender: AnyObject) {
        let appPath = Bundle.main.bundlePath + "/Contents/Library/LrcMerger.app"
        NSWorkspace.shared().launchApplication(appPath)
    }
    
    @IBAction func editLyrics(_ sender: AnyObject?) {
        var lrcContents = readLocalLyrics(currentSongTitle, theArtist: currentArtist)
        if lrcContents == nil {
            lrcContents = ""
        }
        let windowController = LyricsEditWindowController.sharedController
        windowController.setLyricsContents(lrcContents!, songID: currentSongID, songTitle: currentSongTitle, andArtist: currentArtist)
        if !windowController.window!.isVisible {
            windowController.showWindow(nil)
        }
        windowController.window!.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @IBAction func importLrcFile(_ sender: AnyObject) {
        let songTitle: String = currentSongTitle
        let artist: String = currentArtist
        let songID: String = currentSongID
        let panel: NSOpenPanel = NSOpenPanel()
        panel.allowedFileTypes = ["lrc", "txt"]
        panel.isExtensionHidden = false
        if panel.runModal() == NSFileHandlingPanelOKButton {
            let lrcContents: String!
            do {
                lrcContents = try String(contentsOf: panel.url!, encoding: String.Encoding.utf8)

            } catch let theError as NSError {
                lrcContents = nil
                NSLog("%@", theError.localizedDescription)
                
                // Error must be the text encoding thing.
                if !userDefaults.bool(forKey: LyricsDisableAllAlert) {
                    let alert: NSAlert = NSAlert()
                    alert.messageText = NSLocalizedString("UNSUPPORTED_ENCODING", comment: "")
                    alert.informativeText = NSLocalizedString("ONLY_UTF8", comment: "")
                    alert.addButton(withTitle: NSLocalizedString("OK", comment: ""))
                    alert.runModal()
                }
                return
            }
            if lrcContents != nil && lrcParser.testLrc(lrcContents) {
                lrcSourceHandleQueue.cancelAllOperations()
                lrcSourceHandleQueue.addOperation({ () -> Void in
                    //make the current lrc the better one so that it can't be replaced.
                    if songID == self.currentSongID {
                        self.parseCurrentLrc(lrcContents)
                        self.hasDiglossiaLrc = true
                    }
                    self.saveLrcToLocal(lrcContents, songTitle: songTitle, artist: artist)
                })
            }
        }
    }
    
    @IBAction func exportLrcFile(_ sender: AnyObject) {
        let savingPath: String
        if userDefaults.integer(forKey: LyricsSavingPathPopUpIndex) == 0 {
            savingPath = NSSearchPathForDirectoriesInDomains(.musicDirectory, [.userDomainMask], true).first! + "/LyricsX"
        } else {
            savingPath = userDefaults.string(forKey: LyricsUserSavingPath)!
        }
        let songTitle:String = currentSongTitle.replacingOccurrences(of: "/", with: "&")
        let artist:String = currentArtist.replacingOccurrences(of: "/", with: "&")
        let lrcFilePath = (savingPath as NSString).appendingPathComponent("\(songTitle) - \(artist).lrc")
        
        let panel: NSSavePanel = NSSavePanel()
        panel.allowedFileTypes = ["lrc","txt"]
        panel.nameFieldStringValue = (lrcFilePath as NSString).lastPathComponent
        panel.isExtensionHidden = false
        
        if panel.runModal() == NSFileHandlingPanelOKButton {
            let fm = FileManager.default
            if fm.fileExists(atPath: panel.url!.path) {
                do {
                    try fm.removeItem(at: panel.url!)
                } catch let theError as NSError {
                    NSLog("%@", theError.localizedDescription)
                }
            }
            do {
                try fm.copyItem(atPath: lrcFilePath, toPath: panel.url!.path)
            } catch let theError as NSError {
                NSLog("%@", theError.localizedDescription)
            }
        }
    }
    
    @IBAction func writeLyricsToiTunes(_ sender: AnyObject?) {
        if lyricsArray.count == 0 {
            MessageWindowController.sharedMsgWindow.displayMessage(NSLocalizedString("OPERATION_FAILED", comment: ""))
            return
        } else {
            var theLyrics: String = String()
            for lrc in lyricsArray {
                theLyrics.append(lrc.lyricsSentence + "\n")
            }
            iTunes.setLyrics(theLyrics)
            MessageWindowController.sharedMsgWindow.displayMessage(NSLocalizedString("WROTE_TO_ITUNES", comment: ""))
        }
    }
    
    @IBAction func writeAllLyricsToiTunes(_ sender: AnyObject?) {
        let skip: Bool
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("OVERRIDE_OR_SKIP", comment: "")
        alert.informativeText = NSLocalizedString("OVERRIDE_OR_SKIP_INTRO", comment: "")
        alert.addButton(withTitle: NSLocalizedString("SKIP", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("OVERRIDE", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("CANCEL", comment: ""))
        switch alert.runModal() {
        case NSAlertFirstButtonReturn:
            skip = true
        case NSAlertSecondButtonReturn:
            skip = false
        default:
            return
        }
        
        DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.low).async { () -> Void in
            if self.iTunes.setAllLyrics(skip) {
                DispatchQueue.main.async(execute: { () -> Void in
                    MessageWindowController.sharedMsgWindow.displayMessage(NSLocalizedString("WROTE_TO_ITUNES", comment: ""))
                })
            }
            else {
                DispatchQueue.main.async(execute: { () -> Void in
                    MessageWindowController.sharedMsgWindow.displayMessage(NSLocalizedString("OPERATION_FAILED", comment: ""))
                })
            }
        }
    }
    
    @IBAction func wrongLyrics(_ sender: AnyObject) {
        let songID = currentSongID
        let songTitle = currentSongTitle
        let artist = currentArtist
        if !userDefaults.bool(forKey: LyricsDisableAllAlert) {
            let alert: NSAlert = NSAlert()
            alert.messageText = NSLocalizedString("CONFIRM_MARK_WRONG", comment: "")
            alert.informativeText = NSLocalizedString("CANT_UNDONE", comment: "")
            alert.addButton(withTitle: NSLocalizedString("CANCEL", comment: ""))
            alert.addButton(withTitle: NSLocalizedString("MARK", comment: ""))
            let response: NSModalResponse = alert.runModal()
            if response == NSAlertFirstButtonReturn {
                return
            }
        }
        let wrongLyricsTag: String = NSLocalizedString("WRONG_LYRICS", comment: "")
        if songID == currentSongID {
            lyricsArray.removeAll()
            currentLyrics = nil
            DispatchQueue.main.async { () -> Void in
                self.lyricsWindow.displayLyrics(nil, secondLyrics: nil)
            }
        }
        DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.default).async { 
            self.saveLrcToLocal(wrongLyricsTag, songTitle: songTitle!, artist: artist!)
        }
    }

    @IBAction func setAutoLayout(_ sender: AnyObject?) {
        //Action triggers before NSUserDefaults, so, delay 0.1s 
        if !userDefaults.bool(forKey: LyricsUseAutoLayout) {
            lyricsWindow.storeWindowSize()
        }
        lyricsWindow.perform(#selector(DesktopLyricsController.checkAutoLayout), with: nil, afterDelay: 0.1)
    }
    
    @IBAction func lockLyricsFloatingWindow(_ sender: AnyObject?) {
        lockFloatingWindow = !lockFloatingWindow
        lyricsWindow.window?.ignoresMouseEvents = lockFloatingWindow
    }
    
    func setPresetByMenu(_ sender: AnyObject?) {
        if sender is NSMenuItem {
            let index: Int = presetMenuItem.submenu!.index(of: sender as! NSMenuItem)
            if index == -1 {
                return
            }
            let prefs = AppPrefsWindowController.sharedPrefsWindowController
            prefs.presetListView.selectRowIndexes(IndexSet(integer: index), byExtendingSelection: false)
            prefs.applyPreset(nil)
        }
    }
    
// MARK: - iTunes Events
    
    fileprivate func iTunesTrackingThread() {
        // side node: iTunes update playerPosition once per second.
        var iTunesPosition: Int = 0
        var currentPosition: Int = 0
        //No need to track iTunes PlayerPosition when it's paused, just end the thread.
        while iTunes.playing() {
            if lyricsArray.count != 0 {
                iTunesPosition = iTunes.playerPosition()
                if (currentPosition < iTunesPosition) || ((currentPosition / 1000) != (iTunesPosition / 1000) && currentPosition % 1000 < 850) {
                    currentPosition = iTunesPosition
                }
                DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.default).async(execute: { () -> Void in
                    self.handlePositionChange(iTunesPosition)
                })
            }
            Thread.sleep(forTimeInterval: 0.15)
            currentPosition += 150
        }
        if userDefaults.bool(forKey: LyricsDisabledWhenPaused) {
            self.currentLyrics = nil
            DispatchQueue.main.async(execute: { () -> Void in
                self.lyricsWindow.displayLyrics(nil, secondLyrics: nil)
                if self.menuBarLyrics != nil {
                    self.menuBarLyrics.displayLyrics(nil)
                }
            })
        }
        NSLog("iTunesTrackingThread Ended")
        isTrackingRunning=false
    }
    
    
    func iTunesPlayerInfoChanged (_ n:Notification) {
        let userInfo = (n as NSNotification).userInfo
        if userInfo == nil {
            return
        }
        else {
            if userInfo!["Player State"] as! String == "Paused" {
                NSLog("iTunes Paused")
                if userDefaults.bool(forKey: LyricsQuitWithITunes) {
                    // iTunes would paused before it quitted, so we should check whether iTunes is running
                    // seconds later when playing or paused.
                    if timer != nil {
                        timer.invalidate()
                    }
                    timer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(terminate), userInfo: nil, repeats: false)
                }
                return
            }
            else if userInfo!["Player State"] as! String == "Playing" {
                //iTunes is playing now, we should create the tracking thread if not exists.
                if !isTrackingRunning {
                    NSLog("Create new iTunesTrackingThead")
                    isTrackingRunning = true
                    DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.default).async { () -> Void in
                        self.iTunesTrackingThread()
                    }
                }
                NSLog("iTunes Playing")
            }
            else if userInfo!["Player State"] as! String == "Stopped" {
                // iTunes send this player state when quit in some case.
                currentSongID = ""
                currentSongTitle = ""
                currentArtist = ""
                if timer != nil {
                    timer.invalidate()
                }
                timer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(terminate), userInfo: nil, repeats: false)
                return
            }
            
            // Get infos from userinfo if can't get them from API.
            var songID: String = iTunes.currentPersistentID()
            var songTitle: String = iTunes.currentTitle()
            var artist: String = iTunes.currentArtist()
            if songID == "" {
                let aSongID = userInfo!["PersistentID"]
                if aSongID != nil {
                    songID = (aSongID as! NSNumber).stringValue
                }
            }
            if songTitle == "" {
                let aSongTitle = userInfo!["Name"]
                if aSongTitle != nil {
                    songTitle = aSongTitle as! String
                }
            }
            if artist == "" {
                let aArtist = userInfo!["Artist"]
                if aArtist != nil {
                    artist = aArtist as! String
                }
            }
            
            // Check whether song is changed.
            if currentSongID == songID {
                return
            } else {
                //if time-Delay for the previous song is changed, we should save the change to lrc file.
                //Save time-Delay laziely for better I/O performance.
                if timeDly != timeDlyInFile {
                    self.handleLrcDelayChange()
                }
                
                lyricsArray.removeAll()
                idTagsArray.removeAll()
                self.setValue(0, forKey: "timeDly")
                timeDlyInFile = 0
                currentLyrics = nil
                lyricsWindow.displayLyrics(nil, secondLyrics: nil)
                currentSongID = songID
                currentSongTitle = songTitle
                currentArtist = artist
                if currentSongID != "" {
                    NSLog("Song Changed to: %@",currentSongTitle)
                    DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.default).async(execute: { () -> Void in
                        self.handleSongChange()
                    })
                } else {
                    NSLog("iTunes Stopped")
                }
            }
        }
    }

// MARK: - Lrc Methods
    
    fileprivate func parseCurrentLrc(_ lrcContents: String) {
        lyricsArray.removeAll()
        idTagsArray.removeAll()
        let lrcToParse: String
        
        // whether convert Chinese type
        if userDefaults.bool(forKey: LyricsAutoConvertChinese) {
            switch userDefaults.integer(forKey: LyricsChineseTypeIndex) {
            case 0:
                lrcToParse = convertToSC(lrcContents)
            case 1:
                lrcToParse = convertToTC(lrcContents)
            case 2:
                lrcToParse = convertToTC_TW(lrcContents)
            case 3:
                lrcToParse = convertToTC_HK(lrcContents)
            default:
                lrcToParse = lrcContents
                break
            }
        } else {
            lrcToParse = lrcContents
        }
        
        if userDefaults.bool(forKey: LyricsEnableFilter) {
            lrcParser.parseWithFilter(lrcToParse, iTunesTitle: currentSongTitle, iTunesAlbum: iTunes.currentAlbum())
        }
        else {
            lrcParser.regularParse(lrcToParse)
        }
        lyricsArray = lrcParser.lyrics
        idTagsArray = lrcParser.idTags
        self.setValue(lrcParser.timeDly, forKey: "timeDly")
        timeDlyInFile = timeDly
        lrcParser.cleanCache()
    }

    fileprivate func saveLrcToLocal (_ lyricsContents: String, songTitle: String, artist: String) {
        let savingPath: String
        if userDefaults.integer(forKey: LyricsSavingPathPopUpIndex) == 0 {
            savingPath = NSSearchPathForDirectoriesInDomains(.musicDirectory, [.userDomainMask], true).first! + "/LyricsX"
        } else {
            savingPath = userDefaults.string(forKey: LyricsUserSavingPath)!
        }
        let fm: FileManager = FileManager.default
        
        var isDir = ObjCBool(false)
        if fm.fileExists(atPath: savingPath, isDirectory: &isDir) {
            if !isDir.boolValue {
                return
            }
        } else {
            do {
                try fm.createDirectory(atPath: savingPath, withIntermediateDirectories: true, attributes: nil)
            } catch let theError as NSError{
                NSLog("%@", theError.localizedDescription)
                return
            }
        }
        
        let titleForSaving = songTitle.replacingOccurrences(of: "/", with: "&")
        let artistForSaving = artist.replacingOccurrences(of: "/", with: "&")
        let lrcFilePath = (savingPath as NSString).appendingPathComponent("\(titleForSaving) - \(artistForSaving).lrc")
        
        if fm.fileExists(atPath: lrcFilePath) {
            do {
                try fm.removeItem(atPath: lrcFilePath)
            } catch let theError as NSError {
                NSLog("%@", theError.localizedDescription)
                return
            }
        }
        do {
            try lyricsContents.write(toFile: lrcFilePath, atomically: false, encoding: String.Encoding.utf8)
        } catch let theError as NSError {
            NSLog("%@", theError.localizedDescription)
        }
    }
    
    func readLocalLyrics(_ theTitle: String, theArtist: String) -> String? {
        let savingPath: String
        if userDefaults.integer(forKey: LyricsSavingPathPopUpIndex) == 0 {
            savingPath = NSSearchPathForDirectoriesInDomains(.musicDirectory, [.userDomainMask], true).first! + "/LyricsX"
        } else {
            savingPath = userDefaults.string(forKey: LyricsUserSavingPath)!
        }
        let songTitle: String = theTitle.replacingOccurrences(of: "/", with: "&")
        let artist: String = theArtist.replacingOccurrences(of: "/", with: "&")
        let lrcFilePath = (savingPath as NSString).appendingPathComponent("\(songTitle) - \(artist).lrc")
        if  FileManager.default.fileExists(atPath: lrcFilePath) {
            let lrcContents: String?
            do {
                lrcContents = try String(contentsOfFile: lrcFilePath, encoding: String.Encoding.utf8)
            } catch {
                lrcContents = nil
                NSLog("Failed to load lrc")
            }
            return lrcContents
        } else {
            return nil
        }
    }

// MARK: - Handle Events
    
    func handlePositionChange (_ playerPosition: Int) {
        let tempLyricsArray = lyricsArray
        var index: Int = 0
        //1.Find the first lyrics which time position is larger than current position, and its index is "index"
        //2.The index of first-line-lyrics which needs to display is "index - 1"
        while index < (tempLyricsArray?.count)! {
            if playerPosition < (tempLyricsArray?[index].msecPosition)! - timeDly {
                if index == 0 {
                    if currentLyrics != nil {
                        currentLyrics = nil
                        if userDefaults.bool(forKey: LyricsDesktopLyricsEnabled) {
                            DispatchQueue.main.async(execute: { () -> Void in
                                self.lyricsWindow.displayLyrics(nil, secondLyrics: nil)
                            })
                        }
                        if menuBarLyrics != nil {
                            DispatchQueue.main.async(execute: { () -> Void in
                                self.menuBarLyrics.displayLyrics(nil)
                            })
                        }
                    }
                    return
                }
                else {
                    if !(tempLyricsArray?[index-1].enabled)! {
                        if currentLyrics != nil {
                            currentLyrics = nil
                            if userDefaults.bool(forKey: LyricsDesktopLyricsEnabled) {
                                DispatchQueue.main.async(execute: { () -> Void in
                                    self.lyricsWindow.displayLyrics(nil, secondLyrics: nil)
                                })
                            }
                            if menuBarLyrics != nil {
                                DispatchQueue.main.async(execute: { () -> Void in
                                    self.menuBarLyrics.displayLyrics(nil)
                                })
                            }
                        }
                    }
                    else if currentLyrics != tempLyricsArray?[index-1].lyricsSentence {
                        var secondLyrics: String!
                        currentLyrics = tempLyricsArray?[index-1].lyricsSentence
                        if userDefaults.bool(forKey: LyricsDesktopLyricsEnabled) {
                            if userDefaults.bool(forKey: LyricsTwoLineMode) && userDefaults.integer(forKey: LyricsTwoLineModeIndex)==0 && index < (tempLyricsArray?.count)! {
                                if tempLyricsArray?[index].lyricsSentence != "" {
                                    secondLyrics = tempLyricsArray?[index].lyricsSentence
                                }
                            }
                            DispatchQueue.main.async(execute: { () -> Void in
                                self.lyricsWindow.displayLyrics(self.currentLyrics, secondLyrics: secondLyrics)
                            })
                        }
                        if menuBarLyrics != nil {
                            DispatchQueue.main.async(execute: { 
                                self.menuBarLyrics.displayLyrics(self.currentLyrics)
                            })
                        }
                    }
                    return
                }
            }
            index += 1
        }
        if index == (tempLyricsArray?.count)! && (tempLyricsArray?.count)!>0 {
            if !(tempLyricsArray?[(tempLyricsArray?.count)! - 1].enabled)! {
                if currentLyrics != nil {
                    currentLyrics = nil
                    if userDefaults.bool(forKey: LyricsDesktopLyricsEnabled) {
                        DispatchQueue.main.async(execute: { () -> Void in
                            self.lyricsWindow.displayLyrics(nil, secondLyrics: nil)
                        })
                    }
                    if menuBarLyrics != nil {
                        DispatchQueue.main.async(execute: { () -> Void in
                            self.menuBarLyrics.displayLyrics(nil)
                        })
                    }
                }
            }
            else if currentLyrics != tempLyricsArray?[(tempLyricsArray?.count)! - 1].lyricsSentence {
                currentLyrics = tempLyricsArray?[(tempLyricsArray?.count)! - 1].lyricsSentence
                if userDefaults.bool(forKey: LyricsDesktopLyricsEnabled) {
                    DispatchQueue.main.async(execute: { () -> Void in
                        self.lyricsWindow.displayLyrics(self.currentLyrics, secondLyrics: nil)
                    })
                }
                if menuBarLyrics != nil {
                    DispatchQueue.main.async(execute: {
                        self.menuBarLyrics.displayLyrics(self.currentLyrics)
                    })
                }
            }
        }
    }
    
    func handleSongChange() {
        //load lyrics for the song which is about to play
        lrcSourceHandleQueue.cancelAllOperations()
        let lrcContents: String? = readLocalLyrics(currentSongTitle, theArtist: currentArtist)
        if lrcContents != nil {
            parseCurrentLrc(lrcContents!)
            if lyricsArray.count != 0 {
                return
            }
        }
        
        //Search in the Net if local lrc is nil or invalid
        let loadingSongID: String = currentSongID
        let loadingArtist: String = currentArtist
        let loadingTitle: String = currentSongTitle
        hasDiglossiaLrc = false
        
        let artistForSearching: String = self.delSpecificSymbol(loadingArtist)
        let titleForSearching: String = self.delSpecificSymbol(loadingTitle)
        
        //千千静听不支持繁体中文搜索，先转成简体中文。搜歌词组件参数是iTunes中显示的歌曲名
        //歌手名以及iTunes的唯一编号（防止歌曲变更造成的歌词对错歌），以及用于搜索用的歌曲
        //名与歌手名。另外，天天动听/QQ只会获取歌词文本，其他歌词源都是获取歌词URL
        qianqian.getLyricsWithTitle(loadingTitle, artist: loadingArtist, songID: loadingSongID, titleForSearching: convertToSC(titleForSearching), andArtistForSearching: convertToSC(artistForSearching))
        xiami.getLyricsWithTitle(loadingTitle, artist: loadingArtist, songID: loadingSongID, titleForSearching: titleForSearching, andArtistForSearching: artistForSearching)
        ttpod.getLyricsWithTitle(loadingTitle, artist: loadingArtist, songID: loadingSongID, titleForSearching: titleForSearching, andArtistForSearching: artistForSearching)
        geciMe.getLyricsWithTitle(loadingTitle, artist: loadingArtist, songID: loadingSongID, titleForSearching: titleForSearching, andArtistForSearching: artistForSearching)
        qqMusic.getLyricsWithTitle(loadingTitle, artist: loadingArtist, songID: loadingSongID, titleForSearching: titleForSearching, andArtistForSearching: artistForSearching)
    }
    
    func handleUserEditLyrics(_ n: Notification) {
        let userInfo: [AnyHashable: Any] = (n as NSNotification).userInfo!
        let lyrics: String = LyricsEditWindowController.sharedController.textView.string!
        
        if lrcParser.testLrc(lyrics) {
            //User lrc has the highest priority level
            lrcSourceHandleQueue.cancelAllOperations()
            lrcSourceHandleQueue.addOperation { () -> Void in
                if (userInfo["SongID"] as! String) == self.currentSongID {
                    //make the current lrc the better one so that it can't be replaced.
                    self.hasDiglossiaLrc = true
                    self.parseCurrentLrc(lyrics)
                }
                self.saveLrcToLocal(lyrics, songTitle: userInfo["SongTitle"] as! String, artist: userInfo["SongArtist"] as! String)
            }
        }
    }
    
    func handleExtenalLyricsEvent (_ n:Notification) {
        let userInfo = (n as NSNotification).userInfo
        
        //no playing track?
        if currentSongID == "" {
            let notification: NSUserNotification = NSUserNotification()
            notification.title = NSLocalizedString("NO_PLAYING_TRACK", comment: "")
            notification.informativeText = String(format: NSLocalizedString("IGNORE_LYRICS", comment: ""), userInfo!["Sender"] as! String)
            NSUserNotificationCenter.default.deliver(notification)
            return
        }
        MessageWindowController.sharedMsgWindow.displayMessage(String(format: NSLocalizedString("RECIEVE_LYRICS", comment: ""), userInfo!["Sender"] as! String))
        //User lrc has the highest priority level
        lrcSourceHandleQueue.cancelAllOperations()
        lrcSourceHandleQueue.addOperation { () -> Void in
            let lyricsContents: String = userInfo!["LyricsContents"] as! String
            if self.lrcParser.testLrc(lyricsContents) {
                self.parseCurrentLrc(lyricsContents)
                //make the current lrc the better one so that it can't be replaced.
                self.hasDiglossiaLrc = true
                self.saveLrcToLocal(lyricsContents, songTitle: self.currentSongTitle, artist: self.currentArtist)
            }
        }
    }
    
    func handleLrcDelayChange () {
        //save the delay change to file.
        if lyricsArray.count == 0 {
            return
        }
        var theLyrics: String = String()
        for idtag in idTagsArray {
            theLyrics.append(idtag + "\n")
        }
        theLyrics.append("[offset:\(timeDly)]\n")
        for lrc in lyricsArray {
            theLyrics.append(lrc.timeTag + lrc.lyricsSentence + "\n")
        }
        if lyricsArray.count > 0 {
            theLyrics.remove(at: theLyrics.characters.index(theLyrics.endIndex, offsetBy: -1))
        }
        NSLog("Writing the time delay to file")
        DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.default).async { 
            self.saveLrcToLocal(theLyrics, songTitle: self.currentSongTitle, artist: self.currentArtist)
        }
    }
    
    func handlePresetDidChanged() {
        presetMenuItem.submenu?.removeAllItems()
        let prefs = AppPrefsWindowController.sharedPrefsWindowController
        if prefs.presets.count == 0 {
            presetMenuItem.submenu?.addItem(withTitle: NSLocalizedString("EMPTY", comment: ""), action: nil, keyEquivalent: "")
            return
        }
        for preset in prefs.presets {
            let item = NSMenuItem()
            item.title = preset
            item.target = self
            item.action = #selector(setPresetByMenu(_:))
            presetMenuItem.submenu?.addItem(item)
        }
    }
    
// MARK: - Lyrics Source Loading Completion

    func lrcLoadingCompleted(_ n: Notification) {
        // we should run the handle thread one by one in the queue of maxConcurrentOperationCount =1
        let userInfo = (n as NSNotification).userInfo
        let source: Int = (userInfo!["source"]! as AnyObject).intValue
        let songTitle: String = userInfo!["title"] as! String
        let artist: String = userInfo!["artist"] as! String
        let songID: String = userInfo!["songID"] as! String
        let serverLrcs: [SongInfos]
        switch source {
        case 1:
            serverLrcs = (self.qianqian.currentSongs as NSArray) as! [SongInfos]
        case 2:
            serverLrcs = (self.xiami.currentSongs as NSArray) as! [SongInfos]
        case 3:
            let info: SongInfos = self.ttpod.songInfos.copy() as! SongInfos
            if info.lyric == "" {
                return
            } else {
                serverLrcs = [info]
            }
        case 4:
            serverLrcs = (self.geciMe.currentSongs as NSArray) as! [SongInfos]
        case 5:
            serverLrcs = self.qqMusic.currentSongs
        default:
            return;
        }
        if serverLrcs.count > 0 {
            lrcSourceHandleQueue.addOperation({ () -> Void in
                self.handleLrcURLDownloaded(serverLrcs, songTitle: songTitle, artist: artist, songID: songID)
            })
        }
    }
    
    
    fileprivate func handleLrcURLDownloaded(_ serverLrcs: [SongInfos], songTitle:String, artist:String, songID:String) {
        // alread has lyrics, check if user needs a better one.
        if lyricsArray.count > 0 {
            if userDefaults.bool(forKey: LyricsSearchForDiglossiaLrc) {
                if hasDiglossiaLrc {
                    return
                }
            } else {
                return
            }
        }
        
        var lyricsContents: String! = nil
        for lrc in serverLrcs {
            if isDiglossiaLrc(lrc.songTitle + lrc.artist) {
                if lrc.lyric != nil {
                    lyricsContents = lrc.lyric
                }
                else if lrc.lyricURL != nil {
                    do {
                        if let downloadURL = URL(string: lrc.lyricURL) {
                            lyricsContents = try String(contentsOf: downloadURL, encoding: String.Encoding.utf8)
                        }
                    } catch let theError as NSError{
                        NSLog("%@", theError.localizedDescription)
                        lyricsContents = nil
                        continue
                    }
                }
                break
            }
        }
        if lyricsContents == nil && lyricsArray.count > 0 {
            return
        }
        
        var hasLrc: Bool
        if lyricsContents == nil || !lrcParser.testLrc(lyricsContents) {
            NSLog("better lrc not found or it's not lrc file,trying others")
            hasLrc = false
            lyricsContents = nil
            hasDiglossiaLrc = false
            for lrc in serverLrcs {
                if lrc.lyric != nil {
                    lyricsContents = lrc.lyric
                }
                else if lrc.lyricURL != nil {
                    do {
                        if let downloadURL = URL(string: lrc.lyricURL) {
                            lyricsContents = try String(contentsOf: downloadURL, encoding: String.Encoding.utf8)
                        }
                    } catch let theError as NSError{
                        NSLog("%@", theError.localizedDescription)
                        lyricsContents = nil
                        continue
                    }
                }
                if lyricsContents != nil && lrcParser.testLrc(lyricsContents) {
                    hasLrc = true
                    break
                }
            }
        } else {
            hasLrc = true
            hasDiglossiaLrc = true
        }
        if hasLrc {
            if songID == currentSongID {
                parseCurrentLrc(lyricsContents)
            }
            saveLrcToLocal(lyricsContents, songTitle: songTitle, artist: artist)
        }
    }
    
// MARK: - Other Methods
    
    func terminate() {
        if !iTunes.running() {
            NSApplication.shared().terminate(nil)
        }
    }
    
    fileprivate func isDiglossiaLrc(_ serverSongTitle: String) -> Bool {
        if serverSongTitle.range(of: "中") != nil || serverSongTitle.range(of: "对照") != nil || serverSongTitle.range(of: "双") != nil {
            return true
        }
        return false
    }
    
    fileprivate func delSpecificSymbol(_ input: String) -> String {
        let specificSymbol: [String] = [
            ",", ".", "'", "\"", "`", "~", "!", "@", "#", "$", "%", "^", "&", "＆", "*", "(", ")", "（", "）", "，",
            "。", "“", "”", "‘", "’", "?", "？", "！", "/", "[", "]", "{", "}", "<", ">", "=", "-", "+", "×",
            "☆", "★", "√", "～"
        ]
        var output: String = input
        for symbol in specificSymbol {
            output = output.replacingOccurrences(of: symbol, with: " ")
        }
        return output
    }
    
}

