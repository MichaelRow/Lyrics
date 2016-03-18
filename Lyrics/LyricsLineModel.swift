//
//  LyricsLineModel.swift
//  Lyrics
//
//  Created by Eru on 15/11/12.
//  Copyright © 2015年 Eru. All rights reserved.
//

import Cocoa

class LyricsLineModel: NSObject {
    
    var lyricsSentence: String!
    
    private(set) var msecPosition: Int!
    
    private(set) var timeTag: String!
    
    func setMsecPositionWithTimeTag (theTimeTag: NSString) {
        self.timeTag = theTimeTag as String
        let colonRange: NSRange = theTimeTag.rangeOfString(":")
        let minuteStr: NSString = theTimeTag.substringWithRange(NSMakeRange(1, colonRange.location-1))
        let secondStr: NSString = theTimeTag.substringWithRange(NSMakeRange(colonRange.location+1, theTimeTag.length-colonRange.length-colonRange.location-1))
        let minute: Int = minuteStr.integerValue
        let second: Float = secondStr.floatValue
        self.msecPosition = Int((Float(minute)*60+second)*1000)
    }
    
    func setTimeTagWithMsecPosition (theMsecPosition: Int) {
        let minute: Int = theMsecPosition/(60*1000)
        let second: Int = (theMsecPosition-minute*60*1000)/1000
        let mSecond: Int = theMsecPosition-(minute*60+second)*1000
        var theTimeTag: String = String()
        
        if minute < 10 {
            theTimeTag.appendContentsOf("[0\(minute):")
        } else {
            theTimeTag.appendContentsOf("[\(minute):")
        }
        
        if second < 10 {
            theTimeTag.appendContentsOf("0\(second).")
        } else {
            theTimeTag.appendContentsOf("\(second).")
        }
        
        if mSecond > 99 {
            theTimeTag.appendContentsOf("\(mSecond)]")
        } else if mSecond > 9 {
            theTimeTag.appendContentsOf("0\(mSecond)]")
        } else {
            theTimeTag.appendContentsOf("00\(mSecond)]")
        }
        self.timeTag = theTimeTag
    }
}
