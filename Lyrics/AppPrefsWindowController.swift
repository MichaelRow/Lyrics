//
//  Controller.swift
//  Lyrics
//
//  Created by Eru on 15/11/11.
//  Copyright © 2015年 Eru. All rights reserved.
//

import Cocoa
import ServiceManagement

class AppPrefsWindowController: DBPrefsWindowController,NSWindowDelegate {
    
    @IBOutlet private var generalPrefsView:NSView!
    @IBOutlet private var lyricsPrefsView:NSView!
    @IBOutlet private var fontAndColorPrefsView:NSView!
    @IBOutlet private var shortcutPrefsView:NSView!
    @IBOutlet private var donateView:NSView!
    //General
    @IBOutlet private weak var savingPathPopUp: NSPopUpButton!
    //Font & Color
    @IBOutlet private weak var textPreview: TextPreview!
    @IBOutlet private weak var fontDisplayText: NSTextField!
    @IBOutlet private weak var textColor: NSColorWell!
    @IBOutlet private weak var bkColor: NSColorWell!
    @IBOutlet private weak var shadowColor: NSColorWell!
    //Shortcuts
    @IBOutlet private weak var lyricsModeSwitchShortcut: MASShortcutView!
    @IBOutlet private weak var desktopMenubarSwitchShortcut: MASShortcutView!
    @IBOutlet private weak var lrcSeekerShortcut: MASShortcutView!
    @IBOutlet private weak var copyLrcToPbShortcut: MASShortcutView!
    @IBOutlet private weak var editLrcShortcut: MASShortcutView!
    @IBOutlet private weak var makeLrcShortcut: MASShortcutView!
    @IBOutlet private weak var writeLrcToiTunesShortcut: MASShortcutView!
    
    @IBOutlet weak var revertButton: NSButton!
    @IBOutlet weak var applyButton: NSButton!
    
    var shadowModeEnabled: Bool = false
    var shadowRadius: Float = 0
    var bgHeightIncreasement: Float = 0
    var lyricsYOffset: Float = 0
    
    private var hasUnsavedChange: Bool = false
    private var font: NSFont!
    
//MARK: - Init

    override func windowDidLoad() {
        super.windowDidLoad()
        self.window?.delegate = self
        hasUnsavedChange = false
        
        //Pop up button and font is hard to bind to NSUserDefaultsController, do it by self
        let defaultSavingPath: String = NSSearchPathForDirectoriesInDomains(.MusicDirectory, [.UserDomainMask], true).first! + "/LyricsX"
        let userSavingPath: NSString = NSUserDefaults.standardUserDefaults().stringForKey(LyricsUserSavingPath)!
        savingPathPopUp.itemAtIndex(0)?.toolTip = defaultSavingPath
        savingPathPopUp.itemAtIndex(1)?.toolTip = userSavingPath as String
        savingPathPopUp.itemAtIndex(1)?.title = userSavingPath.lastPathComponent
        
        reflashFontAndColorPrefs()
        setupShortcuts()
    }
    
    override func setupToolbar () {
        self.addView(generalPrefsView, label: NSLocalizedString("GENERAL", comment: ""), image: NSImage(named: "general_icon"))
        self.addView(lyricsPrefsView, label: NSLocalizedString("LYRICS", comment: ""), image: NSImage(named: "lyrics_icon"))
        self.addView(fontAndColorPrefsView, label: NSLocalizedString("FONT_COLOR", comment: ""), image: NSImage(named: "font_Color_icon"))
        self.addView(shortcutPrefsView, label: NSLocalizedString("SHORTCUT", comment: ""), image: NSImage(named: "shortcut"))
        self.addFlexibleSpacer()
        self.addView(donateView, label: NSLocalizedString("DONATE", comment: ""), image: NSImage(named: "donate_icon"))
        self.crossFade=true
        self.shiftSlowsAnimation=false
    }
    
    private func setupShortcuts() {
        let appController = AppController.sharedAppController
        // User shortcuts
        lyricsModeSwitchShortcut.associatedUserDefaultsKey = ShortcutLyricsModeSwitch
        MASShortcutBinder.sharedBinder().bindShortcutWithDefaultsKey(ShortcutLyricsModeSwitch) { () -> Void in
            appController.changeLyricsMode(nil)
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
    
//MARK: - Override
    
    override func displayViewForIdentifier(identifier: String, animate: Bool) {
        //If uncommited value exists, there must be a NSTextField object which is 
        //First responder. And if the value is invalid, invoke NSNumber formatter
        //by resigning the first responder.
        if !checkTextFieldNumberValid() {
            self.window?.makeFirstResponder(nil)
            self.window?.toolbar?.selectedItemIdentifier = self.window?.title
            return
        }
        //check if changes are unsaved
        let fontAndColorID: String = NSLocalizedString("FONT_COLOR", comment: "")
        if self.window?.title == fontAndColorID {
            if identifier != fontAndColorID {
                if hasUnsavedChange {
                    displayAlert(identifier)
                    return
                } else {
                    NSFontPanel.sharedFontPanel().orderOut(nil)
                    NSColorPanel.sharedColorPanel().orderOut(nil)
                }
            }
        }
        self.window?.makeFirstResponder(nil)
        super.displayViewForIdentifier(identifier, animate: animate)
    }
    
// MARK: - General Prefs
    
    @IBAction func changeLrcSavingPath(sender: AnyObject) {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.beginSheetModalForWindow(self.window!) { (result) -> Void in
            if result == NSFileHandlingPanelOKButton {
                let newPath: NSString = (openPanel.URL?.path)!
                let userDefaults = NSUserDefaults.standardUserDefaults()
                userDefaults.setObject(newPath, forKey: LyricsUserSavingPath)
                userDefaults.setObject(NSNumber(integer: 1), forKey: LyricsSavingPathPopUpIndex)
                self.savingPathPopUp.itemAtIndex(1)?.title = newPath.lastPathComponent
                self.savingPathPopUp.itemAtIndex(1)?.toolTip = newPath as String
            }
        }
    }
    
    @IBAction func enableLoginItem(sender: AnyObject) {
        let identifier: String = "Eru.LyricsX-Helper"
        if (sender as! NSButton).state == NSOnState {
            if !SMLoginItemSetEnabled((identifier as CFStringRef), true) {
                NSLog("Failed to enable login item")
            }
        } else {
            if !SMLoginItemSetEnabled(identifier, false) {
                NSLog("Failed to disable login item")
            }
        }
        
    }
    
    @IBAction func reflashLyrics(sender: AnyObject) {
        NSNotificationCenter.defaultCenter().postNotificationName(LyricsLayoutChangeNotification, object: nil)
    }
    
// MARK: - Font and Color Prefs
    
    func reflashFontAndColorPrefs () {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        font = NSFont(name: userDefaults.stringForKey(LyricsFontName)!, size: CGFloat(userDefaults.floatForKey(LyricsFontSize)))!
        fontDisplayText.stringValue = NSString(format: "%@, %.1f", font.displayName!,font.pointSize) as String
        
        self.setValue(userDefaults.boolForKey(LyricsShadowModeEnable), forKey: "shadowModeEnabled")
        self.setValue(userDefaults.floatForKey(LyricsShadowRadius), forKey: "shadowRadius")
        self.setValue(userDefaults.floatForKey(LyricsBgHeightINCR), forKey: "bgHeightIncreasement")
        self.setValue(userDefaults.floatForKey(LyricsYOffset), forKey: "lyricsYOffset")
        textColor.color = NSKeyedUnarchiver.unarchiveObjectWithData(userDefaults.dataForKey(LyricsTextColor)!)! as! NSColor
        bkColor.color = NSKeyedUnarchiver.unarchiveObjectWithData(userDefaults.dataForKey(LyricsBackgroundColor)!)! as! NSColor
        shadowColor.color = NSKeyedUnarchiver.unarchiveObjectWithData(userDefaults.dataForKey(LyricsShadowColor)!)! as! NSColor
        textPreview.setAttributs(font, textColor:textColor.color, bkColor: bkColor.color, heightInrc:bgHeightIncreasement, enableShadow: shadowModeEnabled, shadowColor: shadowColor.color, shadowRadius: shadowRadius, yOffset:lyricsYOffset)
    }
    
    @IBAction func fontAndColorChanged(sender: AnyObject?) {
        if !hasUnsavedChange {
            revertButton.enabled = true
            applyButton.enabled = true
        }
        hasUnsavedChange = true
        textPreview.setAttributs(font, textColor:textColor.color, bkColor: bkColor.color, heightInrc:bgHeightIncreasement, enableShadow: shadowModeEnabled, shadowColor: shadowColor.color, shadowRadius: shadowRadius, yOffset:lyricsYOffset)
    }
    
    @IBAction func applyFontAndColorChanges(sender: AnyObject?) {
        if !checkTextFieldNumberValid() {
            self.window?.makeFirstResponder(nil)
            return
        }
        self.window?.makeFirstResponder(nil)
        hasUnsavedChange = false
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
        NSNotificationCenter.defaultCenter().postNotificationName(LyricsAttributesChangedNotification, object: nil)
    }
    
    @IBAction func revertFontAndColorChanges(sender: AnyObject?) {
        // If current value is invalid, set one before reverting
        if !checkTextFieldNumberValid() {
            let textView = self.window?.firstResponder as! NSTextView
            textView.string = "0"
        }
        self.window?.makeFirstResponder(nil)
        hasUnsavedChange = false
        revertButton.enabled = false
        applyButton.enabled = false
        reflashFontAndColorPrefs()
    }
    
    override func changeFont(sender: AnyObject?) {
        font = (sender?.convertFont(font))!
        fontDisplayText.stringValue = NSString(format: "%@, %.1f", font.displayName!,font.pointSize) as String
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
    
// MARK: - Delegate

    func windowShouldClose(sender: AnyObject) -> Bool {
        if !checkTextFieldNumberValid() {
            self.window?.makeFirstResponder(nil)
            return false
        }
        if (sender as! NSWindow).title == NSLocalizedString("FONT_COLOR", comment: "") {
            if hasUnsavedChange {
                displayAlert(nil)
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
    
// MARK: - Alert
    
    func displayAlert(identifier: String!) {
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
                    self.displayViewForIdentifier(identifier,animate: true)
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
    
// MARK: - Other 
    
    func checkTextFieldNumberValid() -> Bool {
        let currentResponder = self.window?.firstResponder
        if currentResponder != nil && currentResponder!.isKindOfClass(NSTextView) {
            let formatter: NSNumberFormatter = ((currentResponder as! NSTextView).superview?.superview as! NSTextField).formatter as! NSNumberFormatter
            let stringValue: String = (currentResponder as! NSTextView).string!
            if formatter.numberFromString(stringValue) == nil {
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
}
