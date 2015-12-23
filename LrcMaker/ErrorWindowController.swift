//
//  ErrorWindowController.swift
//  Lyrics
//
//  Created by Eru on 15/12/22.
//  Copyright © 2015年 Eru. All rights reserved.
//

import Cocoa

class ErrorWindowController: NSWindowController {
    
    static let sharedErrorWindow = ErrorWindowController()
    
    var errorText: CATextLayer!
    var attrs: [String:AnyObject]!
    var isOrderFront: Bool = false
    var timer: NSTimer!

    convenience init() {
        NSLog("Init MessageWindow")
        let win = NSWindow(contentRect: NSZeroRect, styleMask: NSBorderlessWindowMask, backing: NSBackingStoreType.Buffered, `defer`: false)
        self.init(window: win)
        self.window?.opaque = false
        self.window?.hasShadow = false
        self.window?.ignoresMouseEvents = true
        self.window?.level = Int(CGWindowLevelForKey(.FloatingWindowLevelKey))
        self.window?.backgroundColor = NSColor.clearColor()
        self.window?.contentView?.layer = CALayer()
        self.window?.contentView?.wantsLayer = true
        self.window?.contentView?.layer?.backgroundColor = NSColor(calibratedWhite: 0, alpha: 0.65).CGColor
        self.window?.contentView?.layer?.cornerRadius = 15
        
        errorText = CATextLayer()
        errorText.anchorPoint = NSZeroPoint
        errorText.position = NSZeroPoint
        errorText.alignmentMode = kCAAlignmentCenter
        errorText.font = NSFont(name: "HiraginoSansGB-W6", size: 20)
        errorText.fontSize = 20
        errorText.foregroundColor = NSColor.whiteColor().CGColor
        self.window?.contentView?.layer?.addSublayer(errorText)
        
        attrs = [NSFontAttributeName : NSFont(name: "HiraginoSansGB-W6", size: 20)!]
        self.window?.orderOut(nil)
    }
    
    func displayError(errorStr: String) {
        let attributedStr = NSAttributedString(string: errorStr, attributes: attrs)
        let size = attributedStr.size()
        let mainWin = NSApplication.sharedApplication().mainWindow
        let mainFrame: NSRect = (mainWin?.frame)!
        if isOrderFront {
            mainWin?.removeChildWindow(self.window!)
        }
        let x = mainFrame.origin.x + (mainFrame.size.width - size.width)/2
        let y = mainFrame.origin.y + (mainFrame.size.height - size.height)/2
        self.window!.setFrame(NSMakeRect(x, y, size.width + 30, size.height + 30), display: true)
        errorText.string = errorStr
        errorText.frame = NSMakeRect(0, 15, size.width + 30, size.height)
        mainWin?.addChildWindow(self.window!, ordered: .Above)
        if !isOrderFront {
            self.window!.alphaValue = 0
            self.window!.makeKeyAndOrderFront(nil)
            isOrderFront = true
            self.window!.animator().alphaValue = 1
        }
        if timer != nil {
            timer.invalidate()
            timer = nil
        }
        timer = NSTimer.scheduledTimerWithTimeInterval(2, target: self, selector: "fadeOut", userInfo: nil, repeats: false)
    }
    
    func fadeOut() {
        let delay: NSTimeInterval = NSAnimationContext.currentContext().duration + 0.1
        self.window!.performSelector("orderOut:", withObject: nil, afterDelay: delay)
        self.window!.animator().alphaValue = 0
        let mainWin = NSApplication.sharedApplication().mainWindow
        mainWin?.removeChildWindow(self.window!)
        errorText.string = ""
        isOrderFront = false
    }

}
