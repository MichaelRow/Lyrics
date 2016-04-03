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
        //过滤主要的思路是：1.歌词中若出现"直接过滤列表"中的关键字则直接清除该行
        //               2.歌词中若出现"条件过滤列表"中的关键字以及各种形式冒号则清除该行
        //               3.如果开启智能过滤，则将lrc文件中的ID-Tag内容（包含歌曲名、专辑名、制作者等）作为过滤关键字，
        //                 由于在歌词中嵌入的歌曲信息主要集中在前10行并连续出现，为了防止误过滤（有些歌词本身就含有歌
        //                 曲名），过滤需要参照上下文，如果上下文有空行则顺延。
        let userDefaults = NSUserDefaults.standardUserDefaults()
        let directFilter = userDefaults.arrayForKey(LyricsDirectFilter) as! [String]
        let conditionalFilter = userDefaults.arrayForKey(LyricsConditionalFilter) as! [String]
        var prevFiltered: Bool = false
        var prevHasTitleAlbum: Bool = false
        var emptyLine: Int = 0
        MainLoop: for index in 0 ..< tempLyrics.count {
            var currentHasTitleAlbum = false
            let line = tempLyrics[index].lyricsSentence.stringByReplacingOccurrencesOfString(" ", withString: "").lowercaseString
            if line == "" {
                emptyLine += 1
                continue MainLoop
            }
            if userDefaults.boolForKey(LyricsEnableSmartFilter) {
                let hasTitle: Bool = (line.rangeOfString(title) != nil) || (title.rangeOfString(line) != nil)
                let hasAlbum: Bool = (line.rangeOfString(album) != nil) || (album.rangeOfString(line) != nil)
                let isTitleAlbumSimillar: Bool = (title.rangeOfString(album) != nil) || (album.rangeOfString(title) != nil)
                
                if hasTitle && hasAlbum && !isTitleAlbumSimillar {
                    if prevHasTitleAlbum {
                        tempLyrics[index-1-emptyLine].lyricsSentence = ""
                    }
                    tempLyrics[index].lyricsSentence = ""
                    prevFiltered = true
                    continue MainLoop
                }
                
                for filter in otherIDInfos {
                    if line.rangeOfString(filter) != nil {
                        if prevHasTitleAlbum {
                            tempLyrics[index-1-emptyLine].lyricsSentence = ""
                        }
                        tempLyrics[index].lyricsSentence = ""
                        prevFiltered = true
                        continue MainLoop
                    }
                }
                
                if index < 10 && (hasAlbum || hasTitle) {
                    if prevHasTitleAlbum {
                        tempLyrics[index-1-emptyLine].lyricsSentence = ""
                        tempLyrics[index].lyricsSentence = ""
                        prevFiltered = true
                        continue MainLoop
                    }
                    else if prevFiltered {
                        tempLyrics[index].lyricsSentence = ""
                        prevFiltered = true
                        continue MainLoop
                    }
                    else {
                        currentHasTitleAlbum = true
                    }
                }
            }
            for filter in directFilter {
                if line.rangeOfString(filter) != nil {
                    if prevHasTitleAlbum {
                        tempLyrics[index-1-emptyLine].lyricsSentence = ""
                    }
                    tempLyrics[index].lyricsSentence = ""
                    prevFiltered = true
                    if currentHasTitleAlbum {
                        currentHasTitleAlbum = false
                    }
                    continue MainLoop
                }
            }
            for filter in conditionalFilter {
                if line.rangeOfString(filter) != nil {
                    for aColon in colons {
                        if line.rangeOfString(aColon) != nil {
                            if prevHasTitleAlbum {
                                tempLyrics[index-1-emptyLine].lyricsSentence = ""
                            }
                            tempLyrics[index].lyricsSentence = ""
                            prevFiltered = true
                            if currentHasTitleAlbum {
                                currentHasTitleAlbum = false
                            }
                            continue MainLoop
                        }
                    }
                }
            }
            prevFiltered = false
            prevHasTitleAlbum = currentHasTitleAlbum
            if line != "" {
                emptyLine = 0
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
