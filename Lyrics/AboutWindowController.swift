//
//  AboutWindowController.swift
//  Lyrics
//
//  Created by Eru on 1/9/16.
//  Copyright © 2016 Eru. All rights reserved.
//

import Cocoa

class AboutWindowController: NSWindowController {
    
    static let sharedController = AboutWindowController()
    
    @IBOutlet weak var appName: NSTextField!
    @IBOutlet weak var appVersion: NSTextField!
    @IBOutlet weak var scrollView: NSScrollView!
    @IBOutlet var textView: NSTextView!
    @IBOutlet var donateView: NSView!
    @IBOutlet weak var infoButton: NSButton!
    
    var textViewState: Int = 0
    var windowState: Bool = false
    var appCopyright: NSAttributedString!
    var appCredits: NSAttributedString!
    var appEULA: NSAttributedString!
    
    convenience init() {
        self.init(windowNibName:"AboutWindow")
        appCopyright = NSAttributedString()
        appCredits = NSAttributedString()
        appEULA = NSAttributedString()
    }
    
    convenience required init?(coder: NSCoder) {
        self.init(windowNibName:"AboutWindow")
        appCopyright = NSAttributedString()
        appCredits = NSAttributedString()
        appEULA = NSAttributedString()
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
        self.window?.backgroundColor = NSColor.whiteColor()
        appName.stringValue = valueFromInfoDict("CFBundleName")
        let version = valueFromInfoDict("CFBundleVersion")
        let shortVersion = valueFromInfoDict("CFBundleShortVersionString")
        if version == "" {
            appVersion.stringValue = "Version \(shortVersion)"
        }
        else {
            appVersion.stringValue = "Version \(shortVersion) (Build \(version))"
        }
        let font:NSFont? = NSFont(name: "HelveticaNeue", size: 11.0)
        let color:NSColor? = NSColor.grayColor()
        let attribs:[String:AnyObject] = [NSForegroundColorAttributeName:color!,
            NSFontAttributeName:font!]
        appCopyright = NSAttributedString(string: valueFromInfoDict("NSHumanReadableCopyright"), attributes:attribs)
        if let creditsRTF = NSBundle.mainBundle().pathForResource("Credits", ofType: "rtf") {
            appCredits = NSAttributedString(path: creditsRTF, documentAttributes: nil)!
        }
        if let eulaRTF = NSBundle.mainBundle().pathForResource("EULA", ofType: "rtf") {
            appEULA = NSAttributedString(path: eulaRTF, documentAttributes: nil)!
        }
        textView.textStorage?.setAttributedString(self.appCopyright)
        scrollView.documentView = textView
    }
    
    override func showWindow(sender: AnyObject?) {
        super.showWindow(sender)
        self.window?.makeKeyAndOrderFront(nil)
        NSApp.activateIgnoringOtherApps(true)
    }
    
    @IBAction func switchTextView(sender: AnyObject) {
        if scrollView.documentView!.isEqual(donateView) {
            scrollView.documentView = textView
        }
        textViewState += 1
        if textViewState == 3 {
            textViewState = 0
            
        }
        switch textViewState {
        case 0:
            textView.textStorage?.setAttributedString(self.appCopyright)
            infoButton.title = "Credits"
        case 1:
            textView.textStorage?.setAttributedString(self.appCredits)
            infoButton.title = NSLocalizedString("EULA", comment: "")
        case 2:
            textView.textStorage?.setAttributedString(self.appEULA)
            infoButton.title = "Copyright"
        default:
            break
        }
        if textViewState == 0 && windowState {
            var oldFrame:NSRect = self.window!.frame
            oldFrame.size.height -= 100
            oldFrame.origin.y += 100
            self.window!.setFrame(oldFrame,display:true, animate:true)
            windowState = false
        }
        else if textViewState != 0 && !windowState {
            var oldFrame:NSRect = self.window!.frame
            oldFrame.size.height += 100
            oldFrame.origin.y -= 100
            self.window!.setFrame(oldFrame,display:true, animate:true)
            windowState = true
        }
    }
    
    @IBAction func showDonate(sender: AnyObject?) {
        if scrollView.documentView!.isEqual(textView) {
            scrollView.documentView = donateView
            let newScrollOrigin: NSPoint = NSMakePoint(0, NSMaxY(scrollView.documentView!.frame)-NSHeight(scrollView.contentView.bounds))
            scrollView.documentView?.scrollPoint(newScrollOrigin)
        }
        if !windowState {
            var oldFrame:NSRect = self.window!.frame
            oldFrame.size.height += 100
            oldFrame.origin.y -= 100
            self.window!.setFrame(oldFrame,display:true, animate:true)
            windowState = true
        }
    }
    
    //Private & Delegate
    private func valueFromInfoDict(string:String) -> String {
        let dictionary = NSBundle.mainBundle().infoDictionary!
        let result = dictionary[string]
        if result == nil {
            return ""
        }
        else {
            return result as! String
        }
    }
    
    func windowShouldClose(sender: AnyObject) -> Bool {
        //reset scrollview's content
        if windowState {
            var oldFrame:NSRect = self.window!.frame
            oldFrame.size.height -= 100
            oldFrame.origin.y += 100
            self.window!.setFrame(oldFrame,display:false, animate:false)
            windowState = false
        }
        textView.textStorage?.setAttributedString(self.appCopyright)
        scrollView.documentView = textView
        textViewState = 0
        infoButton.title = "Credits"
        return true
    }
}
