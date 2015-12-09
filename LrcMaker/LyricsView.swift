//
//  LyricsView.swift
//  LrcMaker
//
//  Created by Eru on 15/12/5.
//  Copyright © 2015年 Eru. All rights reserved.
//

import Cocoa

class LyricsView: NSView {
    
    var lyricsLayers: [CATextLayer]!
    var lyricsArray: [String]!
    var height: CGFloat!
    var attrs: [String:AnyObject]!
    var highlightedCerulean: [String:AnyObject]!
    var highlightedBlue: [String:AnyObject]!
    var currentHighLightedIndex: Int!
    var maxWidth: CGFloat!
    
    //MARK: - Init & Override
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        didWhenInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        didWhenInit()
    }
    
    func didWhenInit() {
        self.layer = CALayer()
        self.wantsLayer = true
        self.layer?.speed = 3
        
        attrs = [NSFontAttributeName : NSFont(name: "HiraginoSansGB-W3", size: 18)!]
        attrs[NSForegroundColorAttributeName] = NSColor.blackColor()
        
        highlightedCerulean = [NSFontAttributeName : NSFont(name: "HiraginoSansGB-W6", size: 21.5)!]
        highlightedCerulean[NSForegroundColorAttributeName] = NSColor(red: 2/255, green: 163/255, blue: 1, alpha: 1)
        
        highlightedBlue = [NSFontAttributeName : NSFont(name: "HiraginoSansGB-W6", size: 21.5)!]
        highlightedBlue[NSForegroundColorAttributeName] = NSColor.blueColor()
        
        lyricsLayers = [CATextLayer]()
        height = (self.frame.height - 10) / 7
    }
    
    override var flipped:Bool {
        get {
            return true
        }
    }
    
    override var acceptsFirstResponder: Bool {
        return true
    }
    
    override func becomeFirstResponder() -> Bool {
        return true
    }
    
    // Lyrics Methods
    
    func setLyricsLayerWithArray(array: [String]) {
        lyricsArray = array
        for anLayer in lyricsLayers {
            anLayer.removeFromSuperlayer()
        }
        lyricsLayers.removeAll()
        maxWidth = 0
        
        for var i = 0; i < lyricsArray.count; ++i {
            let lyrics: String = lyricsArray[i]
            let layer: CATextLayer = CATextLayer()
            self.layer?.addSublayer(layer)
            layer.anchorPoint = NSZeroPoint
            
            let attributedStr: NSAttributedString = NSAttributedString(string: lyrics, attributes: attrs)
            layer.string = attributedStr
            let w = attributedStr.size().width
            if w > maxWidth {
                maxWidth = w
            }
            layer.frame = NSMakeRect(5, 10 + CGFloat(i) * height, w, height)
            lyricsLayers.append(layer)
            
        }
        self.setFrameSize(NSMakeSize(5 + maxWidth, 10 + CGFloat(lyricsArray.count) * height))
        currentHighLightedIndex = -1
    }
    
    func setHighlightedAtIndex(index: Int, andStyle style: Int) {
        unsetHighlighted()
        currentHighLightedIndex = index
        let attributes: [String:AnyObject]
        if style == 1 {
            attributes = highlightedBlue
        } else {
            attributes = highlightedCerulean
        }
        let attributedStr = NSAttributedString(string: lyricsArray[index], attributes: attributes)
        let w = attributedStr.size().width
        lyricsLayers[index].speed = 3
        if w > lyricsLayers[index].frame.width {
            lyricsLayers[index].frame = NSMakeRect(5, 10 + CGFloat(index) * height, w, height)
        }
        if w > maxWidth {
            maxWidth = w
            self.setFrameSize(NSMakeSize(5 + maxWidth, 10 + self.frame.height))
        }
        lyricsLayers[index].string = attributedStr
    }
    
    func unsetHighlighted() {
        if currentHighLightedIndex != -1 {
            let attributedStr = NSAttributedString(string: lyricsArray[currentHighLightedIndex], attributes: attrs)
            lyricsLayers[currentHighLightedIndex].speed = 1000
            lyricsLayers[currentHighLightedIndex].string = attributedStr
            currentHighLightedIndex = -1
        }
    }
    
}
