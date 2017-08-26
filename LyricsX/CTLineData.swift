//
//  CTLineData.swift
//  CoreTextTest
//
//  Created by Eru on 2017/7/20.
//  Copyright © 2017年 Eru. All rights reserved.
//

import Cocoa

class CTLineData {
    
    /// run中的最大ascent
    fileprivate(set) var maxRunAscent: CGFloat
    
    /// run中的最大descent
    fileprivate(set) var maxRunDescent: CGFloat
    
    /// line中包含的所有run
    fileprivate(set) var runDatas: [CTRunData]
    
    /// 原始的大小
    fileprivate(set) var originalBounds: CGRect
    
    /// Core Text 原始行对象
    fileprivate var line: CTLine?
    
    init() {
        originalBounds = CGRect()
        maxRunAscent = 0
        maxRunDescent = 0
        runDatas = []
        originalBounds = CGRect()
    }
    
    
    func config(with attrString: NSAttributedString) {
        
        let tempLine = CTLineCreateWithAttributedString(attrString)
        guard let ctRuns = CTLineGetGlyphRuns(tempLine) as? [CTRun] else { return }
        var tempRuns = [CTRunData]()
        var tempMaxAscent: CGFloat = 0
        var tempMaxDescent: CGFloat = 0

        let rawString = attrString.string
        
        for ctRun in ctRuns {
            let range = CTRunGetStringRange(ctRun)
            let start = rawString.index(rawString.startIndex, offsetBy: range.location)
            let end = rawString.index(start, offsetBy: range.length)
            let runString = rawString.substring(with: start ..< end)
            
            let run = CTRunData()
            run.config(with: ctRun, rawString: runString)
            tempMaxAscent = max(tempMaxAscent, run.ascent)
            tempMaxDescent = max(tempMaxDescent, run.descent)
            tempRuns.append(run)
        }

        originalBounds = CTLineGetBoundsWithOptions(tempLine, .useOpticalBounds)
        maxRunAscent = tempMaxAscent
        maxRunDescent = tempMaxDescent
        line = tempLine
        runDatas = tempRuns
    }
    
}

