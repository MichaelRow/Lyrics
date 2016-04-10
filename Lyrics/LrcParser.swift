//
//  LrcParser.swift
//  Lyrics
//
//  Created by Eru on 16/3/25.
//  Copyright © 2016年 Eru. All rights reserved.
//

import Cocoa

enum LrcType: Int {
    case Lyrics, Title, Album, TitleAndAlbum, TitleAndAlbumSimillar, Other
}

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
                    if idStr.stringByReplacingOccurrencesOfString(" ", withString: "").lowercaseString != "offset" {
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
    
    func parseWithFilter(lrcContents: String, iTunesTitle: String?, iTunesAlbum: String?) {
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
                    let idStr: String = idTag.substringWithRange(NSMakeRange(1, colonRange.location-1)).stringByReplacingOccurrencesOfString(" ", withString: "")
                    let idContent: String = idTag.substringWithRange(NSMakeRange(colonRange.location+1, idTag.length-colonRange.length-colonRange.location-1)).stringByReplacingOccurrencesOfString(" ", withString: "")
                    switch idStr.lowercaseString {
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
        //                 曲名），过滤需要参照上下文，如果上下文有空行则顺延。如果连续出现歌曲名或者专辑名则认为是歌词
        //                 本身有该字符串，比如歌曲名是"You"，歌词为"You are great"，如果歌词大于等于歌曲名的5倍也认
        //                 为歌词本身有歌曲名。
        let userDefaults = NSUserDefaults.standardUserDefaults()
        let directFilter = NSKeyedUnarchiver.unarchiveObjectWithData(userDefaults.dataForKey(LyricsDirectFilter)!) as! [FilterString]
        let conditionalFilter = NSKeyedUnarchiver.unarchiveObjectWithData(userDefaults.dataForKey(LyricsConditionalFilter)!) as! [FilterString]
        let isIDTagTitleAlbumSimillar: Bool = (title.rangeOfString(album) != nil) || (album.rangeOfString(title) != nil)
        let isiTunesTitleAlbumSimillar: Bool
        if iTunesTitle != nil && iTunesAlbum != nil {
            isiTunesTitleAlbumSimillar = (iTunesTitle!.rangeOfString(iTunesAlbum!) != nil) || (iTunesAlbum!.rangeOfString(iTunesTitle!) != nil)
        }
        else {
            isiTunesTitleAlbumSimillar = false
        }
        let isTitleAlbumSimillar: Bool = isIDTagTitleAlbumSimillar || isiTunesTitleAlbumSimillar
        var prevLrcType: LrcType = .Lyrics
        var emptyLine: Int = 0
        var lastTitleAlbumSimillarIdx = -1
        
        MainLoop: for index in 0 ..< tempLyrics.count {
            var currentLrcType: LrcType = .Lyrics
            let line = tempLyrics[index].lyricsSentence.stringByReplacingOccurrencesOfString(" ", withString: "")
            if line == "" {
                emptyLine += 1
                continue MainLoop
            }
            for filter in directFilter {
                let searchResult: Bool
                if filter.caseSensitive {
                    searchResult = line.rangeOfString(filter.keyword) != nil
                }
                else {
                    searchResult = line.rangeOfString(filter.keyword, options: [.CaseInsensitiveSearch], range: nil, locale: nil) != nil
                }
                if searchResult {
                    if prevLrcType == .Title || prevLrcType == .Album {
                        tempLyrics[index-1-emptyLine].enabled = false
                    }
                    else if prevLrcType == .TitleAndAlbumSimillar {
                        if lastTitleAlbumSimillarIdx != -1 {
                            tempLyrics[lastTitleAlbumSimillarIdx].enabled = false
                            lastTitleAlbumSimillarIdx = -1
                        }
                        tempLyrics[index-1-emptyLine].enabled = false
                    }
                    tempLyrics[index].enabled = false
                    prevLrcType = .Other
                    continue MainLoop
                }
            }
            
            for filter in conditionalFilter {
                let searchResult: Bool
                if filter.caseSensitive {
                    searchResult = line.rangeOfString(filter.keyword) != nil
                }
                else {
                    searchResult = line.rangeOfString(filter.keyword, options: [.CaseInsensitiveSearch], range: nil, locale: nil) != nil
                }
                if searchResult {
                    for aColon in colons {
                        if line.rangeOfString(aColon) != nil {
                            if prevLrcType == .Title || prevLrcType == .Album {
                                tempLyrics[index-1-emptyLine].enabled = false
                            }
                            else if prevLrcType == .TitleAndAlbumSimillar {
                                if lastTitleAlbumSimillarIdx != -1 {
                                    tempLyrics[lastTitleAlbumSimillarIdx].enabled = false
                                    lastTitleAlbumSimillarIdx = -1
                                }
                                tempLyrics[index-1-emptyLine].enabled = false
                            }
                            tempLyrics[index].enabled = false
                            prevLrcType = .Other
                            continue MainLoop
                        }
                    }
                }
            }
            
            if userDefaults.boolForKey(LyricsEnableSmartFilter) {
                var ignoreTitle: Bool = false
                var ignoreAlbum: Bool = false
                
                let hasIDTagTitle: Bool = (line.rangeOfString(title, options: [.CaseInsensitiveSearch], range: nil, locale: nil) != nil) || (title.rangeOfString(line, options: [.CaseInsensitiveSearch], range: nil, locale: nil) != nil)
                
                if hasIDTagTitle {
                    if line.characters.count/title.characters.count > 4 {
                        ignoreTitle = true
                    }
                }
                
                let hasIDTagAlbum: Bool = (line.rangeOfString(album, options: [.CaseInsensitiveSearch], range: nil, locale: nil) != nil) || (album.rangeOfString(line, options: [.CaseInsensitiveSearch], range: nil, locale: nil) != nil)
                
                if hasIDTagAlbum {
                    if line.characters.count/album.characters.count > 4 {
                        ignoreAlbum = true
                    }
                }
                
                let hasiTunesTitle: Bool
                if iTunesTitle == nil {
                    hasiTunesTitle = false
                }
                else {
                    hasiTunesTitle = (line.rangeOfString(iTunesTitle!, options: [.CaseInsensitiveSearch], range: nil, locale: nil) != nil) || (iTunesTitle!.rangeOfString(line, options: [.CaseInsensitiveSearch], range: nil, locale: nil) != nil)
                    if !ignoreTitle && hasiTunesTitle {
                        if line.characters.count/iTunesTitle!.characters.count > 4 {
                            ignoreTitle = true
                        }
                    }
                }
                
                let hasiTunesAlbum: Bool
                if iTunesAlbum == nil {
                    hasiTunesAlbum = false
                }
                else {
                    hasiTunesAlbum = (line.rangeOfString(iTunesAlbum!, options: [.CaseInsensitiveSearch], range: nil, locale: nil) != nil) || (iTunesAlbum!.rangeOfString(line, options: [.CaseInsensitiveSearch], range: nil, locale: nil) != nil)
                    if !ignoreAlbum && hasiTunesAlbum {
                        if line.characters.count/iTunesAlbum!.characters.count > 4 {
                            ignoreAlbum = true
                        }
                    }
                }
                
                let hasTitle: Bool = hasIDTagTitle || hasiTunesTitle
                let hasAlbum: Bool = hasIDTagAlbum || hasiTunesAlbum
                
                for str in otherIDInfos {
                    if line.rangeOfString(str, options: [.CaseInsensitiveSearch], range: nil, locale: nil) != nil {
                        if prevLrcType == .Title || prevLrcType == .Album {
                            tempLyrics[index-1-emptyLine].enabled = false
                        }
                        else if prevLrcType == .TitleAndAlbumSimillar {
                            if lastTitleAlbumSimillarIdx != -1 {
                                tempLyrics[lastTitleAlbumSimillarIdx].enabled = false
                                lastTitleAlbumSimillarIdx = -1
                            }
                            tempLyrics[index-1-emptyLine].enabled = false
                        }
                        tempLyrics[index].enabled = false
                        prevLrcType = .Other
                        continue MainLoop
                    }
                }
                
                if hasTitle && hasAlbum {
                    if isTitleAlbumSimillar {
                        if !ignoreTitle && !ignoreAlbum {
                            currentLrcType = .TitleAndAlbumSimillar
                            if prevLrcType == .TitleAndAlbumSimillar {
                                if lastTitleAlbumSimillarIdx == -1 {
                                    lastTitleAlbumSimillarIdx = index-1-emptyLine
                                }
                                else {
                                    currentLrcType = .Lyrics
                                }
                            }
                        }
                    }
                    else {
                        if prevLrcType == .Title || prevLrcType == .Album {
                            tempLyrics[index-1-emptyLine].enabled = false
                        }
                        tempLyrics[index].enabled = false
                        prevLrcType = .TitleAndAlbum
                        continue MainLoop
                    }
                }
                else if hasAlbum && !ignoreAlbum {
                    if prevLrcType == .Title {
                        tempLyrics[index-1-emptyLine].enabled = false
                        tempLyrics[index].enabled = false
                        prevLrcType = .Album
                        continue MainLoop
                    }
                    else if prevLrcType == .Other || prevLrcType == .TitleAndAlbum {
                        tempLyrics[index].enabled = false
                        prevLrcType = .Album
                        continue MainLoop
                    }
                    else if prevLrcType == .TitleAndAlbumSimillar {
                        if lastTitleAlbumSimillarIdx == -1 {
                            tempLyrics[index-1-emptyLine].enabled = false
                            tempLyrics[index].enabled = false
                        }
                        else {
                            currentLrcType = .Lyrics
                        }
                    }
                    else {
                        currentLrcType = .Album
                    }
                }
                else if hasTitle && !ignoreTitle {
                    if prevLrcType == .Album {
                        tempLyrics[index-1-emptyLine].enabled = false
                        tempLyrics[index].enabled = false
                        prevLrcType = .Title
                        continue MainLoop
                    }
                    else if prevLrcType == .Other || prevLrcType == .TitleAndAlbum {
                        tempLyrics[index].enabled = false
                        prevLrcType = .Title
                        continue MainLoop
                    }
                    else if prevLrcType == .TitleAndAlbumSimillar {
                        if lastTitleAlbumSimillarIdx == -1 {
                            tempLyrics[index-1-emptyLine].enabled = false
                            tempLyrics[index].enabled = false
                        }
                        else {
                            currentLrcType = .Lyrics
                        }
                    }
                    else {
                        currentLrcType = .Title
                    }
                }
            }
            
            if currentLrcType == .Lyrics && lastTitleAlbumSimillarIdx != -1 {
                lastTitleAlbumSimillarIdx = -1
            }
            prevLrcType = currentLrcType
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
