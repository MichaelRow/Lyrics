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
    
    var timer:Timer!
    var launchType:Int!
    var shouldWaitForiTunesQuit:Bool = false
    let iTunes: iTunesBridge = iTunesBridge()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        let lyrics = NSRunningApplication.runningApplications(withBundleIdentifier: "Eru.Lyrics")
        if lyrics.count > 0 {
            NSApp.terminate(nil)
        }

        let lyricsXDefaults: UserDefaults = UserDefaults.init(suiteName: "Eru.Lyrics")!
        let returnedObj = lyricsXDefaults.object(forKey: "LyricsLaunchTpyePopUpIndex");
        
        if returnedObj == nil {
            // nil when key not found (register defaults)
            launchType = 2
        } else {
            launchType = (returnedObj as! NSNumber).intValue
        }
        switch launchType {
        case 0:
            //launches at login
            launchLyricsXAndQuit()
        case 1:
            //launches with iTunes
            if iTunes.running() {
                shouldWaitForiTunesQuit = true
                DistributedNotificationCenter.default().addObserver(self, selector: #selector(handleiTunesEvent(_:)), name: NSNotification.Name(rawValue: "com.apple.iTunes.playerInfo"), object: nil)
            } else {
                waitForiTunesLaunch()
            }
        case 2:
            //launches when iTunes playing
            if iTunes.running() {
                shouldWaitForiTunesQuit = true
            }
            DistributedNotificationCenter.default().addObserver(self, selector: #selector(handleiTunesEvent(_:)), name: NSNotification.Name(rawValue: "com.apple.iTunes.playerInfo"), object: nil)
        default:
            break
        }
    }
    

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
        DistributedNotificationCenter.default().removeObserver(self)
    }
    
    
    func launchLyricsXAndQuit() {
        var pathComponents: NSArray = (Bundle.main.bundlePath as NSString).pathComponents as NSArray
        pathComponents = pathComponents.subarray(with: NSMakeRange(0, pathComponents.count-4)) as NSArray
        let path = NSString.path(withComponents: pathComponents as! [String])
        NSWorkspace.shared().launchApplication(path)
        NSApp.terminate(nil)
    }
    
    
    func handleiTunesEvent (_ n: Notification) {
        if !shouldWaitForiTunesQuit && launchType == 2 && n.userInfo!["Player State"] as! String == "Playing" {
            launchLyricsXAndQuit();
        } else if shouldWaitForiTunesQuit {
            let playerState = n.userInfo!["Player State"] as! String
            if playerState == "Paused" || playerState == "Stopped" {
                if timer != nil {
                    timer.invalidate()
                    timer = nil
                }
                timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(AppDelegate.checkiTunesQuit), userInfo: nil, repeats: false)
            }
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
            Thread.sleep(forTimeInterval: 1.5)
        }
        launchLyricsXAndQuit()
    }
}

