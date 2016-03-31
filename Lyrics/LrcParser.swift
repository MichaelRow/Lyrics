//
//  LrcParser.swift
//  Lyrics
//
//  Created by Eru on 16/3/25.
//  Copyright © 2016年 Eru. All rights reserved.
//

import Cocoa

class LrcParser: NSObject {
    
    var lyrics: [LyricsLineModel]!
    var idTags: [String]!
    var timeDly: Int = 0
    private var regexForTimeTag: NSRegularExpression!
    private var regexForIDTag: NSRegularExpression!
    
    override init() {
        super.init()
        lyrics = [LyricsLineModel]()
        idTags = [String]()
        do {
            regexForTimeTag = try NSRegularExpression(pattern: "\\[\\d+:\\d+.\\d+\\]|\\[\\d+:\\d+\\]", options: [])
        } catch let theError as NSError {
            NSLog("%@", theError.localizedDescription)
            return
        }
        //the regex below should only use when the string doesn't contain time-tags
        //because all time-tags would be matched as well.
        do {
            regexForIDTag = try NSRegularExpression(pattern: "\\[[^\\]]+:[^\\]]+\\]", options: [])
        } catch let theError as NSError {
            NSLog("%@", theError.localizedDescription)
            return
        }
    }
    
    func testLrc(lrcContents: String) -> Bool {
        // test whether the string is lrc
        let newLineCharSet: NSCharacterSet = NSCharacterSet.newlineCharacterSet()
        let lrcParagraphs: [String] = lrcContents.componentsSeparatedByCharactersInSet(newLineCharSet)
        var numberOfMatched: Int = 0
        for str in lrcParagraphs {
            numberOfMatched = regexForTimeTag.numberOfMatchesInString(str, options: [], range: NSMakeRange(0, str.characters.count))
            if numberOfMatched > 0 {
                return true
            }
        }
        return false
    }
    
    func regularParse(lrcContents: String) {
        NSLog("Start to Parse lrc")
        cleanCache()
        
        var tempLyrics = [LyricsLineModel]()
        var tempIDTags = [String]()
        var tempTimeDly: Int = 0
        let newLineCharSet: NSCharacterSet = NSCharacterSet.newlineCharacterSet()
        let lrcParagraphs: [String] = lrcContents.componentsSeparatedByCharactersInSet(newLineCharSet)
        
        for str in lrcParagraphs {
            let timeTagsMatched: [NSTextCheckingResult] = regexForTimeTag.matchesInString(str, options: [], range: NSMakeRange(0, str.characters.count))
            if timeTagsMatched.count > 0 {
                let index: Int = timeTagsMatched.last!.range.location + timeTagsMatched.last!.range.length
                let lyricsSentence: String = str.substringFromIndex(str.startIndex.advancedBy(index))
                for result in timeTagsMatched {
                    let matchedRange: NSRange = result.range
                    let lrcLine: LyricsLineModel = LyricsLineModel()
                    lrcLine.lyricsSentence = lyricsSentence
                    lrcLine.setMsecPositionWithTimeTag((str as NSString).substringWithRange(matchedRange))
                    let currentCount: Int = tempLyrics.count
                    var j: Int = 0
                    while j < currentCount {
                        if lrcLine.msecPosition < tempLyrics[j].msecPosition {
                            tempLyrics.insert(lrcLine, atIndex: j)
                            break
                        }
                        j += 1
                    }
                    if j == currentCount {
                        tempLyrics.append(lrcLine)
                    }
                }
            }
            else {
                let idTagsMatched: [NSTextCheckingResult] = regexForIDTag.matchesInString(str, options: [], range: NSMakeRange(0, str.characters.count))
                if idTagsMatched.count == 0 {
                    continue
                }
                for result in idTagsMatched {
                    let matchedRange: NSRange = result.range
                    let idTag: NSString = (str as NSString).substringWithRange(matchedRange) as NSString
                    let colonRange: NSRange = idTag.rangeOfString(":")
                    let idStr: String = idTag.substringWithRange(NSMakeRange(1, colonRange.location-1))
                    if idStr.stringByReplacingOccurrencesOfString(" ", withString: "") != "offset" {
                        tempIDTags.append(idTag as String)
                        continue
                    }
                    else {
                        let idContent: String = idTag.substringWithRange(NSMakeRange(colonRange.location+1, idTag.length-colonRange.length-colonRange.location-1))
                        tempTimeDly = (idContent as NSString).integerValue
                    }
                }
            }
        }
        lyrics = tempLyrics
        idTags = tempIDTags
        timeDly = tempTimeDly
    }
    
    func parseForLyrics(lrcContents: String) {
        cleanCache()
        var tempLyrics = [LyricsLineModel]()
        let newLineCharSet: NSCharacterSet = NSCharacterSet.newlineCharacterSet()
        let lrcParagraphs: [String] = lrcContents.componentsSeparatedByCharactersInSet(newLineCharSet)
        
        for str in lrcParagraphs {
            let timeTagsMatched: [NSTextCheckingResult] = regexForTimeTag.matchesInString(str, options: [], range: NSMakeRange(0, str.characters.count))
            if timeTagsMatched.count > 0 {
                let index: Int = timeTagsMatched.last!.range.location + timeTagsMatched.last!.range.length
                let lyricsSentence: String = str.substringFromIndex(str.startIndex.advancedBy(index))
                for result in timeTagsMatched {
                    let matchedRange: NSRange = result.range
                    let lrcLine: LyricsLineModel = LyricsLineModel()
                    lrcLine.lyricsSentence = lyricsSentence
                    lrcLine.setMsecPositionWithTimeTag((str as NSString).substringWithRange(matchedRange))
                    let currentCount: Int = tempLyrics.count
                    var j: Int = 0
                    while j < currentCount {
                        if lrcLine.msecPosition < tempLyrics[j].msecPosition {
                            tempLyrics.insert(lrcLine, atIndex: j)
                            break
                        }
                        j += 1
                    }
                    if j == currentCount {
                        tempLyrics.append(lrcLine)
                    }
                }
            }
        }
        lyrics = tempLyrics
    }
    
    func parseWithFilter(lrcContents: String) {
        NSLog("Start to Parse lrc")
        cleanCache()
        
        var tempLyrics = [LyricsLineModel]()
        var tempIDTags = [String]()
        var tempTimeDly: Int = 0
        var title = String()
        var album = String()
        var otherIDInfos = [String]()
        let colons = [":","：","∶"]
        
        let newLineCharSet: NSCharacterSet = NSCharacterSet.newlineCharacterSet()
        let lrcParagraphs: [String] = lrcContents.componentsSeparatedByCharactersInSet(newLineCharSet)
        
        for str in lrcParagraphs {
            let timeTagsMatched: [NSTextCheckingResult] = regexForTimeTag.matchesInString(str, options: [], range: NSMakeRange(0, str.characters.count))
            if timeTagsMatched.count > 0 {
                let index: Int = timeTagsMatched.last!.range.location + timeTagsMatched.last!.range.length
                let lyricsSentence: String = str.substringFromIndex(str.startIndex.advancedBy(index))
                for result in timeTagsMatched {
                    let matchedRange: NSRange = result.range
                    let lrcLine: LyricsLineModel = LyricsLineModel()
                    lrcLine.lyricsSentence = lyricsSentence
                    lrcLine.setMsecPositionWithTimeTag((str as NSString).substringWithRange(matchedRange))
                    let currentCount: Int = tempLyrics.count
                    var j: Int = 0
                    while j < currentCount {
                        if lrcLine.msecPosition < tempLyrics[j].msecPosition {
                            tempLyrics.insert(lrcLine, atIndex: j)
                            break
                        }
                        j += 1
                    }
                    if j == currentCount {
                        tempLyrics.append(lrcLine)
                    }
                }
            }
            else {
                let idTagsMatched: [NSTextCheckingResult] = regexForIDTag.matchesInString(str, options: [], range: NSMakeRange(0, str.characters.count))
                if idTagsMatched.count == 0 {
                    continue
                }
                for result in idTagsMatched {
                    let matchedRange: NSRange = result.range
                    let idTag: NSString = (str as NSString).substringWithRange(matchedRange) as NSString
                    let colonRange: NSRange = idTag.rangeOfString(":")
                    let idStr: String = idTag.substringWithRange(NSMakeRange(1, colonRange.location-1)).stringByReplacingOccurrencesOfString(" ", withString: "").lowercaseString
                    let idContent: String = idTag.substringWithRange(NSMakeRange(colonRange.location+1, idTag.length-colonRange.length-colonRange.location-1)).stringByReplacingOccurrencesOfString(" ", withString: "").lowercaseString
                    switch idStr {
                    case "offset":
                        tempTimeDly = (idContent as NSString).integerValue
                    case "ti":
                        tempIDTags.append(idTag as String)
                        title = idContent
                    case "al":
                        tempIDTags.append(idTag as String)
                        album = idContent
                    default:
                        tempIDTags.append(idTag as String)
                        otherIDInfos.append(idContent)
                    }
                }
            }
        }
        //Filter
        let userDefaults = NSUserDefaults.standardUserDefaults()
        let directFilter = userDefaults.arrayForKey(LyricsDirectFilter) as! [String]
        let conditionalFilter = userDefaults.arrayForKey(LyricsConditionalFilter) as! [String]
        MainLoop: for index in 0 ..< tempLyrics.count {
            let line = tempLyrics[index].lyricsSentence.stringByReplacingOccurrencesOfString(" ", withString: "").lowercaseString
            if userDefaults.boolForKey(LyricsEnableSmartFilter) {
                let hasTitle: Bool = line.rangeOfString(title) != nil
                let hasAlbum: Bool = line.rangeOfString(album) != nil
                
                if (hasAlbum || hasTitle) && index < 9 {
                    tempLyrics[index].lyricsSentence = ""
                    continue MainLoop
                }
                
                if hasTitle && hasAlbum {
                    tempLyrics[index].lyricsSentence = ""
                    continue MainLoop
                }
                
                for filter in otherIDInfos {
                    if line.rangeOfString(filter) != nil {
                        tempLyrics[index].lyricsSentence = ""
                        continue MainLoop
                    }
                }
            }
            for filter in directFilter {
                if line.rangeOfString(filter) != nil {
                    tempLyrics[index].lyricsSentence = ""
                    continue MainLoop
                }
            }
            for filter in conditionalFilter {
                if line.rangeOfString(filter) != nil {
                    for aColon in colons {
                        if line.rangeOfString(aColon) != nil {
                            tempLyrics[index].lyricsSentence = ""
                            continue MainLoop
                        }
                    }
                }
            }
        }
        lyrics = tempLyrics
        idTags = tempIDTags
        timeDly = tempTimeDly
    }
    
    func cleanCache() {
        lyrics.removeAll()
        idTags.removeAll()
        timeDly = 0
    }
    
}
