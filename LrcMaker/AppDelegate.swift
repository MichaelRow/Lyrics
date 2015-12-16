//
//  AppDelegate.swift
//  LrcMaker
//
//  Created by Eru on 15/12/4.
//  Copyright © 2015年 Eru. All rights reserved.
//

import Cocoa
import AVFoundation

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSXMLParserDelegate {
    
    var mainWindow: MainWindowController!
    var whetherTerminate: Bool = false
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        
        let userDefaults: [String:AnyObject] = [
            "LMHighLightedColor1" : NSKeyedArchiver.archivedDataWithRootObject(NSColor.blueColor()),
            "LMHighLightedColor2" : NSKeyedArchiver.archivedDataWithRootObject(NSColor(red: 2/255, green: 163/255, blue: 1, alpha: 1)),
            "LMPlayWhenAdded" : NSNumber(bool: true)
        ]
        NSUserDefaults.standardUserDefaults().registerDefaults(userDefaults)
        mainWindow = MainWindowController()
    }
    
    @IBAction func showPreferences(sender: AnyObject) {
        PreferencesController.sharedPreferences.showWindow(nil)
    }
    
    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(sender: NSApplication) -> Bool {
        return true
    }
    
    func applicationShouldTerminate(sender: NSApplication) -> NSApplicationTerminateReply {
        if !whetherTerminate && mainWindow.currentView == 2 {
            if mainWindow.lrcLineArray.count > 0 && !mainWindow.isSaved {
                mainWindow.window?.orderFront(nil)
                NSApp.activateIgnoringOtherApps(true)
                let alert: NSAlert = NSAlert()
                alert.messageText = NSLocalizedString("NOT_SAVE", comment: "")
                alert.informativeText = NSLocalizedString("CHECK_QUITE", comment: "")
                alert.addButtonWithTitle(NSLocalizedString("CANCEL", comment: ""))
                alert.addButtonWithTitle(NSLocalizedString("QUIT", comment: ""))
                alert.beginSheetModalForWindow(mainWindow.window!, completionHandler: { (response) -> Void in
                    if response == NSAlertSecondButtonReturn {
                        self.whetherTerminate = true
                        NSApplication.sharedApplication().terminate(self)
                    }
                })
                return .TerminateCancel
            } else {
                return .TerminateNow
            }
        }
        return .TerminateNow
    }
    
}

