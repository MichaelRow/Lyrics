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
        let userDefaults = NSUserDefaults.standardUserDefaults()
        for str in userDefaults.arrayForKey(LyricsDirectFilter)! {
            if lyricsLine.rangeOfString(str as! String) != nil {
                return false
            }
        }
        for str in userDefaults.arrayForKey(LyricsConditionalFilter)! {
            if lyricsLine.rangeOfString(str as! String) != nil {
                for aColon in colon {
                    if lyricsLine.rangeOfString(aColon) != nil {
                        return false
                    }
                }
            }
        }
        return true
    }
    
}
