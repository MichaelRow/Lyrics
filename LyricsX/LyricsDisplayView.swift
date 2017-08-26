//
//  LyricsDisplayView.swift
//  LyricsX
//
//  Created by Eru on 2017/7/16.
//  Copyright © 2017年 Eru. All rights reserved.
//

import Cocoa
import CoreText

class LyricsDisplayView: NSView {
    
    enum DisplayMode {
        case Horizontal
        case Vertical
    }
    
    /// 当前文本的大小
    fileprivate var textSize: CGSize
    
    fileprivate var textLayout: Layout
    
    override var intrinsicContentSize: CGSize {
        return textSize
    }
    
    /// 当前显示的文本
    var attributedText: NSAttributedString {
        didSet {
            adjustContent(bounds)
        }
    }
    
    /// 当前的显示模式
    var displayMode: DisplayMode = .Horizontal {
        didSet {
            adjustContent(bounds)
        }
    }
    
    var hollow: Bool = false {
        didSet {
            setNeedsDisplay(bounds)
        }
    }
    
    var debug: Bool = false {
        didSet {
            setNeedsDisplay(bounds)
        }
    }
    
    override var frame: NSRect {
        willSet {
            adjustContent(newValue)
        }
    }
    
    override func layout() {
        super.layout()
        adjustContent(bounds)
    }
    
    override init(frame frameRect: NSRect) {
        textSize = CGSize()
        attributedText = NSAttributedString()
        textLayout = Layout()
        super.init(frame: frameRect)
    }
    
    required init?(coder: NSCoder) {
        textSize = CGSize()
        attributedText = NSAttributedString()
        textLayout = Layout()
        super.init(coder: coder)
    }
    
    fileprivate func adjustContent(_ rect: CGRect) {
        textLayout.config(with: attributedText, displayMode: displayMode, drawingBounds: rect)
        let contentSize = textLayout.lineFrame.size
        if textSize != contentSize {
            textSize = contentSize
            invalidateIntrinsicContentSize()
        }
    }
    
}

//MARK: Public Methods

extension LyricsDisplayView {
    
    func getTextFrame(at index: Int) -> CGRect {
        guard textLayout.glyphFrames.count > index else { return textLayout.lineFrame }
        return textLayout.glyphFrames[index]
    }
    
}

//MARK: Drawing

extension LyricsDisplayView {
    
    override func draw(_ dirtyRect: NSRect) {
        
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        
        if displayMode == .Horizontal {
            drawHorizontal(in: context)
        } else {
            drawVertical(in: context)
        }
    }
    
    // 横向绘制
    fileprivate func drawHorizontal(in context: CGContext) {
        
        for runData in textLayout.line.runDatas {
            context.saveGState()
            let cgFont = CTFontCopyGraphicsFont(runData.font, nil)
            context.textMatrix = CGAffineTransform.identity
            context.setFont(cgFont)
            context.setFontSize(runData.fontSize)
            context.setStrokeColor(runData.color.cgColor)
            context.setFillColor(runData.color.cgColor)

            for glyphIndex in 0 ..< runData.glyphDatas.count {
                let glyphData = runData.glyphDatas[glyphIndex]
                //空心实心
                if hollow {
                    drawHollow(in: context, glyphData: glyphData, font: runData.font)

                } else {
                    context.showGlyphs([glyphData.glyph], at: [glyphData.position])
                }
            }
            context.restoreGState()
        }
        
        // 调试模式绘制边框
        if debug {
            drawBorder(in: context)
        }
    }
    
    // 纵向绘制
    fileprivate func drawVertical(in context: CGContext) {
        
        for runData in textLayout.line.runDatas {
            
            context.saveGState()
            let cgFont = CTFontCopyGraphicsFont(runData.font, nil)
            context.setFont(cgFont)
            context.setFontSize(runData.fontSize)
            context.setFillColor(runData.color.cgColor)
            context.setStrokeColor(runData.color.cgColor)
            
            for glyphIndex in 0 ..< runData.glyphDatas.count {
                
                let glyphData = runData.glyphDatas[glyphIndex]
                context.textMatrix = CGAffineTransform.identity
                
                //是否翻转
                if glyphData.verticalType == .Down {
                    
                    if hollow {
                        drawHollow(in: context, glyphData: glyphData, font: runData.font)
                    } else {
                        context.showGlyphs([glyphData.glyph], at: [glyphData.position])
                    }
                } else {
                    context.saveGState()
                    context.rotate(by: CGFloat(-0.5*Double.pi))
                    context.translateBy(x: -bounds.width, y: 0)
                    
                    if hollow {
                        drawHollow(in: context, glyphData: glyphData, font: runData.font)
                    } else {
                        context.showGlyphs([glyphData.glyph], at: [glyphData.position])
                    }
                    context.restoreGState()
                }
            }
            context.restoreGState()
        }
        
        // 调试模式绘制边框
        if debug {
            drawBorder(in: context)
        }
    }
    
    // 绘制边框
    fileprivate func drawBorder(in context: CGContext) {
        context.saveGState()
        //字形边框
        context.setStrokeColor(NSColor.blue.cgColor)
        for glyphFrame in textLayout.glyphFrames {
            context.stroke(glyphFrame)
        }
        //行边框
        context.setStrokeColor(NSColor.red.cgColor)
        context.stroke(textLayout.lineFrame)
        context.restoreGState()
    }
    
    // 空心字形
    fileprivate func drawHollow(in context: CGContext, glyphData: CTGlyphData, font: NSFont) {
        var trans = CGAffineTransform(translationX: glyphData.position.x, y: glyphData.position.y)
        guard let path = CTFontCreatePathForGlyph(font, glyphData.glyph, &trans) else { return }
        
        context.saveGState()
        context.beginPath()
        context.addPath(path)
        context.closePath()
        context.strokePath()
        context.restoreGState()
    }
}
