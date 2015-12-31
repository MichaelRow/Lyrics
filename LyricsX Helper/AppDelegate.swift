//
//  AppDelegate.swift
//  LyricsX Helper
//
//  Created by Eru on 15/11/23.
//  Copyright © 2015年 Eru. All rights reserved.
//

import Cocoa
import ScriptingBridge

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    var timer:NSTimer!
    var launchType:Int!
    let vox: VoxBridge = VoxBridge()

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        
        let lyricsVox = NSRunningApplication.runningApplicationsWithBundleIdentifier("Eru.LyricsVox")
        if lyricsVox.count > 0 {
            NSApp.terminate(nil)
        }

        let lyricsVoxDefaults: NSUserDefaults = NSUserDefaults.init(suiteName: "Eru.LyricsVox")!
        let returnedObj = lyricsVoxDefaults.objectForKey("LyricsLaunchTpyePopUpIndex");
        
        if returnedObj == nil {
            // nil when key not found (register defaults)
            launchType = 2
        } else {
            launchType = (returnedObj?.integerValue)!
        }
        
        switch launchType {
        case 0:
            //launches at login
            launchLyricsVox()
            NSApp.terminate(nil)
        case 1:
            //launches with iTunes
            if vox.running() {
                waitForVoxQuit()
            }
            waitForVoxLaunch()
            launchLyricsVox()
        case 2:
            //launches when iTunes playing
            if vox.running() {
                waitForVoxQuit()
            }
            waitForVoxLaunch()
            NSDistributedNotificationCenter.defaultCenter().addObserver(self, selector: "launchLyricsVox", name: "com.coppertino.Vox.trackChanged", object: nil)
        default:
            break
        }
    }
    

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
        NSDistributedNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func launchLyricsVox() {
        var pathComponents: NSArray = (NSBundle.mainBundle().bundlePath as NSString).pathComponents
        pathComponents = pathComponents.subarrayWithRange(NSMakeRange(0, pathComponents.count-4))
        let path = NSString.pathWithComponents(pathComponents as! [String])
        NSWorkspace.sharedWorkspace().launchApplication(path)
    }
    
    func waitForVoxLaunch() {
        while !vox.running() {
            NSThread.sleepForTimeInterval(2)
        }
    }
    
    func waitForVoxQuit() {
        while vox.running() {
            NSThread.sleepForTimeInterval(2)
        }
    }

}

