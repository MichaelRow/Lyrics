//
//  LyricsLineModel.swift
//  Lyrics
//
//  Created by Eru on 15/11/12.
//  Copyright © 2015年 Eru. All rights reserved.
//

import Cocoa

class LyricsLineModel: NSObject {
    
    var lyricsSentence:NSString!
    
    var msecPosition:Int! {
        set {
            let minute:Int = newValue/(60*1000)
            let second:Int = (newValue-minute*60*1000)/1000
            let mSecond:Int = newValue-(minute*60+second)*1000
            var theTimeTag:String = String()
            
            if minute < 10 {
                theTimeTag += "[0\(minute):"
            } else {
                theTimeTag += "[\(minute):"
            }
            
            if second < 10 {
                theTimeTag += "0\(second)."
            } else {
                theTimeTag += "\(second)."
            }
            
            if mSecond > 99 {
                theTimeTag += "\(mSecond)]"
            } else if mSecond > 9 {
                theTimeTag += "0\(second)]"
            } else {
                theTimeTag += "00\(second)]"
            }
            self.timeTag = theTimeTag
        }
        get {
            return self.msecPosition
        }
    }
    
    var timeTag:NSString! {
        set {
            let colonRange:NSRange = newValue.rangeOfString(":")
            let minuteStr:NSString = newValue.substringWithRange(NSMakeRange(1, colonRange.location-1))
            let secondStr:NSString = newValue.substringWithRange(NSMakeRange(colonRange.location+1, newValue.length-colonRange.length-colonRange.location-1))
            let minute:Int = minuteStr.integerValue
            let second:Float = secondStr.floatValue
            self.msecPosition = Int((Float(minute)*60+second)*1000)
        }
        get {
            return self.timeTag
        }
    }
}
