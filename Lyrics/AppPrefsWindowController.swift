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
    
    @IBOutlet fileprivate var generalPrefsView: ClickView!
    @IBOutlet fileprivate var lyricsPrefsView: NSView!
    @IBOutlet fileprivate var fontAndColorPrefsView: ClickView!
    @IBOutlet fileprivate var shortcutPrefsView: NSView!
    @IBOutlet fileprivate var presetPrefsView: ClickView!
    @IBOutlet fileprivate var filterPrefsView: ClickView!
    //General
    @IBOutlet fileprivate weak var savingPathPopUp: NSPopUpButton!
    //Font & Color
    @IBOutlet fileprivate weak var textPreview: TextPreview!
    @IBOutlet fileprivate weak var fontDisplayText: NSTextField!
    @IBOutlet fileprivate weak var textColor: NSColorWell!
    @IBOutlet fileprivate weak var bkColor: NSColorWell!
    @IBOutlet fileprivate weak var shadowColor: NSColorWell!
    @IBOutlet fileprivate weak var revertButton: NSButton!
    @IBOutlet fileprivate weak var applyButton: NSButton!
    fileprivate var hasFontAndColorChange: Bool = false
    fileprivate var font: NSFont!
    var shadowModeEnabled: Bool = false
    var shadowRadius: Float = 0
    var bgHeightIncreasement: Float = 0
    var lyricsYOffset: Float = 0
    //Shortcuts
    @IBOutlet fileprivate weak var offsetIncrShortcut: MASShortcutView!
    @IBOutlet fileprivate weak var offsetDecrShortcut: MASShortcutView!
    @IBOutlet fileprivate weak var lyricsModeSwitchShortcut: MASShortcutView!
    @IBOutlet fileprivate weak var desktopMenubarSwitchShortcut: MASShortcutView!
    @IBOutlet fileprivate weak var lrcSeekerShortcut: MASShortcutView!
    @IBOutlet fileprivate weak var copyLrcToPbShortcut: MASShortcutView!
    @IBOutlet fileprivate weak var editLrcShortcut: MASShortcutView!
    @IBOutlet fileprivate weak var makeLrcShortcut: MASShortcutView!
    @IBOutlet fileprivate weak var writeLrcToiTunesShortcut: MASShortcutView!
    //Preset
    var presets = [String]()
    @IBOutlet weak var presetListView: PresetListView!
    @IBOutlet fileprivate var tableMenu: NSMenu!
    @IBOutlet fileprivate var dialog: NSWindow!
    @IBOutlet fileprivate var presetNameTF: NSTextField!
    //Filter
    dynamic var directFilter = [FilterString]()
    dynamic var conditionalFilter = [FilterString]()
    @IBOutlet var directFilterList: NSTableView!
    @IBOutlet var conditionalFilterList: NSTableView!
    @IBOutlet var helpPopover: NSPopover!
    
//MARK: - Init & Override

    override func windowDidLoad() {
        super.windowDidLoad()
        
        self.window?.delegate = self
        hasFontAndColorChange = false
        
        //Pop up button and font is hard to bind to NSUserDefaultsController, do it by self
        let defaultSavingPath: String = NSSearchPathForDirectoriesInDomains(.musicDirectory, [.userDomainMask], true).first! + "/LyricsX"
        let userSavingPath: String = UserDefaults.standard.string(forKey: LyricsUserSavingPath)!
        savingPathPopUp.item(at: 0)?.toolTip = defaultSavingPath
        savingPathPopUp.item(at: 1)?.toolTip = userSavingPath
        savingPathPopUp.item(at: 1)?.title = (userSavingPath as NSString).lastPathComponent
        
        reflashFontAndColorPrefs()
        bindShortcutViewToKey()
        reflashPreset(nil)
        loadFilter()
    }
    
    override func setupToolbar () {
        self.add(generalPrefsView, label: NSLocalizedString("GENERAL", comment: ""), image: NSImage(named: NSImageNamePreferencesGeneral))
        self.add(lyricsPrefsView, label: NSLocalizedString("LYRICS", comment: ""), image: NSImage(named: "lyrics_icon"))
        self.add(fontAndColorPrefsView, label: NSLocalizedString("FONT_COLOR", comment: ""), image: NSImage(named: "font_Color_icon"))
        self.add(shortcutPrefsView, label: NSLocalizedString("SHORTCUT", comment: ""), image: NSImage(named: "shortcut"))
        self.add(presetPrefsView, label: NSLocalizedString("PRESET", comment: ""), image: NSImage(named: NSImageNameAdvanced))
        self.add(filterPrefsView, label: NSLocalizedString("FILTER", comment: ""), image: NSImage(named:"Delete"))
    }
    
    override func displayView(forIdentifier identifier: String, animate: Bool) {
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
                    NSFontPanel.shared().orderOut(nil)
                    NSColorPanel.shared().orderOut(nil)
                }
            }
        }
        else if self.window?.title == shortCutID {
            endRecordShortcut()
        }
        self.window?.makeFirstResponder(nil)
        super.displayView(forIdentifier: identifier, animate: animate)
    }
    
// MARK: - General Prefs
    
    @IBAction fileprivate func changeLrcSavingPath(_ sender: AnyObject) {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.beginSheetModal(for: self.window!) { (result) -> Void in
            if result == NSFileHandlingPanelOKButton {
                let newPath: String = (openPanel.url?.path)!
                let userDefaults = UserDefaults.standard
                userDefaults.set(newPath, forKey: LyricsUserSavingPath)
                userDefaults.set(NSNumber(value: 1 as Int), forKey: LyricsSavingPathPopUpIndex)
                self.savingPathPopUp.item(at: 1)?.title = (newPath as NSString).lastPathComponent
                self.savingPathPopUp.item(at: 1)?.toolTip = newPath
            }
        }
    }
    
    @IBAction fileprivate func enableLoginItem(_ sender: AnyObject) {
        let identifier: String = "Eru.LyricsX-Helper"
        if (sender as! NSButton).state == NSOnState {
            if !SMLoginItemSetEnabled(identifier as CFString, true) {
                NSLog("Failed to enable login item")
            }
        } else {
            if !SMLoginItemSetEnabled(identifier as CFString, false) {
                NSLog("Failed to disable login item")
            }
        }
    }
    
    @IBAction func reflashLyrics(_ sender: AnyObject) {
        DesktopLyricsController.sharedController.reflash()
    }
    
// MARK: - Lyrics Prefs
    
    @IBAction func disableLyricsWhenSnapshot(_ sender: AnyObject) {
        if (sender as! NSButton).state == NSOnState {
            DesktopLyricsController.sharedController.window!.sharingType = .none
        } else {
            DesktopLyricsController.sharedController.window!.sharingType = .readOnly
        }
    }
    
    @IBAction func lyricsCanJoinAllDesktop(_ sender: AnyObject) {
        if (sender as! NSButton).state == NSOnState {
            DesktopLyricsController.sharedController.window!.collectionBehavior = .canJoinAllSpaces
        } else {
            DesktopLyricsController.sharedController.window!.collectionBehavior = NSWindowCollectionBehavior()
        }
    }
    
// MARK: - Font and Color Prefs
    
    fileprivate func reflashFontAndColorPrefs () {
        let userDefaults = UserDefaults.standard
        font = NSFont(name: userDefaults.string(forKey: LyricsFontName)!, size: CGFloat(userDefaults.float(forKey: LyricsFontSize)))!
        fontDisplayText.stringValue = String(format: "%@ (%.1f)", font.displayName!,font.pointSize)
        
        self.setValue(userDefaults.bool(forKey: LyricsShadowModeEnable), forKey: "shadowModeEnabled")
        self.setValue(userDefaults.float(forKey: LyricsShadowRadius), forKey: "shadowRadius")
        self.setValue(userDefaults.float(forKey: LyricsBgHeightINCR), forKey: "bgHeightIncreasement")
        self.setValue(userDefaults.float(forKey: LyricsYOffset), forKey: "lyricsYOffset")
        textColor.color = NSKeyedUnarchiver.unarchiveObject(with: userDefaults.data(forKey: LyricsTextColor)!)! as! NSColor
        bkColor.color = NSKeyedUnarchiver.unarchiveObject(with: userDefaults.data(forKey: LyricsBackgroundColor)!)! as! NSColor
        shadowColor.color = NSKeyedUnarchiver.unarchiveObject(with: userDefaults.data(forKey: LyricsShadowColor)!)! as! NSColor
        textPreview.setAttributs(font, textColor:textColor.color, bkColor: bkColor.color, heightInrc:bgHeightIncreasement, enableShadow: shadowModeEnabled, shadowColor: shadowColor.color, shadowRadius: shadowRadius, yOffset:lyricsYOffset)
    }
    
    @IBAction fileprivate func fontAndColorChanged(_ sender: AnyObject?) {
        if !hasFontAndColorChange {
            revertButton.isEnabled = true
            applyButton.isEnabled = true
        }
        hasFontAndColorChange = true
        textPreview.setAttributs(font, textColor:textColor.color, bkColor: bkColor.color, heightInrc:bgHeightIncreasement, enableShadow: shadowModeEnabled, shadowColor: shadowColor.color, shadowRadius: shadowRadius, yOffset:lyricsYOffset)
    }
    
    @IBAction fileprivate func applyFontAndColorChanges(_ sender: AnyObject?) {
        if !canResignFirstResponder() {
            self.window?.makeFirstResponder(nil)
            return
        }
        self.window?.makeFirstResponder(nil)
        hasFontAndColorChange = false
        revertButton.isEnabled = false
        applyButton.isEnabled = false
        let userDefaults: UserDefaults = UserDefaults.standard
        userDefaults.set(font.fontName, forKey: LyricsFontName)
        userDefaults.set(Float(font.pointSize), forKey: LyricsFontSize)
        userDefaults.set(shadowRadius, forKey: LyricsShadowRadius)
        userDefaults.set(bgHeightIncreasement, forKey: LyricsBgHeightINCR)
        userDefaults.set(lyricsYOffset, forKey: LyricsYOffset)
        userDefaults.set(shadowModeEnabled, forKey: LyricsShadowModeEnable)
        userDefaults.set(NSKeyedArchiver.archivedData(withRootObject: textColor.color), forKey: LyricsTextColor)
        userDefaults.set(NSKeyedArchiver.archivedData(withRootObject: bkColor.color), forKey: LyricsBackgroundColor)
        userDefaults.set(NSKeyedArchiver.archivedData(withRootObject: shadowColor.color), forKey: LyricsShadowColor)
        DesktopLyricsController.sharedController.handleAttributesUpdate()
    }
    
    @IBAction fileprivate func revertFontAndColorChanges(_ sender: AnyObject?) {
        // If current value is invalid, set one before reverting
        if !canResignFirstResponder() {
            let textView = self.window?.firstResponder as! NSTextView
            textView.string = "0"
        }
        self.window?.makeFirstResponder(nil)
        hasFontAndColorChange = false
        revertButton.isEnabled = false
        applyButton.isEnabled = false
        reflashFontAndColorPrefs()
    }
    
    override func changeFont(_ sender: Any?) {
        font = (sender as! NSFontManager).convert(font)
        fontDisplayText.stringValue = String(format: "%@ (%.1f)", font.displayName!,font.pointSize)
        fontAndColorChanged(nil)
    }
    
    override func validModesForFontPanel(_ fontPanel: NSFontPanel) -> Int {
        return Int(NSFontPanelSizeModeMask | NSFontPanelCollectionModeMask | NSFontPanelFaceModeMask)
    }
    
    @IBAction func showFontPanel(_ sender: AnyObject) {
        let fontManger: NSFontManager = NSFontManager.shared()
        let fontPanel: NSFontPanel = NSFontPanel.shared()
        fontManger.target = self
        fontManger.setSelectedFont(font, isMultiple: false)
        fontPanel.makeKeyAndOrderFront(self)
        fontPanel.delegate = self
    }
    
    fileprivate func canResignFirstResponder() -> Bool {
        let currentResponder = self.window?.firstResponder
        if currentResponder != nil && currentResponder!.isKind(of: NSTextView.self) {
            let textField: NSTextField? = (currentResponder as! NSTextView).superview?.superview as? NSTextField
            if textField == nil {
                return true
            }
            let formatter = textField!.formatter as? NumberFormatter
            if formatter == nil {
                return true
            }
            let stringValue: String = (currentResponder as! NSTextView).string!
            if formatter!.number(from: stringValue) == nil {
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
    
    fileprivate func fontAndColorAlert(_ identifier: String!) {
        // identifier nil means window is about to close
        let alert: NSAlert = NSAlert()
        alert.messageText = NSLocalizedString("CHANGE_UNSAVED", comment: "")
        alert.informativeText = NSLocalizedString("DISGARDS_LEAVE", comment: "")
        alert.addButton(withTitle: NSLocalizedString("APPLY_LEAVE", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("REVERT_LEAVE", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("CANCEL", comment: ""))
        alert.beginSheetModal(for: self.window!, completionHandler: { (response) -> Void in
            if response != NSAlertThirdButtonReturn {
                if response == NSAlertFirstButtonReturn {
                    self.applyFontAndColorChanges(nil)
                } else {
                    self.revertFontAndColorChanges(nil)
                }
                if identifier != nil {
                    NSFontPanel.shared().orderOut(nil)
                    NSColorPanel.shared().orderOut(nil)
                    self.displayView(forIdentifier: identifier,animate: false)
                } else {
                    NSFontPanel.shared().orderOut(nil)
                    NSColorPanel.shared().orderOut(nil)
                    self.window?.orderOut(nil)
                }
            }
            else {
                self.window?.toolbar?.selectedItemIdentifier = NSLocalizedString("FONT_COLOR", comment: "")
            }
        })
    }
    
// MARK: - Shortcut Prefs
    
    func bindShortcutViewToKey() {
        offsetIncrShortcut.associatedUserDefaultsKey = ShortcutOffsetIncr
        offsetDecrShortcut.associatedUserDefaultsKey = ShortcutOffsetDecr
        lyricsModeSwitchShortcut.associatedUserDefaultsKey = ShortcutLyricsModeSwitch
        desktopMenubarSwitchShortcut.associatedUserDefaultsKey = ShortcutDesktopMenubarSwitch
        lrcSeekerShortcut.associatedUserDefaultsKey = ShortcutOpenLrcSeeker
        copyLrcToPbShortcut.associatedUserDefaultsKey = ShortcutCopyLrcToPb
        editLrcShortcut.associatedUserDefaultsKey = ShortcutEditLrc
        makeLrcShortcut.associatedUserDefaultsKey = ShortcutMakeLrc
        writeLrcToiTunesShortcut.associatedUserDefaultsKey = ShortcutWriteLrcToiTunes
    }
    
    fileprivate func endRecordShortcut() {
        if lyricsModeSwitchShortcut.isRecording {
            lyricsModeSwitchShortcut.isRecording = false
        }
        if desktopMenubarSwitchShortcut.isRecording {
            desktopMenubarSwitchShortcut.isRecording = false
        }
        if lrcSeekerShortcut.isRecording {
            lrcSeekerShortcut.isRecording = false
        }
        if copyLrcToPbShortcut.isRecording {
            copyLrcToPbShortcut.isRecording = false
        }
        if editLrcShortcut.isRecording {
            editLrcShortcut.isRecording = false
        }
        if makeLrcShortcut.isRecording {
            makeLrcShortcut.isRecording = false
        }
        if writeLrcToiTunesShortcut.isRecording {
            writeLrcToiTunesShortcut.isRecording = false
        }
    }
    
// MARK: - Preset Prefs
    
    @IBAction func reflashPreset(_ sender: AnyObject?) {
        presets.removeAll()
        let fm = FileManager.default
        let libraryPath: String = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, [.userDomainMask], true).first! + "/LyricsX"
        var isDir = ObjCBool(true)
        var hasDir: Bool = fm.fileExists(atPath: libraryPath, isDirectory: &isDir)
        if !isDir.boolValue {
            do {
                try fm.removeItem(atPath: libraryPath)
            } catch let theError as NSError {
                NSLog("%@", theError.localizedDescription)
                return
            }
            hasDir = false
        }
        if !hasDir {
            do {
                try fm.createDirectory(atPath: libraryPath, withIntermediateDirectories: true, attributes: nil)
            } catch let theError as NSError {
                NSLog("%@", theError.localizedDescription)
                return
            }
        }
        let files: [String]
        do {
            files = try fm.contentsOfDirectory(atPath: libraryPath)
        } catch let theError as NSError {
            NSLog("%@", theError.localizedDescription)
            return
        }
        for file in files {
            if (file as NSString).pathExtension == "lxconfig" {
                presets.append((file as NSString).deletingPathExtension)
            }
        }
        presetListView.reloadData()
        NotificationCenter.default.post(name: Notification.Name(rawValue: LyricsPresetDidChangedNotification), object: nil)
    }
    
    @IBAction func applyPreset(_ sender: AnyObject?) {
        let selectedRow: Int = presetListView.selectedRow
        if selectedRow == -1 {
            return
        }
        let libraryPath: NSString = (NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, [.userDomainMask], true).first! + "/LyricsX") as NSString
        let savingPath = libraryPath.appendingPathComponent(presets[selectedRow] + ".lxconfig")
        let dic = NSDictionary(contentsOfFile: savingPath)
        if dic == nil {
            MessageWindowController.sharedMsgWindow.displayMessage(NSLocalizedString("INVALID_PRESET", comment: ""))
            return
        }
        let userDefaults = UserDefaults.standard
        for (key,value) in dic! {
            userDefaults.set(value, forKey: key as! String)
        }
        reflashFontAndColorPrefs()
        DesktopLyricsController.sharedController.handleAttributesUpdate()
        DesktopLyricsController.sharedController.checkAutoLayout()
        AppController.sharedController.lockFloatingWindow = false
        MessageWindowController.sharedMsgWindow.displayMessage(NSLocalizedString("PRESET_LOADED", comment: ""))
    }
    
    @IBAction fileprivate func addPreset(_ sender: AnyObject?) {
        presetNameTF.stringValue = NSLocalizedString("UNTITLED_PRESET", comment: "")
        presetNameTF.selectText(nil)
        self.window!.beginSheet(dialog) { (response) -> Void in
            if response == NSModalResponseOK {
                let savingPath: String = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, [.userDomainMask], true).first! + "/LyricsX/" + self.presetNameTF.stringValue + ".lxconfig"
                let userDefaults = UserDefaults.standard
                let settings: [String:AnyObject] = [
                    LyricsUseAutoLayout : userDefaults.object(forKey: LyricsUseAutoLayout)! as AnyObject,
                    LyricsHeightFromDockToLyrics : userDefaults.object(forKey: LyricsHeightFromDockToLyrics)! as AnyObject,
                    LyricsConstWidth : userDefaults.object(forKey: LyricsConstWidth)! as AnyObject,
                    LyricsConstHeight: userDefaults.object(forKey: LyricsConstHeight)! as AnyObject,
                    LyricsIsVerticalLyrics : userDefaults.object(forKey: LyricsIsVerticalLyrics)! as AnyObject,
                    LyricsVerticalLyricsPosition: userDefaults.object(forKey: LyricsVerticalLyricsPosition)! as AnyObject,
                    LyricsTwoLineMode : userDefaults.object(forKey: LyricsTwoLineMode)! as AnyObject,
                    LyricsTwoLineModeIndex : userDefaults.object(forKey: LyricsTwoLineModeIndex)! as AnyObject,
                    LyricsDisplayInAllSpaces : userDefaults.object(forKey: LyricsDisplayInAllSpaces)! as AnyObject,
                    LyricsFontName : userDefaults.object(forKey: LyricsFontName)! as AnyObject,
                    LyricsFontSize : userDefaults.object(forKey: LyricsFontSize)! as AnyObject,
                    LyricsShadowModeEnable : userDefaults.object(forKey: LyricsShadowModeEnable)! as AnyObject,
                    LyricsTextColor : userDefaults.object(forKey: LyricsTextColor)! as AnyObject,
                    LyricsBackgroundColor : userDefaults.object(forKey: LyricsBackgroundColor)! as AnyObject,
                    LyricsShadowColor : userDefaults.object(forKey: LyricsShadowColor)! as AnyObject,
                    LyricsShadowRadius : userDefaults.object(forKey: LyricsShadowRadius)! as AnyObject,
                    LyricsBgHeightINCR : userDefaults.object(forKey: LyricsBgHeightINCR)! as AnyObject,
                    LyricsYOffset : userDefaults.object(forKey: LyricsYOffset)! as AnyObject
                ]
                (settings as NSDictionary).write(toFile: savingPath, atomically: false)
                self.presets.append(self.presetNameTF.stringValue)
                self.presetListView.reloadData()
                NotificationCenter.default.post(name: Notification.Name(rawValue: LyricsPresetDidChangedNotification), object: nil)
            }
        }
    }
    
    @IBAction fileprivate func importPreset(_ sender: AnyObject?) {
        let panel = NSOpenPanel()
        panel.allowedFileTypes = ["lxconfig"]
        panel.isExtensionHidden = false
        panel.beginSheetModal(for: self.window!) { (response) -> Void in
            if response == NSFileHandlingPanelOKButton {
                let libraryPath: NSString = (NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, [.userDomainMask], true).first! + "/LyricsX") as NSString
                var presetName: String = panel.url!.deletingPathExtension().lastPathComponent
                var fileSavingPath: String = libraryPath.appendingPathComponent(panel.url!.lastPathComponent)
                let fm = FileManager.default
                if fm.fileExists(atPath: fileSavingPath) {
                    var i: Int = 0
                    repeat {
                        i += 1
                        fileSavingPath = libraryPath.appendingPathComponent(presetName + " \(i).lxconfig")
                    } while !fm.fileExists(atPath: fileSavingPath)
                    presetName = presetName + " \(i)"
                }
                do {
                    try fm.copyItem(atPath: panel.url!.path, toPath: fileSavingPath)
                } catch let theError as NSError {
                    NSLog("%@", theError.localizedDescription)
                    return
                }
                self.presets.append(presetName)
                self.presetListView.reloadData()
                NotificationCenter.default.post(name: Notification.Name(rawValue: LyricsPresetDidChangedNotification), object: nil)
            }
        }
    }
    
    @IBAction fileprivate func exportPreset(_ sender: AnyObject?) {
        let selectedRow = presetListView.selectedRow
        if selectedRow == -1 {
            return
        }
        let panel = NSSavePanel()
        panel.allowedFileTypes = ["lxconfig"]
        panel.isExtensionHidden = true
        panel.nameFieldStringValue = presets[selectedRow] + ".lxconfig"
        panel.beginSheetModal(for: self.window!) { (response) -> Void in
            if response == NSFileHandlingPanelOKButton {
                let libraryPath: NSString = (NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, [.userDomainMask], true).first! + "/LyricsX") as NSString
                let presetPath = libraryPath.appendingPathComponent(self.presets[selectedRow] + ".lxconfig")
                let fm = FileManager.default
                if fm.fileExists(atPath: panel.url!.path) {
                    do {
                        try fm.removeItem(at: panel.url!)
                    } catch let theError as NSError {
                        NSLog("%@", theError.localizedDescription)
                        return
                    }
                }
                do {
                    try fm.copyItem(atPath: presetPath, toPath: panel.url!.path)
                } catch let theError as NSError {
                    NSLog("%@", theError.localizedDescription)
                    return
                }
            }
        }
    }
    
    @IBAction func removePreset(_ sender: AnyObject?) {
        let selectedRow: Int = presetListView.selectedRow
        if selectedRow == -1 {
            return
        }
        let libraryPath: String = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, [.userDomainMask], true).first! + "/LyricsX"
        let presetPath: String = (libraryPath as NSString).appendingPathComponent(presets[selectedRow] + ".lxconfig")
        do {
            try FileManager.default.removeItem(atPath: presetPath)
        } catch let theError as NSError {
            NSLog("%@", theError.localizedDescription)
            return
        }
        presets.remove(at: selectedRow)
        presetListView.reloadData()
        NotificationCenter.default.post(name: Notification.Name(rawValue: LyricsPresetDidChangedNotification), object: nil)
    }
    
    @IBAction fileprivate func renamePreset(_ sender: AnyObject) {
        let selectedRow: Int = presetListView.selectedRow
        if selectedRow == -1 {
            return
        }
        let oldName = presets[selectedRow]
        presetNameTF.stringValue = oldName
        presetNameTF.selectText(nil)
        self.window?.beginSheet(dialog, completionHandler: { (response) -> Void in
            if response == NSModalResponseOK {
                let libraryPath: NSString = (NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, [.userDomainMask], true).first! + "/LyricsX") as NSString
                let oldPath = libraryPath.appendingPathComponent(oldName + ".lxconfig")
                let newPath = libraryPath.appendingPathComponent(self.presetNameTF.stringValue + ".lxconfig")
                do {
                    try FileManager.default.moveItem(atPath: oldPath, toPath: newPath)
                } catch let theError as NSError {
                    NSLog("%@", theError.localizedDescription)
                    return
                }
                self.presets[selectedRow] = self.presetNameTF.stringValue
                self.presetListView.reloadData()
                NotificationCenter.default.post(name: Notification.Name(rawValue: LyricsPresetDidChangedNotification), object: nil)
            }
        })
    }
    
    @IBAction fileprivate func confirmPrestName(_ sender: AnyObject) {
        if presetNameTF.stringValue.replacingOccurrences(of: " ", with: "") == "" {
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

    @IBAction fileprivate func cancelChangePresetName(_ sender: AnyObject) {
        self.window!.endSheet(dialog, returnCode: NSModalResponseCancel)
    }
    
// MARK: - Filter Prefs   
    
    func loadFilter() {
        let userDefault = UserDefaults.standard
        let directFilterData = userDefault.data(forKey: LyricsDirectFilterKey)!
        let conditionalFilterData = userDefault.data(forKey: LyricsConditionalFilterKey)!
        directFilter = NSKeyedUnarchiver.unarchiveObject(with: directFilterData) as! [FilterString]
        conditionalFilter = NSKeyedUnarchiver.unarchiveObject(with: conditionalFilterData) as! [FilterString]
    }
    
    @IBAction func addKeywordForDirectFilterList(_ sender: AnyObject) {
        directFilter.append(FilterString())
        DispatchQueue.main.async {
            self.directFilterList.scrollRowToVisible(self.directFilter.count - 1)
            self.directFilterList.editColumn(0, row: self.directFilter.count - 1, with: nil, select: true)
        }
    }
    
    @IBAction func addKeywordForConditionalFilterList(_ sender: AnyObject) {
        conditionalFilter.append(FilterString())
        DispatchQueue.main.async { 
            self.conditionalFilterList.scrollRowToVisible(self.conditionalFilter.count - 1)
            self.conditionalFilterList.editColumn(0, row: self.conditionalFilter.count - 1, with: nil, select: true)
        }
    }
    
    @IBAction func resetFilterList(_ sender: AnyObject) {
        let alert: NSAlert = NSAlert()
        alert.messageText = NSLocalizedString("RESET_FILTER", comment: "")
        alert.informativeText = NSLocalizedString("RESET_CONFIRM", comment: "")
        alert.addButton(withTitle: NSLocalizedString("RESET", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("CANCEL", comment: ""))
        alert.beginSheetModal(for: self.window!, completionHandler: { (response) in
            if response == NSAlertFirstButtonReturn {
                let userDefaults = UserDefaults.standard
                userDefaults.removeObject(forKey: LyricsDirectFilterKey)
                userDefaults.removeObject(forKey: LyricsConditionalFilterKey)
                self.directFilter.removeAll()
                self.conditionalFilter.removeAll()
                self.loadFilter()
            }
        }) 
    }
    
    @IBAction func revertFilterKeyword(_ sender: AnyObject) {
        self.directFilter.removeAll()
        self.conditionalFilter.removeAll()
        self.loadFilter()
    }
    
    @IBAction func saveFilterKeyword(_ sender: AnyObject) {
        for filter in directFilter {
            filter.keyword = filter.keyword.replacingOccurrences(of: " ", with: "")
        }
        for filter in conditionalFilter {
            filter.keyword = filter.keyword.replacingOccurrences(of: " ", with: "")
        }
        let userDefaults = UserDefaults.standard
        let directFilterData = NSKeyedArchiver.archivedData(withRootObject: directFilter)
        let conditionalFilterData = NSKeyedArchiver.archivedData(withRootObject: conditionalFilter)
        userDefaults.set(directFilterData, forKey: LyricsDirectFilterKey)
        userDefaults.set(conditionalFilterData, forKey: LyricsConditionalFilterKey)
    }
    
    @IBAction func showHelp(_ sender: NSButton) {
        helpPopover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .maxY)
    }

// MARK: - NSWindow & NSTextField Delegate

    func windowShouldClose(_ sender: Any) -> Bool {
        if !canResignFirstResponder() {
            self.window?.makeFirstResponder(nil)
            return false
        }
        if (sender as! NSWindow).title == NSLocalizedString("FONT_COLOR", comment: "") {
            if hasFontAndColorChange {
                fontAndColorAlert(nil)
                return false
            } else {
                NSFontPanel.shared().orderOut(nil)
                NSColorPanel.shared().orderOut(nil)
                return true
            }
        }
        return true
    }
    
    override func controlTextDidChange(_ obj: Notification) {
        fontAndColorChanged(nil)
    }
    
// MARK: - NSTableView Delegate & ContextMenuDelegate
    
    func numberOfRowsInTableView(_ aTableView: NSTableView) -> Int {
        return presets.count
    }
    
    func tableView(_ aTableView: NSTableView, objectValueForTableColumn aTableColumn: NSTableColumn, row rowIndex: Int) -> AnyObject? {
        return presets[rowIndex] as AnyObject?
    }
    
    func tableView(_ aTableView: NSTableView, menuForRows rows: IndexSet) -> NSMenu {
        self.window?.makeFirstResponder(self.presetListView)
        return tableMenu
    }
    
}
