//
//  CTGlyphData.swift
//  CoreTextTest
//
//  Created by Eru on 2017/7/23.
//  Copyright © 2017年 Eru. All rights reserved.
//

import Cocoa

enum GlyphType {
    /// 底朝左
    case Left
    
    /// 底朝下
    case Down
}

class CTGlyphData: NSObject {

    /// 字形
    var glyph: CGGlyph
    
    /// 位置
    var position: CGPoint
    
    /// 原始位置
    private(set) var originalPosition: CGPoint
    
    /// 视觉大小
    var opticalRect: CGRect
    
    /// 边界大小
    var boundingRect: CGRect
    
    /// 类型
    var verticalType: GlyphType
    
    /// 文字
    var character: UInt16
    
    init(glyph: CGGlyph, character: unichar, originalPosition: CGPoint) {
        
        self.glyph = glyph
        self.character = character
        self.originalPosition = originalPosition
        self.position = originalPosition
        self.opticalRect = CGRect()
        self.boundingRect = CGRect()
        if CharacterSet.ckjUnifiedIdeographs.characterIsMember(character) {
            verticalType = .Down
        } else {
            verticalType = .Left
        }
        
        super.init()
    }
    
}
