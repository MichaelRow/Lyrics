//
//  Controller.swift
//  Lyrics
//
//  Created by Eru on 15/11/11.
//  Copyright © 2015年 Eru. All rights reserved.
//

import Cocoa

class AppPrefsWindowController: DBPrefsWindowController,NSWindowDelegate {
    
    @IBOutlet var generalPrefsView:NSView!
    @IBOutlet var lyricsPrefsView:NSView!
    @IBOutlet var donateView:NSView!
    
    @IBOutlet weak var textPreview: TextPreview!
    @IBOutlet weak var savingPathPopUp: NSPopUpButton!
    @IBOutlet weak var fontDisplayText: NSTextField!
    @IBOutlet weak var shadowModeCheckbox: NSButton!
    @IBOutlet weak var textColor: NSColorWell!
    @IBOutlet weak var bkColor: NSColorWell!
    @IBOutlet weak var shadowColor: NSColorWell!
    @IBOutlet weak var shadowRadius: NSTextField!
    @IBOutlet weak var revertButton: NSButton!
    @IBOutlet weak var applyButton: NSButton!
    
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
        let defaultSavingPath: String = NSSearchPathForDirectoriesInDomains(.MusicDirectory, [.UserDomainMask], true).first! + "/LyricsX"
        let userSavingPath: NSString = NSUserDefaults.standardUserDefaults().stringForKey(LyricsUserSavingPath)!
        savingPathPopUp.itemAtIndex(0)?.toolTip = defaultSavingPath
        savingPathPopUp.itemAtIndex(1)?.toolTip = userSavingPath as String
        savingPathPopUp.itemAtIndex(1)?.title = userSavingPath.lastPathComponent
        
        let userDefaults = NSUserDefaults.standardUserDefaults()
        font = NSFont(name: userDefaults.stringForKey(LyricsFontName)!, size: CGFloat(userDefaults.floatForKey(LyricsFontSize)))!
        fontDisplayText.stringValue = NSString(format: "%@, %.1f", font.displayName!,font.pointSize) as String
        textPreview.setAttributs(font, textColor:textColor.color, bkColor: bkColor.color, enableShadow: Bool(shadowModeCheckbox.state), shadowColor: shadowColor.color, shadowRadius: CGFloat(shadowRadius.floatValue))
        
        textColor.addObserver(self, forKeyPath: "color", options: [], context: &prefsChangeContext)
        bkColor.addObserver(self, forKeyPath: "color", options: [], context: &prefsChangeContext)
        shadowColor.addObserver(self, forKeyPath: "color", options: [], context: &prefsChangeContext)
        shadowModeCheckbox.addObserver(self, forKeyPath: "cell.state", options: [], context: &prefsChangeContext)
    }
    
    override func displayViewForIdentifier(identifier: String, animate: Bool) {
        if hasUnsaveChange && self.window?.title == "Lyrics" {
            displayAlert(false, identifier: identifier)
            return
        }
        
        NSUserDefaultsController.sharedUserDefaultsController().appliesImmediately = true
        
        super.displayViewForIdentifier(identifier, animate: animate)
        
        if self.window?.title == "Lyrics" {
            NSUserDefaultsController.sharedUserDefaultsController().appliesImmediately = false
            let userDefaults = NSUserDefaults.standardUserDefaults()
            font = NSFont(name: userDefaults.stringForKey(LyricsFontName)!, size: CGFloat(userDefaults.floatForKey(LyricsFontSize)))!
        }
    }
    
    override func setupToolbar () {
        self.addView(generalPrefsView, label: "General", image: NSImage(named: "general_icon"))
        self.addView(lyricsPrefsView, label: "Lyrics", image: NSImage(named: "lyrics_icon"))
        self.addView(donateView, label: "Donate", image: NSImage(named: "donate_icon"))
        self.crossFade=true
        self.shiftSlowsAnimation=true
    }
    
// MARK: - Interface Methods
    
    @IBAction func changeSavingPath(sender: AnyObject) {
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
    
    @IBAction func applyChanges(sender: AnyObject) {
        NSUserDefaultsController.sharedUserDefaultsController().save(nil)
        hasUnsaveChange = false
        revertButton.enabled = false
        applyButton.enabled = false
        let userDefaults: NSUserDefaults = NSUserDefaults.standardUserDefaults()
        userDefaults.setObject(font.fontName, forKey: LyricsFontName)
        userDefaults.setObject(NSNumber(float: Float(font.pointSize)), forKey: LyricsFontSize)
        NSNotificationCenter.defaultCenter().postNotificationName(LyricsAttributesChangedNotification, object: nil)
    }
    
    @IBAction func restoreChanges(sender: AnyObject) {
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
    
// MARK: - Font Methods
    
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
        return Int(NSFontPanelAllModesMask)
    }
    
    @IBAction func showFontPanel(sender: AnyObject) {
        let fontManger: NSFontManager = NSFontManager.sharedFontManager()
        let fontPanel: NSFontPanel = NSFontPanel.sharedFontPanel()
        fontManger.target = self
        fontManger.setSelectedFont(font, isMultiple: false)
        fontPanel.makeKeyAndOrderFront(self)
        fontPanel.delegate = self
    }

    func windowShouldClose(sender: AnyObject) -> Bool {
        if (sender as! NSWindow).title == "Lyrics" {
            if hasUnsaveChange {
                displayAlert(true, identifier: nil)
                return false
            } else {
                return true
            }
        }
        return true
    }
    
// MARK: - KVO and TextField Delegate
    
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
    
// MARK: - Alert
    
    func displayAlert(closeWindow: Bool, identifier: String!) {
        let alert: NSAlert = NSAlert()
        alert.messageText = "Changes unsaved"
        alert.informativeText = "Do you really want to revert all the changes and leave?"
        alert.addButtonWithTitle("Apply and Leave")
        alert.addButtonWithTitle("Revert and Leave")
        alert.addButtonWithTitle("Cancel")
        alert.beginSheetModalForWindow(self.window!, completionHandler: { (response) -> Void in
            if response != NSAlertThirdButtonReturn {
                if response == NSAlertFirstButtonReturn {
                    NSUserDefaultsController.sharedUserDefaultsController().save(nil)
                } else {
                    NSUserDefaultsController.sharedUserDefaultsController().revert(nil)
                }
                self.hasUnsaveChange = false
                self.revertButton.enabled = false
                self.applyButton.enabled = false
                if identifier != nil {
                    self.displayViewForIdentifier(identifier,animate: true)
                    NSUserDefaultsController.sharedUserDefaultsController().appliesImmediately = true
                }
                if closeWindow {
                    self.window?.orderOut(nil)
                }
            } else {
                self.window?.toolbar?.selectedItemIdentifier = "Lyrics"
            }
        })
    }
}
