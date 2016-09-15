//
//  LyricsLineModel.swift
//  Lyrics
//
//  Created by Eru on 15/11/12.
//  Copyright © 2015年 Eru. All rights reserved.
//

import Cocoa

class LyricsLineModel: NSObject {
    
    var lyricsSentence: String
    var enabled: Bool
    
    fileprivate(set) var msecPosition: Int
    fileprivate(set) var timeTag: String
    
    override init() {
        lyricsSentence = String()
        enabled = true
        msecPosition = 0
        timeTag = "[00:00.000]"
        super.init()
    }
    
    func setMsecPositionWithTimeTag (_ theTimeTag: NSString) {
        self.timeTag = theTimeTag as String
        let colonRange: NSRange = theTimeTag.range(of: ":")
        let minuteStr: NSString = theTimeTag.substring(with: NSMakeRange(1, colonRange.location-1)) as NSString
        let secondStr: NSString = theTimeTag.substring(with: NSMakeRange(colonRange.location+1, theTimeTag.length-colonRange.length-colonRange.location-1)) as NSString
        let minute: Int = minuteStr.integerValue
        let second: Float = secondStr.floatValue
        self.msecPosition = Int((Float(minute)*60+second)*1000)
    }
    
    func setTimeTagWithMsecPosition (_ theMsecPosition: Int) {
        let minute: Int = theMsecPosition/(60*1000)
        let second: Int = (theMsecPosition-minute*60*1000)/1000
        let mSecond: Int = theMsecPosition-(minute*60+second)*1000
        var theTimeTag: String = String()
        
        if minute < 10 {
            theTimeTag.append("[0\(minute):")
        } else {
            theTimeTag.append("[\(minute):")
        }
        
        if second < 10 {
            theTimeTag.append("0\(second).")
        } else {
            theTimeTag.append("\(second).")
        }
        
        if mSecond > 99 {
            theTimeTag.append("\(mSecond)]")
        } else if mSecond > 9 {
            theTimeTag.append("0\(mSecond)]")
        } else {
            theTimeTag.append("00\(mSecond)]")
        }
        self.timeTag = theTimeTag
    }
}
