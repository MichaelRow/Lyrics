//
//  LrcFilter.swift
//  Lyrics
//
//  Created by Eru on 16/3/26.
//  Copyright © 2016年 Eru. All rights reserved.
//

import Cocoa

class LrcFilter: NSObject {
    
    let colon = [":","：","∶"]
    
    func filter(lyricsLine: String) -> Bool {
        let convertedLyrics = lyricsLine.stringByReplacingOccurrencesOfString(" ", withString: "").lowercaseString
        let userDefaults = NSUserDefaults.standardUserDefaults()
        for str in userDefaults.arrayForKey(LyricsDirectFilter)! {
            if convertedLyrics.rangeOfString((str as! String).lowercaseString) != nil {
                return false
            }
        }
        for str in userDefaults.arrayForKey(LyricsConditionalFilter)! {
            if convertedLyrics.rangeOfString((str as! String).lowercaseString) != nil {
                for aColon in colon {
                    if convertedLyrics.rangeOfString(aColon) != nil {
                        return false
                    }
                }
            }
        }
        return true
    }
    
}
