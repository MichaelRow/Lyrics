//
//  TextPreview.swift
//  Lyrics
//
//  Created by Eru on 15/11/18.
//  Copyright © 2015年 Eru. All rights reserved.
//

import Cocoa

class TextPreview: NSView {
    
    private var attributes: [String:AnyObject]
    private var backgroundColor: NSColor

    required init?(coder: NSCoder) {
        attributes = [String:AnyObject]()
        backgroundColor = NSColor.blackColor()
        super.init(coder: coder)
    }

    override func drawRect(dirtyRect: NSRect) {
        drawStringInCenter()
        
        NSColor.grayColor().set()
        NSBezierPath.setDefaultLineWidth(5)
        NSBezierPath.strokeRect(self.bounds)
    }
    
    func setAttributs(font:NSFont, textColor:NSColor, bkColor:NSColor, enableShadow:Bool, shadowColor:NSColor, shadowRadius:CGFloat) {
        backgroundColor = bkColor
        attributes.removeAll()
        attributes[NSForegroundColorAttributeName] = textColor
        attributes[NSFontAttributeName] = font
        if enableShadow {
            let shadow: NSShadow = NSShadow()
            shadow.shadowColor = shadowColor
            shadow.shadowBlurRadius = shadowRadius
            attributes[NSShadowAttributeName] = shadow
        }
        self.needsDisplay = true
    }
    
    func drawStringInCenter() {
        let str: NSString = "歌词效果预览"
        let strSize: NSSize = str.sizeWithAttributes(attributes)
        var strOrigin: NSPoint = NSPoint()
        
        strOrigin.x = self.bounds.origin.x + (self.bounds.size.width - strSize.width)/2
        strOrigin.y = self.bounds.origin.y + (self.bounds.size.height - strSize.height)/2
        
        // draw background layer
        let strRect: NSRect = NSMakeRect(strOrigin.x - 25, strOrigin.y, strSize.width + 50, strSize.height)
        let path:NSBezierPath = NSBezierPath(roundedRect: strRect, xRadius: 20, yRadius: 20)
        backgroundColor.set()
        path.fill()
        
        // draw string
        str.drawAtPoint(strOrigin, withAttributes: attributes)
    }
    
}
