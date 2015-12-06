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
    var shouldWaitForiTunesQuit:Bool = false
    let iTunes: iTunesBridge = iTunesBridge()

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        
        let lyrics = NSRunningApplication.runningApplicationsWithBundleIdentifier("Eru.Lyrics")
        if lyrics.count > 0 {
            NSApp.terminate(nil)
        }

        let lyricsXDefaults: NSUserDefaults = NSUserDefaults.init(suiteName: "Eru.Lyrics")!
        let returnedObj = lyricsXDefaults.objectForKey("LyricsLaunchTpyePopUpIndex");
        
        if returnedObj == nil {
            // nil when key not found (register defaults)
            launchType = 2
        } else {
            launchType = (returnedObj?.integerValue)!
        }
        
        switch launchType {
        case 0:
            //launches at login
            launchLyricsX()
            NSApp.terminate(nil)
        case 1:
            //launches with iTunes
            if iTunes.running() {
                shouldWaitForiTunesQuit = true
                NSDistributedNotificationCenter.defaultCenter().addObserver(self, selector: "handleiTunesEvent:", name: "com.apple.iTunes.playerInfo", object: nil)
            } else {
                waitForiTunesLaunch()
            }
        case 2:
            //launches when iTunes playing
            if iTunes.running() {
                shouldWaitForiTunesQuit = true
            }
            NSDistributedNotificationCenter.defaultCenter().addObserver(self, selector: "handleiTunesEvent:", name: "com.apple.iTunes.playerInfo", object: nil)
        default:
            break
        }
    }
    

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
        NSDistributedNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    
    func launchLyricsX() {
        var pathComponents: NSArray = (NSBundle.mainBundle().bundlePath as NSString).pathComponents
        pathComponents = pathComponents.subarrayWithRange(NSMakeRange(0, pathComponents.count-4))
        let path = NSString.pathWithComponents(pathComponents as! [String])
        NSWorkspace.sharedWorkspace().launchApplication(path)
    }
    
    
    func handleiTunesEvent (n: NSNotification) {
        if !shouldWaitForiTunesQuit && launchType == 2 && n.userInfo!["Player State"] as! String == "Playing" {
            launchLyricsX();
            NSApp.terminate(nil)
        } else if shouldWaitForiTunesQuit && n.userInfo!["Player State"] as! String == "Paused" {
            if timer != nil {
                timer.invalidate()
                timer = nil
            }
            timer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: "checkiTunesQuit", userInfo: nil, repeats: false)
        }
    }
    
 
    func checkiTunesQuit () {
        if timer != nil {
            timer.invalidate()
            timer = nil
        }
        if !iTunes.running() {
            shouldWaitForiTunesQuit = false
            if launchType == 1 {
                waitForiTunesLaunch()
            }
        }
    }
    
    func waitForiTunesLaunch() {
        while !iTunes.running() {
            NSThread.sleepForTimeInterval(1.5)
        }
        launchLyricsX()
        NSApp.terminate(nil)
    }
}

