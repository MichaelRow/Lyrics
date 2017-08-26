//
//  CTRunData.swift
//  CoreTextTest
//
//  Created by Eru on 2017/7/19.
//  Copyright © 2017年 Eru. All rights reserved.
//

import Cocoa

class CTRunData {
    
    fileprivate var run: CTRun?
    
    fileprivate(set) var ascent: CGFloat
    
    fileprivate(set) var descent: CGFloat
    
    fileprivate(set) var font: NSFont
    
    fileprivate(set) var fontSize: CGFloat
    
    fileprivate(set) var color: NSColor
    
    fileprivate(set) var glyphs: [CGGlyph]
    
    fileprivate(set) var glyphDatas: [CTGlyphData]
    
    fileprivate(set) var rawString: String
    
    init() {
        glyphs = []
        glyphDatas = [CTGlyphData]()
        font = NSFont.systemFont(ofSize: 14)
        fontSize = 14
        ascent = CTFontGetAscent(font)
        descent = CTFontGetDescent(font)
        color = NSColor.black
        rawString = String()
    }
    
    func config(with run: CTRun, rawString: String) {
        
        let glyphCount = CTRunGetGlyphCount(run) as Int
        var cgGlyphs = [CGGlyph](repeating: CGGlyph(), count: glyphCount)
        var advances = [CGSize](repeating: CGSize(), count: glyphCount)
        var positions = [CGPoint](repeating: CGPoint(), count: glyphCount)
        var opticalRect = [CGRect](repeating: CGRect(), count:glyphCount)
        var boundingRect = [CGRect](repeating: CGRect(), count:glyphCount)
        
        CTRunGetGlyphs(run, CFRange(location: 0, length: 0), &cgGlyphs)
        CTRunGetPositions(run, CFRange(location: 0,length: 0), &positions)
        CTRunGetAdvances(run, CFRange(location: 0,length: 0), &advances)
        
        if let runAttributes = CTRunGetAttributes(run) as? [String : Any] {
            if let runFont = runAttributes[NSAttributedStringKey.font.rawValue] as? NSFont {
                font = runFont
                ascent = CTFontGetAscent(font)
                descent = CTFontGetDescent(font)
                fontSize = font.pointSize
            }
            if let runColor = runAttributes[NSAttributedStringKey.foregroundColor.rawValue] as? NSColor {
                color = runColor
            }
        }
        CTFontGetOpticalBoundsForGlyphs(font, &cgGlyphs, &opticalRect, glyphCount, 0)
        CTFontGetBoundingRectsForGlyphs(font, .horizontal, &cgGlyphs, &boundingRect, glyphCount)
        
        var tempGlyphs = [CTGlyphData]()
        for glyphIndex in 0 ..< glyphCount {
            
            let utf16 = rawString.utf16
            let charStart = utf16.index(utf16.startIndex, offsetBy: glyphIndex)
            let character = utf16[charStart]
            
            let glyphData = CTGlyphData(glyph: cgGlyphs[glyphIndex], character: character, originalPosition: positions[glyphIndex])
            glyphData.boundingRect = boundingRect[glyphIndex]
            glyphData.opticalRect = opticalRect[glyphIndex]
            
            tempGlyphs.append(glyphData)
        }
        self.run = run
        self.rawString = rawString
        self.glyphs = cgGlyphs
        self.glyphDatas = tempGlyphs
    }
}
