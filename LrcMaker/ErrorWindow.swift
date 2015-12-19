//
//  ErrorWindow.swift
//  LrcMaker
//
//  Created by Eru on 15/12/6.
//  Copyright © 2015年 Eru. All rights reserved.
//

import Cocoa

class ErrorWindow: NSWindow {
    
    var errorText: CATextLayer!
    var attrs: [String:AnyObject]!
    var isOrderFront: Bool = false
    var timer: NSTimer!
    
    init () {
        super.init(contentRect: NSZeroRect, styleMask: NSBorderlessWindowMask, backing: .Buffered, `defer`: false)
        doInitialSetup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        doInitialSetup()
    }
    
    private func doInitialSetup() {
        self.opaque = false
        self.hasShadow = false
        self.ignoresMouseEvents = true
        self.level = Int(CGWindowLevelForKey(.FloatingWindowLevelKey))
        self.backgroundColor = NSColor.clearColor()
        
        self.contentView?.layer = CALayer()
        self.contentView?.wantsLayer = true
        self.contentView?.layer?.backgroundColor = NSColor(calibratedWhite: 0, alpha: 0.65).CGColor
        self.contentView?.layer?.cornerRadius = 15
        
        errorText = CATextLayer()
        errorText.anchorPoint = NSZeroPoint
        errorText.position = NSZeroPoint
        errorText.alignmentMode = kCAAlignmentCenter
        errorText.font = NSFont(name: "HiraginoSansGB-W6", size: 20)
        errorText.fontSize = 20
        errorText.foregroundColor = NSColor.whiteColor().CGColor
        self.contentView?.layer?.addSublayer(errorText)
        
        attrs = [NSFontAttributeName : NSFont(name: "HiraginoSansGB-W6", size: 20)!]
    
        self.orderOut(nil)
    }
    
    func fadeInAndOutWithErrorString(errorStr: String) {
        let attributedStr = NSAttributedString(string: errorStr, attributes: attrs)
        let size = attributedStr.size()
        let mainWin = NSApplication.sharedApplication().mainWindow
        let mainFrame: NSRect = (mainWin?.frame)!
        if isOrderFront {
            mainWin?.removeChildWindow(self)
        }
        let x = mainFrame.origin.x + (mainFrame.size.width - size.width)/2
        let y = mainFrame.origin.y + (mainFrame.size.height - size.height)/2
        self.setFrame(NSMakeRect(x, y, size.width + 30, size.height + 30), display: true)
        errorText.string = errorStr
        errorText.frame = NSMakeRect(0, 15, size.width + 30, size.height)
        mainWin?.addChildWindow(self, ordered: .Above)
        if !isOrderFront {
            self.alphaValue = 0
            self.makeKeyAndOrderFront(nil)
            isOrderFront = true
            self.animator().alphaValue = 1
        }
        if timer != nil {
            timer.invalidate()
            timer = nil
        }
        timer = NSTimer.scheduledTimerWithTimeInterval(2, target: self, selector: "fadeOut", userInfo: nil, repeats: false)
    }
    
    func fadeOut() {
        let delay: NSTimeInterval = NSAnimationContext.currentContext().duration + 0.1
        self.performSelector("orderOut:", withObject: nil, afterDelay: delay)
        self.animator().alphaValue = 0
        let mainWin = NSApplication.sharedApplication().mainWindow
        mainWin?.removeChildWindow(self)
        errorText.string = ""
        isOrderFront = false
    }
}
