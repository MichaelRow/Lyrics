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
    @IBOutlet private var donateView:NSView!
    
    @IBOutlet private weak var textPreview: TextPreview!
    @IBOutlet private weak var savingPathPopUp: NSPopUpButton!
    @IBOutlet private weak var fontDisplayText: NSTextField!
    @IBOutlet private weak var shadowModeCheckbox: NSButton!
    @IBOutlet private weak var textColor: NSColorWell!
    @IBOutlet private weak var bkColor: NSColorWell!
    @IBOutlet private weak var shadowColor: NSColorWell!
    @IBOutlet private weak var shadowRadius: NSTextField!
    @IBOutlet private weak var revertButton: NSButton!
    @IBOutlet private weak var applyButton: NSButton!
    
    private var hasUnsaveChange: Bool = false
    private var flag: Bool = true
    private var prefsChangeContext = 0
    private var font: NSFont!
    
//MARK: - Override superclass methods
    
    deinit {
        textColor.removeObserver(self, forKeyPath: "color", context: &prefsChangeContext)
        bkColor.removeObserver(self, forKeyPath: "color", context: &prefsChangeContext)
        shadowColor.removeObserver(self, forKeyPath: "color", context: &prefsChangeContext)
        shadowModeCheckbox.removeObserver(self, forKeyPath: "cell.state", context: &prefsChangeContext)
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
        self.window?.delegate = self
        hasUnsaveChange = false
        
        //Pop up button and font is hard to bind to NSUserDefaultsController, do it selves
        let defaultSavingPath: String = NSSearchPathForDirectoriesInDomains(.MusicDirectory, [.UserDomainMask], true).first! + "/LyricsX"
        let userSavingPath: NSString = NSUserDefaults.standardUserDefaults().stringForKey(LyricsUserSavingPath)!
        savingPathPopUp.itemAtIndex(0)?.toolTip = defaultSavingPath
        savingPathPopUp.itemAtIndex(1)?.toolTip = userSavingPath as String
        savingPathPopUp.itemAtIndex(1)?.title = userSavingPath.lastPathComponent
        
        let userDefaults = NSUserDefaults.standardUserDefaults()
        font = NSFont(name: userDefaults.stringForKey(LyricsFontName)!, size: CGFloat(userDefaults.floatForKey(LyricsFontSize)))!
        fontDisplayText.stringValue = NSString(format: "%@, %.1f", font.displayName!,font.pointSize) as String
        textPreview.setAttributs(font, textColor:textColor.color, bkColor: bkColor.color, enableShadow: Bool(shadowModeCheckbox.state), shadowColor: shadowColor.color, shadowRadius: CGFloat(shadowRadius.floatValue))
        
        //observe the font and color changes for preview
        textColor.addObserver(self, forKeyPath: "color", options: [], context: &prefsChangeContext)
        bkColor.addObserver(self, forKeyPath: "color", options: [], context: &prefsChangeContext)
        shadowColor.addObserver(self, forKeyPath: "color", options: [], context: &prefsChangeContext)
        shadowModeCheckbox.addObserver(self, forKeyPath: "cell.state", options: [], context: &prefsChangeContext)
    }
    
    override func displayViewForIdentifier(identifier: String, animate: Bool) {
        
        //check if changes are unsaved
        if hasUnsaveChange && self.window?.title == NSLocalizedString("FONT_COLOR", comment: "") {
            displayAlert(identifier)
            return
        }
        
        super.displayViewForIdentifier(identifier, animate: animate)
        
        if self.window?.title == NSLocalizedString("FONT_COLOR", comment: "") {
            NSUserDefaultsController.sharedUserDefaultsController().appliesImmediately = false
            let userDefaults = NSUserDefaults.standardUserDefaults()
            font = NSFont(name: userDefaults.stringForKey(LyricsFontName)!, size: CGFloat(userDefaults.floatForKey(LyricsFontSize)))!
        } else {
            //applies Immediately in other prefs view
            NSUserDefaultsController.sharedUserDefaultsController().appliesImmediately = true
        }
    }
    
    override func setupToolbar () {
        self.addView(generalPrefsView, label: NSLocalizedString("GENERAL", comment: ""), image: NSImage(named: "general_icon"))
        self.addView(lyricsPrefsView, label: NSLocalizedString("LYRICS", comment: ""), image: NSImage(named: "lyrics_icon"))
        self.addView(fontAndColorPrefsView, label: NSLocalizedString("FONT_COLOR", comment: ""), image: NSImage(named: "font_Color_icon"))
        self.addFlexibleSpacer()
        self.addView(donateView, label: NSLocalizedString("DONATE", comment: ""), image: NSImage(named: "donate_icon"))
        self.crossFade=true
        self.shiftSlowsAnimation=true
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
    
    @IBAction func applyFontAndColorChanges(sender: AnyObject?) {
        NSUserDefaultsController.sharedUserDefaultsController().save(nil)
        hasUnsaveChange = false
        revertButton.enabled = false
        applyButton.enabled = false
        let userDefaults: NSUserDefaults = NSUserDefaults.standardUserDefaults()
        userDefaults.setObject(font.fontName, forKey: LyricsFontName)
        userDefaults.setObject(NSNumber(float: Float(font.pointSize)), forKey: LyricsFontSize)
        NSNotificationCenter.defaultCenter().postNotificationName(LyricsAttributesChangedNotification, object: nil)
    }
    
    @IBAction func revertFontAndColorChanges(sender: AnyObject?) {
        flag = false
        NSUserDefaultsController.sharedUserDefaultsController().revert(nil)
        hasUnsaveChange = false
        revertButton.enabled = false
        applyButton.enabled = false
        let userDefaults: NSUserDefaults = NSUserDefaults.standardUserDefaults()
        font = NSFont(name: userDefaults.stringForKey(LyricsFontName)!, size: CGFloat(userDefaults.floatForKey(LyricsFontSize)))
        fontDisplayText.stringValue = NSString(format: "%@, %.1f", font.displayName!,font.pointSize) as String
        textPreview.setAttributs(font, textColor:textColor.color, bkColor: bkColor.color, enableShadow: Bool(shadowModeCheckbox.state), shadowColor: shadowColor.color, shadowRadius: CGFloat(shadowRadius.floatValue))
    }
    
    override func changeFont(sender: AnyObject?) {
        font = (sender?.convertFont(font))!
        fontDisplayText.stringValue = NSString(format: "%@, %.1f", font.displayName!,font.pointSize) as String
        if !hasUnsaveChange {
            revertButton.enabled = true
            applyButton.enabled = true
        }
        hasUnsaveChange = true
        textPreview.setAttributs(font, textColor:textColor.color, bkColor: bkColor.color, enableShadow: Bool(shadowModeCheckbox.state), shadowColor: shadowColor.color, shadowRadius: CGFloat(shadowRadius.floatValue))
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
    
// MARK: - KVO and Delegate
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if context == &prefsChangeContext {
            if flag {
                if !hasUnsaveChange {
                    revertButton.enabled = true
                    applyButton.enabled = true
                }
                hasUnsaveChange = true
            } else {
                flag = true
            }
            textPreview.setAttributs(font, textColor:textColor.color, bkColor: bkColor.color, enableShadow: Bool(shadowModeCheckbox.state), shadowColor: shadowColor.color, shadowRadius: CGFloat(shadowRadius.floatValue))
        }
    }
    
    override func controlTextDidChange(obj: NSNotification) {
        if !hasUnsaveChange {
            revertButton.enabled = true
            applyButton.enabled = true
        }
        hasUnsaveChange = true
        textPreview.setAttributs(font, textColor:textColor.color, bkColor: bkColor.color, enableShadow: Bool(shadowModeCheckbox.state), shadowColor: shadowColor.color, shadowRadius: CGFloat(shadowRadius.floatValue))
    }
    
    func windowShouldClose(sender: AnyObject) -> Bool {
        if (sender as! NSWindow).title == NSLocalizedString("FONT_COLOR", comment: "") {
            if hasUnsaveChange {
                displayAlert(nil)
                return false
            } else {
                return true
            }
        }
        return true
    }
    
// MARK: - Alert
    
    // identifier nil means window is about to close
    func displayAlert(identifier: String!) {
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
                    self.displayViewForIdentifier(identifier,animate: true)
                    NSUserDefaultsController.sharedUserDefaultsController().appliesImmediately = true
                } else {
                    self.window?.orderOut(nil)
                }
                
            } else {
                self.window?.toolbar?.selectedItemIdentifier = NSLocalizedString("FONT_COLOR", comment: "")
            }
        })
    }
}
