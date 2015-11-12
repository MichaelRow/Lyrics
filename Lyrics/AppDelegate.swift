//
//  AppDelegate.swift
//  Lyrics
//
//  Created by Eru on 15/11/6.
//  Copyright © 2015年 Eru. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    var applicationController: AppController!
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        
        applicationController = AppController()
        
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }

}

