//
//  Layout.swift
//  CoreTextTest
//
//  Created by Eru on 2017/7/23.
//  Copyright © 2017年 Eru. All rights reserved.
//

import Cocoa

class Layout: NSObject {
    
    fileprivate var attributedString: NSAttributedString
    
    fileprivate var displayMode: LyricsDisplayView.DisplayMode
    
    fileprivate var drawingBounds: CGRect
    
    fileprivate(set) var line: CTLineData
    
    fileprivate(set) var lineFrame: CGRect
    
    fileprivate(set) var glyphFrames: [CGRect]
    
    override init() {
        displayMode = .Horizontal
        attributedString = NSAttributedString()
        drawingBounds = CGRect()
        line = CTLineData()
        lineFrame = CGRect()
        glyphFrames = []
        
        super.init()
    }
    
    func config(with attrString: NSAttributedString, displayMode mode: LyricsDisplayView.DisplayMode, drawingBounds bounds: CGRect) {
        // 生成CoreText对象
        let isTextChanged = !attributedString.isEqual(to: attrString)
        if isTextChanged {
            attributedString = attrString
            line.config(with: attrString)
        }
        
        // 计算文字位置
        if isTextChanged || displayMode != mode || drawingBounds != bounds {
            displayMode = mode
            drawingBounds = bounds
            
            if displayMode == .Horizontal {
                calculateForHorizontal()
            } else {
                calculateForVertical()
            }
        }
    }
    
    /// 横向布局直接使用默认方式
    fileprivate func calculateForHorizontal() {
        
        let xOffset = max((drawingBounds.width - line.originalBounds.width) / 2, 0)
        let yOffset = max((drawingBounds.height - line.maxRunAscent - line.maxRunDescent) / 2 + line.maxRunDescent, 0)
        
        // 获取行大小
        lineFrame = line.originalBounds
        lineFrame.origin.x += xOffset
        lineFrame.origin.y += yOffset
        
        var tempGlyghFrame = [CGRect]()
        for runData in line.runDatas {
            
            for glyphData in runData.glyphDatas {
                
                glyphData.position.x = glyphData.originalPosition.x + xOffset
                glyphData.position.y = glyphData.originalPosition.y + yOffset
                
                // 获取字形大小
                let frame = CGRect(x: glyphData.position.x, y: lineFrame.minY, width: glyphData.opticalRect.width, height: lineFrame.height)
                tempGlyghFrame.append(frame)
            }
        }
        glyphFrames = tempGlyghFrame
    }
    
    /// 纵向布局每个字形单独计算
    fileprivate func calculateForVertical() {
        
        let startX = CGFloat()
        let startY = drawingBounds.size.height
        var lineWidth = CGFloat()
        var lineHeight = CGFloat()
        var xLeftOffset = CGFloat()
        var xRightOffset = CGFloat()
        let currentX = startX
        var currentY = startY
        
        var tempGlyphFrames = [CGRect]()
        
        for runIndex in 0 ..< line.runDatas.count {
            
            let run = line.runDatas[runIndex]
            
            for glyphIndex in 0 ..< run.glyphDatas.count {
                
                let glyph = run.glyphDatas[glyphIndex]
                
                let boundingDescent = -glyph.boundingRect.origin.y
                let boundingAscent = glyph.boundingRect.height - boundingDescent
                
                if glyph.verticalType == .Down {
                    
                    let bearing = glyph.opticalRect.width / 11
                    
                    let glyphX = currentX - glyph.opticalRect.width / 7
                    let glyphY = currentY - bearing - boundingAscent
                    
                    glyph.position = CGPoint(x: glyphX, y: glyphY)
                    let glyphFrame = CGRect(x: glyphX + glyph.boundingRect.minX, y: glyphY - boundingDescent, width: glyph.boundingRect.width, height: glyph.boundingRect.height + bearing)
                    tempGlyphFrames.append(glyphFrame)
                    
                    let glyphXLeftOffset = glyph.opticalRect.width / 5 - glyph.boundingRect.minX
                    let glyphXRightOffset = glyph.boundingRect.width - glyphXLeftOffset
                    
                    xLeftOffset = max(xLeftOffset, glyphXLeftOffset)
                    xRightOffset = max(xRightOffset, glyphXRightOffset)
                    lineHeight += (bearing + glyph.boundingRect.height)
                    currentY -= (bearing + glyph.boundingRect.height)
                    
                } else {
                    
                    let bearing: CGFloat
                    if glyphIndex == 0 {
                        if runIndex <= 0 {
                            bearing = run.fontSize / 11
                        } else {
                            if let lastGlyph = line.runDatas[runIndex-1].glyphDatas.last {
                                bearing = glyph.originalPosition.x - lastGlyph.originalPosition.x - lastGlyph.boundingRect.width
                            } else {
                                bearing = run.fontSize / 11
                            }
                        }
                    } else {
                        bearing = glyph.originalPosition.x - run.glyphDatas[glyphIndex-1].originalPosition.x - run.glyphDatas[glyphIndex-1].boundingRect.width
                    }
                    
                    let xBearing = (glyph.opticalRect.width - glyph.boundingRect.width) / 2
                    
                    // 正常坐标系下
                    let glyphX = currentX
                    let glyphY = currentY - bearing - glyph.boundingRect.width
                    
                    // 旋转-π/2后向上平移bounds.width后的坐标
                    let newGlyphX = drawingBounds.width - (currentY - bearing + xBearing)
                    let newGlyphY = glyphX
                    
                    glyph.position = CGPoint(x: newGlyphX, y: newGlyphY)
                    let glyphFrame = CGRect(x: glyphX + glyph.boundingRect.minY, y: glyphY, width: glyph.boundingRect.height, height: glyph.boundingRect.width + bearing)
                    tempGlyphFrames.append(glyphFrame)
                    
                    lineHeight += (bearing + glyph.boundingRect.width)
                    xLeftOffset = max(xLeftOffset, fabs(glyph.boundingRect.minY) + xBearing)
                    xRightOffset = max(xRightOffset, glyph.boundingRect.height - fabs(glyph.boundingRect.minY) + xBearing)
                    currentY -= (bearing + glyph.boundingRect.width)
                }
            }
        }
        
        //加宽
        lineWidth = (xLeftOffset + xRightOffset) * 1.15
        
        let xOffset = max((drawingBounds.width - lineWidth) / 2, 0)
        let yOffset = max((drawingBounds.height - lineHeight) / 2, 0)
        
        lineFrame = CGRect(x: xOffset, y: yOffset, width: lineWidth, height: lineHeight)
        
        for run in line.runDatas {
            
            for glyphIndex in 0 ..< run.glyphDatas.count {
                
                let glyph = run.glyphDatas[glyphIndex]
                if glyph.verticalType == .Down {
                    glyph.position.x += (xOffset + xLeftOffset)
                    glyph.position.y -= yOffset
                } else {
                    glyph.position.x += yOffset
                    glyph.position.y += (xOffset + xLeftOffset)
                }
            }
        }
        
        for index in 0 ..< tempGlyphFrames.count {
            tempGlyphFrames[index].origin.x = lineFrame.minX
            tempGlyphFrames[index].size.width = lineFrame.width
            tempGlyphFrames[index].origin.y -= yOffset
        }
        
        glyphFrames = tempGlyphFrames
    }
}
