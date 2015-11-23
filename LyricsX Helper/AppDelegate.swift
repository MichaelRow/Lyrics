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

    @IBOutlet weak var window: NSWindow!


    func applicationDidFinishLaunching(aNotification: NSNotification) {

        let lyricsXDefaults: NSUserDefaults = NSUserDefaults.init(suiteName: "Eru.Lyrics")!
        switch lyricsXDefaults.integerForKey("LyricsLaunchTpyePopUpIndex") {
        case 0:
            //launches at login
            launchLyricsX()
        case 1:
            //launches with iTunes
            launchLyricsXWheniTunesLaunched()
        case 2:
            //launches when iTunes is playing
            NSDistributedNotificationCenter.defaultCenter().addObserver(self, selector: "launchLyricsXWheniTunesPlaying:", name: "com.apple.iTunes.playerInfo", object: nil)
        default:
            break
        }
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }
    
    func launchLyricsX() {
        var pathComponents: NSArray = (NSBundle.mainBundle().bundlePath as NSString).pathComponents
        pathComponents = pathComponents.subarrayWithRange(NSMakeRange(0, pathComponents.count-4))
        let path = NSString.pathWithComponents(pathComponents as! [String])
        NSWorkspace.sharedWorkspace().launchApplication(path)
        NSApp.terminate(nil)
    }
    
    func launchLyricsXWheniTunesLaunched () {
        let iTunes:SBApplication = SBApplication(bundleIdentifier: "com.apple.iTunes")!
        
        while true {
            autoreleasepool({ () -> () in
                if iTunes.running {
                    launchLyricsX();
                }
            })
            NSThread.sleepForTimeInterval(2)
        }
    }
    
    func launchLyricsXWheniTunesPlaying (n: NSNotification) {
        if n.userInfo!["Player State"] as! String == "Playing" {
            launchLyricsX();
        }
    }
    
}

