//
//  LrcDecoder.swift
//  LyricsX
//
//  Created by Eru on 2017/8/2.
//  Copyright © 2017年 Eru. All rights reserved.
//

import Cocoa

/// 通用歌词解析器
final class LrcDecoder: LyricsDecoder {
    
    static var shared: LyricsDecoder = LrcDecoder()
    
    private var timeTagRex: NSRegularExpression
    
    private var idTagRex: NSRegularExpression
    
    private init() {
        
        timeTagRex = try! NSRegularExpression(pattern: "\\[\\d+:\\d+.\\d+\\]|\\[\\d+:\\d+\\]", options: [])
        idTagRex = try! NSRegularExpression(pattern: "\\[[^\\]]+:[^\\]]+\\]", options: [])
    }
    
    func decode(_ text: String) -> Lyrics? {
        
        guard let parseResult = parse(text) else { return nil }
        let timeDic = parseResult.timeTrack
        let tagInfo = parseResult.infos
        let sortedTime = timeDic.keys.sorted { $0 < $1 }
        var info = MetaData()
        var lines = [LyricsLine]()
        
        guard timeDic.count > 0 else { return nil }
        
        for index in 0 ..< sortedTime.count {
            let currentTime = sortedTime[index]
            guard let content = timeDic[currentTime] else { continue }
            let nextTime: Int
            if index + 1 < sortedTime.count {
                nextTime = sortedTime[index + 1]
            } else {
                nextTime = Int.max
            }
            
            var line = LyricsLine()
            line.reset(line: content, begin: currentTime, end: nextTime)
            lines.append(line)
        }
        
        for key in tagInfo.keys {
            guard let value = tagInfo[key] else { continue }
            info.set(value: value, forKey: key)
        }
        
        let lyrics = Lyrics(lines: lines, type: .Line, info: info)
        
        return lyrics
    }
    
    /// 解析lrc歌词
    func parse(_ text: String) -> (timeTrack: [Int : String], infos: [String : String])? {
        
        var timeDic = [Int : String]()
        var infos = [String : String]()
        
        let lrcParagraphs = text.components(separatedBy: CharacterSet.newlines)
        for lrcLine in lrcParagraphs {
            let timeTagsMatched = timeTagRex.matches(in: lrcLine, options: [], range: NSRange(location: 0, length: lrcLine.characters.count))
            if timeTagsMatched.count > 0 {
                let index = timeTagsMatched.last!.range.location + timeTagsMatched.last!.range.length
                let lineContent = lrcLine.substring(from: lrcLine.characters.index(lrcLine.startIndex, offsetBy: index))
                for result in timeTagsMatched {
                    guard let range = lrcLine.range(from: result.range) else { continue }
                    let timeTag = lrcLine.substring(with: range)
                    guard let msTime = time(from: timeTag) else { continue }
                    timeDic[msTime] = lineContent
                }
                
            } else {
                
                let idTagsMatched = idTagRex.matches(in: lrcLine, options: [], range: NSRange(location: 0, length: lrcLine.characters.count))
                guard idTagsMatched.count > 0 else { continue }
                
                for result in idTagsMatched {
                    guard let range = lrcLine.range(from: result.range) else { continue }
                    let idTag = lrcLine.substring(with: range)
                    guard let colonRange = idTag.range(of: ":") else { continue }
                    
                    let keyStartIndex = idTag.index(after: idTag.startIndex)
                    let valueEndIndex = idTag.index(before: idTag.endIndex)
                    
                    let key = idTag.substring(with: keyStartIndex ..< colonRange.lowerBound)
                    let value = idTag.substring(with: colonRange.upperBound ..< valueEndIndex)
                    
                    infos[key] = value
                }
            }
        }
        return timeDic.count > 0 ? (timeDic, infos) : nil
    }
    
//MARK: Private
    
    private func time(from tag: String) -> Int? {
        guard let colonRange = tag.range(of: ":") else { return nil }
        guard let dotRange = tag.range(of: ".") else { return nil }
        guard let leftBracketRange = tag.range(of: "[") else { return nil }
        guard let rightBracketRange = tag.range(of: "]") else { return nil }
        
        let minStr = tag.substring(with: leftBracketRange.upperBound ..< colonRange.lowerBound)
        let secStr = tag.substring(with: colonRange.upperBound ..< dotRange.lowerBound)
        let msecStr = tag.substring(with: dotRange.upperBound ..< rightBracketRange.lowerBound)
        
        guard let min = Int(minStr) else { return nil }
        guard let sec = Int(secStr) else { return nil }
        guard let msec = Int(msecStr) else { return nil }
        
        return (min * 60 + sec) * 1000 + msec
    }
}

