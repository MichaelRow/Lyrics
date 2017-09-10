//
//  LyricsPicker.swift
//  LyricsX
//
//  Created by Eru on 2017/8/27.
//  Copyright © 2017年 Eru. All rights reserved.
//

import Foundation

class LyricsPicker {
    
    /// 标记某些参数允许的Bool类型
    struct BoolSet: OptionSet {
        var rawValue: UInt
        static let valueTrue = BoolSet(rawValue: 1 << 0)
        static let valueFalse = BoolSet(rawValue: 1 << 1)
    }
    
    
    
}

private extension Bool {
    
    var boolSetValue: LyricsPicker.BoolSet {
        if self {
            return LyricsPicker.BoolSet.valueTrue
        } else {
            return LyricsPicker.BoolSet.valueFalse
        }
    }
}
