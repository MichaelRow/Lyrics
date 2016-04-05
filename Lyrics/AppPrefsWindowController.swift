//
//  Controller.swift
//  Lyrics
//
//  Created by Eru on 15/11/11.
//  Copyright © 2015年 Eru. All rights reserved.
//

import Cocoa
import ServiceManagement

class AppPrefsWindowController: DBPrefsWindowController, NSWindowDelegate, ContextMenuDelegate {
    
    static let sharedPrefsWindowController = AppPrefsWindowController(windowNibName:"Preferences")
    
    @IBOutlet private var generalPrefsView: ClickView!
    @IBOutlet private var lyricsPrefsView: NSView!
    @IBOutlet private var fontAndColorPrefsView: ClickView!
    @IBOutlet private var shortcutPrefsView: NSView!
    @IBOutlet private var presetPrefsView: ClickView!
    @IBOutlet private var filterPrefsView: ClickView!
    //General
    @IBOutlet private weak var savingPathPopUp: NSPopUpButton!
    //Font & Color
    @IBOutlet private weak var textPreview: TextPreview!
    @IBOutlet private weak var fontDisplayText: NSTextField!
    @IBOutlet private weak var textColor: NSColorWell!
    @IBOutlet private weak var bkColor: NSColorWell!
    @IBOutlet private weak var shadowColor: NSColorWell!
    @IBOutlet private weak var revertButton: NSButton!
    @IBOutlet private weak var applyButton: NSButton!
    private var hasFontAndColorChange: Bool = false
    private var font: NSFont!
    var shadowModeEnabled: Bool = false
    var shadowRadius: Float = 0
    var bgHeightIncreasement: Float = 0
    var lyricsYOffset: Float = 0
    //Shortcuts
    @IBOutlet private weak var lyricsModeSwitchShortcut: MASShortcutView!
    @IBOutlet private weak var desktopMenubarSwitchShortcut: MASShortcutView!
    @IBOutlet private weak var lrcSeekerShortcut: MASShortcutView!
    @IBOutlet private weak var copyLrcToPbShortcut: MASShortcutView!
    @IBOutlet private weak var editLrcShortcut: MASShortcutView!
    @IBOutlet private weak var makeLrcShortcut: MASShortcutView!
    @IBOutlet private weak var writeLrcToiTunesShortcut: MASShortcutView!
    //Preset
    var presets: [String]!
    @IBOutlet weak var presetListView: PresetListView!
    @IBOutlet private var tableMenu: NSMenu!
    @IBOutlet private var dialog: NSWindow!
    @IBOutlet private var presetNameTF: NSTextField!
    //Filter
    dynamic var directFilter = [FilterString]()
    dynamic var conditionalFilter = [FilterString]()
    @IBOutlet var directFilterList: NSTableView!
    @IBOutlet var conditionalFilterList: NSTableView!
    @IBOutlet var helpPopover: NSPopover!
    
//MARK: - Init & Override

    override func windowDidLoad() {
        super.windowDidLoad()
        presets = [String]()
        
        self.window?.delegate = self
        hasFontAndColorChange = false
        
        //Pop up button and font is hard to bind to NSUserDefaultsController, do it by self
        let defaultSavingPath: String = NSSearchPathForDirectoriesInDomains(.MusicDirectory, [.UserDomainMask], true).first! + "/LyricsX"
        let userSavingPath: String = NSUserDefaults.standardUserDefaults().stringForKey(LyricsUserSavingPath)!
        savingPathPopUp.itemAtIndex(0)?.toolTip = defaultSavingPath
        savingPathPopUp.itemAtIndex(1)?.toolTip = userSavingPath
        savingPathPopUp.itemAtIndex(1)?.title = (userSavingPath as NSString).lastPathComponent
        
        reflashFontAndColorPrefs()
        loadFilter()
    }
    
    override func setupToolbar () {
        self.addView(generalPrefsView, label: NSLocalizedString("GENERAL", comment: ""), image: NSImage(named: NSImageNamePreferencesGeneral))
        self.addView(lyricsPrefsView, label: NSLocalizedString("LYRICS", comment: ""), image: NSImage(named: "lyrics_icon"))
        self.addView(fontAndColorPrefsView, label: NSLocalizedString("FONT_COLOR", comment: ""), image: NSImage(named: "font_Color_icon"))
        self.addView(shortcutPrefsView, label: NSLocalizedString("SHORTCUT", comment: ""), image: NSImage(named: "shortcut"))
        self.addView(presetPrefsView, label: NSLocalizedString("PRESET", comment: ""), image: NSImage(named: NSImageNameAdvanced))
        self.addView(filterPrefsView, label: NSLocalizedString("FILTER", comment: ""), image: NSImage(named:"Delete"))
    }
    
    override func displayViewForIdentifier(identifier: String, animate: Bool) {
        //If uncommited value exists, there must be a NSTextField object which is 
        //First responder. And if the value is invalid, invoke NSNumber formatter
        //by resigning the first responder.
        if !canResignFirstResponder() {
            self.window?.makeFirstResponder(nil)
            self.window?.toolbar?.selectedItemIdentifier = self.window?.title
            return
        }
        //check if changes are unsaved
        let fontAndColorID: String = NSLocalizedString("FONT_COLOR", comment: "")
        let shortCutID: String = NSLocalizedString("SHORTCUT", comment: "")
        if self.window?.title == fontAndColorID {
            if identifier != fontAndColorID {
                if hasFontAndColorChange {
                    fontAndColorAlert(identifier)
                    return
                } else {
                    NSFontPanel.sharedFontPanel().orderOut(nil)
                    NSColorPanel.sharedColorPanel().orderOut(nil)
                }
            }
        }
        else if self.window?.title == shortCutID {
            endRecordShortcut()
        }
        self.window?.makeFirstResponder(nil)
        super.displayViewForIdentifier(identifier, animate: animate)
    }
    
// MARK: - General Prefs
    
    @IBAction private func changeLrcSavingPath(sender: AnyObject) {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.beginSheetModalForWindow(self.window!) { (result) -> Void in
            if result == NSFileHandlingPanelOKButton {
                let newPath: String = (openPanel.URL?.path)!
                let userDefaults = NSUserDefaults.standardUserDefaults()
                userDefaults.setObject(newPath, forKey: LyricsUserSavingPath)
                userDefaults.setObject(NSNumber(integer: 1), forKey: LyricsSavingPathPopUpIndex)
                self.savingPathPopUp.itemAtIndex(1)?.title = (newPath as NSString).lastPathComponent
                self.savingPathPopUp.itemAtIndex(1)?.toolTip = newPath
            }
        }
    }
    
    @IBAction private func enableLoginItem(sender: AnyObject) {
        let identifier: String = "Eru.LyricsX-Helper"
        if (sender as! NSButton).state == NSOnState {
            if !SMLoginItemSetEnabled(identifier, true) {
                NSLog("Failed to enable login item")
            }
        } else {
            if !SMLoginItemSetEnabled(identifier, false) {
                NSLog("Failed to disable login item")
            }
        }
    }
    
    @IBAction func reflashLyrics(sender: AnyObject) {
        DesktopLyricsController.sharedController.reflash()
    }
    
// MARK: - Lyrics Prefs
    
    @IBAction func disableLyricsWhenSnapshot(sender: AnyObject) {
        if (sender as! NSButton).state == NSOnState {
            DesktopLyricsController.sharedController.window!.sharingType = .None
        } else {
            DesktopLyricsController.sharedController.window!.sharingType = .ReadOnly
        }
    }
    
    @IBAction func lyricsCanJoinAllDesktop(sender: AnyObject) {
        if (sender as! NSButton).state == NSOnState {
            DesktopLyricsController.sharedController.window!.collectionBehavior = .CanJoinAllSpaces
        } else {
            DesktopLyricsController.sharedController.window!.collectionBehavior = .Default
        }
    }
    
// MARK: - Font and Color Prefs
    
    private func reflashFontAndColorPrefs () {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        font = NSFont(name: userDefaults.stringForKey(LyricsFontName)!, size: CGFloat(userDefaults.floatForKey(LyricsFontSize)))!
        fontDisplayText.stringValue = String(format: "%@ (%.1f)", font.displayName!,font.pointSize)
        
        self.setValue(userDefaults.boolForKey(LyricsShadowModeEnable), forKey: "shadowModeEnabled")
        self.setValue(userDefaults.floatForKey(LyricsShadowRadius), forKey: "shadowRadius")
        self.setValue(userDefaults.floatForKey(LyricsBgHeightINCR), forKey: "bgHeightIncreasement")
        self.setValue(userDefaults.floatForKey(LyricsYOffset), forKey: "lyricsYOffset")
        textColor.color = NSKeyedUnarchiver.unarchiveObjectWithData(userDefaults.dataForKey(LyricsTextColor)!)! as! NSColor
        bkColor.color = NSKeyedUnarchiver.unarchiveObjectWithData(userDefaults.dataForKey(LyricsBackgroundColor)!)! as! NSColor
        shadowColor.color = NSKeyedUnarchiver.unarchiveObjectWithData(userDefaults.dataForKey(LyricsShadowColor)!)! as! NSColor
        textPreview.setAttributs(font, textColor:textColor.color, bkColor: bkColor.color, heightInrc:bgHeightIncreasement, enableShadow: shadowModeEnabled, shadowColor: shadowColor.color, shadowRadius: shadowRadius, yOffset:lyricsYOffset)
    }
    
    @IBAction private func fontAndColorChanged(sender: AnyObject?) {
        if !hasFontAndColorChange {
            revertButton.enabled = true
            applyButton.enabled = true
        }
        hasFontAndColorChange = true
        textPreview.setAttributs(font, textColor:textColor.color, bkColor: bkColor.color, heightInrc:bgHeightIncreasement, enableShadow: shadowModeEnabled, shadowColor: shadowColor.color, shadowRadius: shadowRadius, yOffset:lyricsYOffset)
    }
    
    @IBAction private func applyFontAndColorChanges(sender: AnyObject?) {
        if !canResignFirstResponder() {
            self.window?.makeFirstResponder(nil)
            return
        }
        self.window?.makeFirstResponder(nil)
        hasFontAndColorChange = false
        revertButton.enabled = false
        applyButton.enabled = false
        let userDefaults: NSUserDefaults = NSUserDefaults.standardUserDefaults()
        userDefaults.setObject(font.fontName, forKey: LyricsFontName)
        userDefaults.setFloat(Float(font.pointSize), forKey: LyricsFontSize)
        userDefaults.setFloat(shadowRadius, forKey: LyricsShadowRadius)
        userDefaults.setFloat(bgHeightIncreasement, forKey: LyricsBgHeightINCR)
        userDefaults.setFloat(lyricsYOffset, forKey: LyricsYOffset)
        userDefaults.setBool(shadowModeEnabled, forKey: LyricsShadowModeEnable)
        userDefaults.setObject(NSKeyedArchiver.archivedDataWithRootObject(textColor.color), forKey: LyricsTextColor)
        userDefaults.setObject(NSKeyedArchiver.archivedDataWithRootObject(bkColor.color), forKey: LyricsBackgroundColor)
        userDefaults.setObject(NSKeyedArchiver.archivedDataWithRootObject(shadowColor.color), forKey: LyricsShadowColor)
        DesktopLyricsController.sharedController.handleAttributesUpdate()
    }
    
    @IBAction private func revertFontAndColorChanges(sender: AnyObject?) {
        // If current value is invalid, set one before reverting
        if !canResignFirstResponder() {
            let textView = self.window?.firstResponder as! NSTextView
            textView.string = "0"
        }
        self.window?.makeFirstResponder(nil)
        hasFontAndColorChange = false
        revertButton.enabled = false
        applyButton.enabled = false
        reflashFontAndColorPrefs()
    }
    
    override func changeFont(sender: AnyObject?) {
        font = (sender?.convertFont(font))!
        fontDisplayText.stringValue = String(format: "%@ (%.1f)", font.displayName!,font.pointSize)
        fontAndColorChanged(nil)
    }
    
    override func validModesForFontPanel(fontPanel: NSFontPanel) -> Int {
        return Int(NSFontPanelSizeModeMask | NSFontPanelCollectionModeMask | NSFontPanelFaceModeMask)
    }
    
    @IBAction func showFontPanel(sender: AnyObject) {
        let fontManger: NSFontManager = NSFontManager.sharedFontManager()
        let fontPanel: NSFontPanel = NSFontPanel.sharedFontPanel()
        fontManger.target = self
        fontManger.setSelectedFont(font, isMultiple: false)
        fontPanel.makeKeyAndOrderFront(self)
        fontPanel.delegate = self
    }
    
    private func canResignFirstResponder() -> Bool {
        let currentResponder = self.window?.firstResponder
        if currentResponder != nil && currentResponder!.isKindOfClass(NSTextView) {
            let textField: NSTextField? = (currentResponder as! NSTextView).superview?.superview as? NSTextField
            if textField == nil {
                return true
            }
            let formatter = textField!.formatter as? NSNumberFormatter
            if formatter == nil {
                return true
            }
            let stringValue: String = (currentResponder as! NSTextView).string!
            if formatter!.numberFromString(stringValue) == nil {
                return false
            }
            else {
                return true
            }
        }
        else {
            return true
        }
    }
    
    private func fontAndColorAlert(identifier: String!) {
        // identifier nil means window is about to close
        let alert: NSAlert = NSAlert()
        alert.messageText = NSLocalizedString("CHANGE_UNSAVED", comment: "")
        alert.informativeText = NSLocalizedString("DISGARDS_LEAVE", comment: "")
        alert.addButtonWithTitle(NSLocalizedString("APPLY_LEAVE", comment: ""))
        alert.addButtonWithTitle(NSLocalizedString("REVERT_LEAVE", comment: ""))
        alert.addButtonWithTitle(NSLocalizedString("CANCEL", comment: ""))
        alert.beginSheetModalForWindow(self.window!, completionHandler: { (response) -> Void in
            if response != NSAlertThirdButtonReturn {
                if response == NSAlertFirstButtonReturn {
                    self.applyFontAndColorChanges(nil)
                } else {
                    self.revertFontAndColorChanges(nil)
                }
                if identifier != nil {
                    NSFontPanel.sharedFontPanel().orderOut(nil)
                    NSColorPanel.sharedColorPanel().orderOut(nil)
                    self.displayViewForIdentifier(identifier,animate: false)
                } else {
                    NSFontPanel.sharedFontPanel().orderOut(nil)
                    NSColorPanel.sharedColorPanel().orderOut(nil)
                    self.window?.orderOut(nil)
                }
            }
            else {
                self.window?.toolbar?.selectedItemIdentifier = NSLocalizedString("FONT_COLOR", comment: "")
            }
        })
    }
    
// MARK: - Shortcut Prefs
    
    func setupShortcuts() {
        let appController = AppController.sharedController
        // User shortcuts
        lyricsModeSwitchShortcut.associatedUserDefaultsKey = ShortcutLyricsModeSwitch
        MASShortcutBinder.sharedBinder().bindShortcutWithDefaultsKey(ShortcutLyricsModeSwitch) { () -> Void in
            let userDefaults = NSUserDefaults.standardUserDefaults()
            userDefaults.setBool(!userDefaults.boolForKey(LyricsIsVerticalLyrics), forKey: LyricsIsVerticalLyrics)
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                DesktopLyricsController.sharedController.reflash()
            })
        }
        desktopMenubarSwitchShortcut.associatedUserDefaultsKey = ShortcutDesktopMenubarSwitch
        MASShortcutBinder.sharedBinder().bindShortcutWithDefaultsKey(ShortcutDesktopMenubarSwitch) { () -> Void in
            appController.switchDesktopMenuBarMode()
        }
        lrcSeekerShortcut.associatedUserDefaultsKey = ShortcutOpenLrcSeeker
        MASShortcutBinder.sharedBinder().bindShortcutWithDefaultsKey(ShortcutOpenLrcSeeker) { () -> Void in
            appController.searchLyricsAndArtworks(nil)
        }
        copyLrcToPbShortcut.associatedUserDefaultsKey = ShortcutCopyLrcToPb
        MASShortcutBinder.sharedBinder().bindShortcutWithDefaultsKey(ShortcutCopyLrcToPb) { () -> Void in
            appController.copyLyricsToPb(nil)
        }
        editLrcShortcut.associatedUserDefaultsKey = ShortcutEditLrc
        MASShortcutBinder.sharedBinder().bindShortcutWithDefaultsKey(ShortcutEditLrc) { () -> Void in
            appController.editLyrics(nil)
        }
        makeLrcShortcut.associatedUserDefaultsKey = ShortcutMakeLrc
        MASShortcutBinder.sharedBinder().bindShortcutWithDefaultsKey(ShortcutMakeLrc) { () -> Void in
            appController.makeLrc(nil)
        }
        writeLrcToiTunesShortcut.associatedUserDefaultsKey = ShortcutWriteLrcToiTunes
        MASShortcutBinder.sharedBinder().bindShortcutWithDefaultsKey(ShortcutWriteLrcToiTunes) { () -> Void in
            appController.writeLyricsToiTunes(nil)
        }
        // Hard-Coded shortcuts
        let offsetIncr: MASShortcut = MASShortcut(keyCode: UInt(kVK_ANSI_Equal), modifierFlags: NSEventModifierFlags.CommandKeyMask.rawValue | NSEventModifierFlags.AlternateKeyMask.rawValue)
        MASShortcutMonitor.sharedMonitor().registerShortcut(offsetIncr) { () -> Void in
            appController.increaseTimeDly()
        }
        let offsetDecr: MASShortcut = MASShortcut(keyCode: UInt(kVK_ANSI_Minus), modifierFlags: NSEventModifierFlags.CommandKeyMask.rawValue | NSEventModifierFlags.AlternateKeyMask.rawValue)
        MASShortcutMonitor.sharedMonitor().registerShortcut(offsetDecr) { () -> Void in
            appController.decreaseTimeDly()
        }
    }
    
    private func endRecordShortcut() {
        if lyricsModeSwitchShortcut.recording {
            lyricsModeSwitchShortcut.recording = false
        }
        if desktopMenubarSwitchShortcut.recording {
            desktopMenubarSwitchShortcut.recording = false
        }
        if lrcSeekerShortcut.recording {
            lrcSeekerShortcut.recording = false
        }
        if copyLrcToPbShortcut.recording {
            copyLrcToPbShortcut.recording = false
        }
        if editLrcShortcut.recording {
            editLrcShortcut.recording = false
        }
        if makeLrcShortcut.recording {
            makeLrcShortcut.recording = false
        }
        if writeLrcToiTunesShortcut.recording {
            writeLrcToiTunesShortcut.recording = false
        }
    }
    
// MARK: - Preset Prefs
    
    @IBAction func reflashPreset(sender: AnyObject?) {
        presets.removeAll()
        let fm = NSFileManager.defaultManager()
        let libraryPath: String = NSSearchPathForDirectoriesInDomains(.ApplicationSupportDirectory, [.UserDomainMask], true).first! + "/LyricsX"
        var isDir: ObjCBool = true
        var hasDir: Bool = fm.fileExistsAtPath(libraryPath, isDirectory: &isDir)
        if !isDir {
            do {
                try fm.removeItemAtPath(libraryPath)
            } catch let theError as NSError {
                NSLog("%@", theError.localizedDescription)
                return
            }
            hasDir = false
        }
        if !hasDir {
            do {
                try fm.createDirectoryAtPath(libraryPath, withIntermediateDirectories: true, attributes: nil)
            } catch let theError as NSError {
                NSLog("%@", theError.localizedDescription)
                return
            }
        }
        let files: [String]
        do {
            files = try fm.contentsOfDirectoryAtPath(libraryPath)
        } catch let theError as NSError {
            NSLog("%@", theError.localizedDescription)
            return
        }
        for file in files {
            if (file as NSString).pathExtension == "lxconfig" {
                presets.append((file as NSString).stringByDeletingPathExtension)
            }
        }
        presetListView.reloadData()
        NSNotificationCenter.defaultCenter().postNotificationName(LyricsPresetDidChangedNotification, object: nil)
    }
    
    @IBAction func applyPreset(sender: AnyObject?) {
        let selectedRow: Int = presetListView.selectedRow
        if selectedRow == -1 {
            return
        }
        let libraryPath: NSString = NSSearchPathForDirectoriesInDomains(.ApplicationSupportDirectory, [.UserDomainMask], true).first! + "/LyricsX"
        let savingPath = libraryPath.stringByAppendingPathComponent(presets[selectedRow] + ".lxconfig")
        let dic = NSDictionary(contentsOfFile: savingPath)
        if dic == nil {
            MessageWindowController.sharedMsgWindow.displayMessage(NSLocalizedString("INVALID_PRESET", comment: ""))
            return
        }
        let userDefaults = NSUserDefaults.standardUserDefaults()
        for (key,value) in dic! {
            userDefaults.setObject(value, forKey: key as! String)
        }
        reflashFontAndColorPrefs()
        DesktopLyricsController.sharedController.handleAttributesUpdate()
        DesktopLyricsController.sharedController.checkAutoLayout()
        AppController.sharedController.lockFloatingWindow = false
        MessageWindowController.sharedMsgWindow.displayMessage(NSLocalizedString("PRESET_LOADED", comment: ""))
    }
    
    @IBAction private func addPreset(sender: AnyObject?) {
        presetNameTF.stringValue = NSLocalizedString("UNTITLED_PRESET", comment: "")
        presetNameTF.selectText(nil)
        self.window!.beginSheet(dialog) { (response) -> Void in
            if response == NSModalResponseOK {
                let savingPath: String = NSSearchPathForDirectoriesInDomains(.ApplicationSupportDirectory, [.UserDomainMask], true).first! + "/LyricsX/" + self.presetNameTF.stringValue + ".lxconfig"
                let userDefaults = NSUserDefaults.standardUserDefaults()
                let settings: [String:AnyObject] = [
                    LyricsUseAutoLayout : userDefaults.objectForKey(LyricsUseAutoLayout)!,
                    LyricsHeightFromDockToLyrics : userDefaults.objectForKey(LyricsHeightFromDockToLyrics)!,
                    LyricsConstWidth : userDefaults.objectForKey(LyricsConstWidth)!,
                    LyricsConstHeight: userDefaults.objectForKey(LyricsConstHeight)!,
                    LyricsIsVerticalLyrics : userDefaults.objectForKey(LyricsIsVerticalLyrics)!,
                    LyricsVerticalLyricsPosition: userDefaults.objectForKey(LyricsVerticalLyricsPosition)!,
                    LyricsTwoLineMode : userDefaults.objectForKey(LyricsTwoLineMode)!,
                    LyricsTwoLineModeIndex : userDefaults.objectForKey(LyricsTwoLineModeIndex)!,
                    LyricsDisplayInAllSpaces : userDefaults.objectForKey(LyricsDisplayInAllSpaces)!,
                    LyricsFontName : userDefaults.objectForKey(LyricsFontName)!,
                    LyricsFontSize : userDefaults.objectForKey(LyricsFontSize)!,
                    LyricsShadowModeEnable : userDefaults.objectForKey(LyricsShadowModeEnable)!,
                    LyricsTextColor : userDefaults.objectForKey(LyricsTextColor)!,
                    LyricsBackgroundColor : userDefaults.objectForKey(LyricsBackgroundColor)!,
                    LyricsShadowColor : userDefaults.objectForKey(LyricsShadowColor)!,
                    LyricsShadowRadius : userDefaults.objectForKey(LyricsShadowRadius)!,
                    LyricsBgHeightINCR : userDefaults.objectForKey(LyricsBgHeightINCR)!,
                    LyricsYOffset : userDefaults.objectForKey(LyricsYOffset)!
                ]
                (settings as NSDictionary).writeToFile(savingPath, atomically: false)
                self.presets.append(self.presetNameTF.stringValue)
                self.presetListView.reloadData()
                NSNotificationCenter.defaultCenter().postNotificationName(LyricsPresetDidChangedNotification, object: nil)
            }
        }
    }
    
    @IBAction private func importPreset(sender: AnyObject?) {
        let panel = NSOpenPanel()
        panel.allowedFileTypes = ["lxconfig"]
        panel.extensionHidden = false
        panel.beginSheetModalForWindow(self.window!) { (response) -> Void in
            if response == NSFileHandlingPanelOKButton {
                let libraryPath: NSString = NSSearchPathForDirectoriesInDomains(.ApplicationSupportDirectory, [.UserDomainMask], true).first! + "/LyricsX"
                var presetName: String = panel.URL!.URLByDeletingPathExtension!.lastPathComponent!
                var fileSavingPath: String = libraryPath.stringByAppendingPathComponent(panel.URL!.lastPathComponent!)
                let fm = NSFileManager.defaultManager()
                if fm.fileExistsAtPath(fileSavingPath) {
                    var i: Int = 0
                    repeat {
                        i += 1
                        fileSavingPath = libraryPath.stringByAppendingPathComponent(presetName + " \(i).lxconfig")
                    } while !fm.fileExistsAtPath(fileSavingPath)
                    presetName = presetName + " \(i)"
                }
                do {
                    try fm.copyItemAtPath(panel.URL!.path!, toPath: fileSavingPath)
                } catch let theError as NSError {
                    NSLog("%@", theError.localizedDescription)
                    return
                }
                self.presets.append(presetName)
                self.presetListView.reloadData()
                NSNotificationCenter.defaultCenter().postNotificationName(LyricsPresetDidChangedNotification, object: nil)
            }
        }
    }
    
    @IBAction private func exportPreset(sender: AnyObject?) {
        let selectedRow = presetListView.selectedRow
        if selectedRow == -1 {
            return
        }
        let panel = NSSavePanel()
        panel.allowedFileTypes = ["lxconfig"]
        panel.extensionHidden = true
        panel.nameFieldStringValue = presets[selectedRow] + ".lxconfig"
        panel.beginSheetModalForWindow(self.window!) { (response) -> Void in
            if response == NSFileHandlingPanelOKButton {
                let libraryPath: NSString = NSSearchPathForDirectoriesInDomains(.ApplicationSupportDirectory, [.UserDomainMask], true).first! + "/LyricsX"
                let presetPath = libraryPath.stringByAppendingPathComponent(self.presets[selectedRow] + ".lxconfig")
                let fm = NSFileManager.defaultManager()
                if fm.fileExistsAtPath(panel.URL!.path!) {
                    do {
                        try fm.removeItemAtURL(panel.URL!)
                    } catch let theError as NSError {
                        NSLog("%@", theError.localizedDescription)
                        return
                    }
                }
                do {
                    try fm.copyItemAtPath(presetPath, toPath: panel.URL!.path!)
                } catch let theError as NSError {
                    NSLog("%@", theError.localizedDescription)
                    return
                }
            }
        }
    }
    
    @IBAction func removePreset(sender: AnyObject?) {
        let selectedRow: Int = presetListView.selectedRow
        if selectedRow == -1 {
            return
        }
        let libraryPath: String = NSSearchPathForDirectoriesInDomains(.ApplicationSupportDirectory, [.UserDomainMask], true).first! + "/LyricsX"
        let presetPath: String = (libraryPath as NSString).stringByAppendingPathComponent(presets[selectedRow] + ".lxconfig")
        do {
            try NSFileManager.defaultManager().removeItemAtPath(presetPath)
        } catch let theError as NSError {
            NSLog("%@", theError.localizedDescription)
            return
        }
        presets.removeAtIndex(selectedRow)
        presetListView.reloadData()
        NSNotificationCenter.defaultCenter().postNotificationName(LyricsPresetDidChangedNotification, object: nil)
    }
    
    @IBAction private func renamePreset(sender: AnyObject) {
        let selectedRow: Int = presetListView.selectedRow
        if selectedRow == -1 {
            return
        }
        let oldName = presets[selectedRow]
        presetNameTF.stringValue = oldName
        presetNameTF.selectText(nil)
        self.window?.beginSheet(dialog, completionHandler: { (response) -> Void in
            if response == NSModalResponseOK {
                let libraryPath: NSString = (NSSearchPathForDirectoriesInDomains(.ApplicationSupportDirectory, [.UserDomainMask], true).first! + "/LyricsX") as NSString
                let oldPath = libraryPath.stringByAppendingPathComponent(oldName + ".lxconfig")
                let newPath = libraryPath.stringByAppendingPathComponent(self.presetNameTF.stringValue + ".lxconfig")
                do {
                    try NSFileManager.defaultManager().moveItemAtPath(oldPath, toPath: newPath)
                } catch let theError as NSError {
                    NSLog("%@", theError.localizedDescription)
                    return
                }
                self.presets[selectedRow] = self.presetNameTF.stringValue
                self.presetListView.reloadData()
                NSNotificationCenter.defaultCenter().postNotificationName(LyricsPresetDidChangedNotification, object: nil)
            }
        })
    }
    
    @IBAction private func confirmPrestName(sender: AnyObject) {
        if presetNameTF.stringValue.stringByReplacingOccurrencesOfString(" ", withString: "") == "" {
            NSBeep()
            MessageWindowController.sharedMsgWindow.displayMessage(NSLocalizedString("EMPTY_NAME", comment: ""))
            return
        }
        for preset in presets {
            if preset == presetNameTF.stringValue {
                NSBeep()
                MessageWindowController.sharedMsgWindow.displayMessage(NSLocalizedString("PRESET_EXISTS", comment: ""))
                return
            }
        }
        self.window!.endSheet(dialog, returnCode: NSModalResponseOK)
    }

    @IBAction private func cancelChangePresetName(sender: AnyObject) {
        self.window!.endSheet(dialog, returnCode: NSModalResponseCancel)
    }
    
// MARK: - Filter Prefs   
    
    func loadFilter() {
        let userDefault = NSUserDefaults.standardUserDefaults()
        let directFilterData = userDefault.dataForKey(LyricsDirectFilter)!
        let conditionalFilterData = userDefault.dataForKey(LyricsConditionalFilter)!
        directFilter = NSKeyedUnarchiver.unarchiveObjectWithData(directFilterData) as! [FilterString]
        conditionalFilter = NSKeyedUnarchiver.unarchiveObjectWithData(conditionalFilterData) as! [FilterString]
    }
    
    @IBAction func addKeywordForDirectFilterList(sender: AnyObject) {
        directFilter.append(FilterString())
        dispatch_async(dispatch_get_main_queue()) {
            self.directFilterList.scrollRowToVisible(self.directFilter.count - 1)
            self.directFilterList.editColumn(0, row: self.directFilter.count - 1, withEvent: nil, select: true)
        }
    }
    
    @IBAction func addKeywordForConditionalFilterList(sender: AnyObject) {
        conditionalFilter.append(FilterString())
        dispatch_async(dispatch_get_main_queue()) { 
            self.conditionalFilterList.scrollRowToVisible(self.conditionalFilter.count - 1)
            self.conditionalFilterList.editColumn(0, row: self.conditionalFilter.count - 1, withEvent: nil, select: true)
        }
    }
    
    @IBAction func resetFilterList(sender: AnyObject) {
        let alert: NSAlert = NSAlert()
        alert.messageText = NSLocalizedString("RESET_FILTER", comment: "")
        alert.informativeText = NSLocalizedString("RESET_CONFIRM", comment: "")
        alert.addButtonWithTitle(NSLocalizedString("RESET", comment: ""))
        alert.addButtonWithTitle(NSLocalizedString("CANCEL", comment: ""))
        alert.beginSheetModalForWindow(self.window!) { (response) in
            if response == NSAlertFirstButtonReturn {
                let userDefaults = NSUserDefaults.standardUserDefaults()
                userDefaults.removeObjectForKey(LyricsDirectFilter)
                userDefaults.removeObjectForKey(LyricsConditionalFilter)
                self.directFilter.removeAll()
                self.conditionalFilter.removeAll()
                self.loadFilter()
            }
        }
    }
    
    @IBAction func revertFilterKeyword(sender: AnyObject) {
        self.directFilter.removeAll()
        self.conditionalFilter.removeAll()
        self.loadFilter()
    }
    
    @IBAction func saveFilterKeyword(sender: AnyObject) {
        for filter in directFilter {
            filter.keyword = filter.keyword.stringByReplacingOccurrencesOfString(" ", withString: "")
        }
        for filter in conditionalFilter {
            filter.keyword = filter.keyword.stringByReplacingOccurrencesOfString(" ", withString: "")
        }
        let userDefaults = NSUserDefaults.standardUserDefaults()
        let directFilterData = NSKeyedArchiver.archivedDataWithRootObject(directFilter)
        let conditionalFilterData = NSKeyedArchiver.archivedDataWithRootObject(conditionalFilter)
        userDefaults.setObject(directFilterData, forKey: LyricsDirectFilter)
        userDefaults.setObject(conditionalFilterData, forKey: LyricsConditionalFilter)
    }
    
    @IBAction func showHelp(sender: NSButton) {
        helpPopover.showRelativeToRect(sender.bounds, ofView: sender, preferredEdge: .MaxY)
    }

// MARK: - NSWindow & NSTextField Delegate

    func windowShouldClose(sender: AnyObject) -> Bool {
        if !canResignFirstResponder() {
            self.window?.makeFirstResponder(nil)
            return false
        }
        if (sender as! NSWindow).title == NSLocalizedString("FONT_COLOR", comment: "") {
            if hasFontAndColorChange {
                fontAndColorAlert(nil)
                return false
            } else {
                NSFontPanel.sharedFontPanel().orderOut(nil)
                NSColorPanel.sharedColorPanel().orderOut(nil)
                return true
            }
        }
        return true
    }
    
    override func controlTextDidChange(obj: NSNotification) {
        fontAndColorChanged(nil)
    }
    
// MARK: - NSTableView Delegate & ContextMenuDelegate
    
    func numberOfRowsInTableView(aTableView: NSTableView) -> Int {
        return presets.count
    }
    
    func tableView(aTableView: NSTableView, objectValueForTableColumn aTableColumn: NSTableColumn, row rowIndex: Int) -> AnyObject? {
        return presets[rowIndex]
    }
    
    func tableView(aTableView: NSTableView, menuForRows rows: NSIndexSet) -> NSMenu {
        self.window?.makeFirstResponder(self.presetListView)
        return tableMenu
    }
    
}
