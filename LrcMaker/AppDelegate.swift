//
//  AppDelegate.swift
//  LrcMaker
//
//  Created by Eru on 15/12/4.
//  Copyright © 2015年 Eru. All rights reserved.
//

import Cocoa
import AVFoundation
import QuartzCore

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSXMLParserDelegate {
    
    var mainWindow: MainWindowController!
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Insert code here to initialize your application
        
        mainWindow = MainWindowController()
    }
    
    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(sender: NSApplication) -> Bool {
        return true
    }
    
}

