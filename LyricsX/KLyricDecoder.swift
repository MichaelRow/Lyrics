//
//  KLyricDecoder.swift
//  LyricsX
//
//  Created by Michael Row on 2017/8/11.
//  Copyright © 2017年 Eru. All rights reserved.
//

import Cocoa

/// 网易云音乐使用的逐字歌词解析器
final class KLyricDecoder: LyricsDecoder {
    
    static let shared: LyricsDecoder = KLyricDecoder()
    
    /// 匹配歌词行开头
    private var lineTimeRex: NSRegularExpression
    
    /// 匹配歌词字的时间和字
    private var wordTimeRex: NSRegularExpression
    
    private var infoRex: NSRegularExpression
    
    private init() {
        lineTimeRex = try! NSRegularExpression(pattern: "\\[\\d+,\\d+\\]", options: [])
        wordTimeRex = try! NSRegularExpression(pattern: "(\\d+,\\d+)", options: [])
        infoRex = try! NSRegularExpression(pattern: "\\[[^\\]]+:[^\\]]+\\]", options: [])
    }
    
    func decode(_ text: String) -> Lyrics? {
        
        var lines = [LyricsLine]()
        var info = MetaData()
        
        //解析
        let paragraphs = text.components(separatedBy: CharacterSet.newlines)
        for krcLine in paragraphs {
            if let lyricsLine = parse(line: krcLine) {
                lines.append(lyricsLine)
            } else if let infoPair = parse(infoLine: krcLine) {
                info.set(value: infoPair.1, forKey: infoPair.0)
            }
        }
        guard lines.count > 0 else { return nil }
        lines.sort { $0.begin < $1.begin }
        return Lyrics(lines: lines, type: .Word, info: info)        
    }
    
    //MARK: Private
    private func parse(line: String) -> LyricsLine? {
        
        guard let lineMatched = lineTimeRex.firstMatch(in: line, options: [], range: NSRange(location: 0, length: line.characters.count)) else { return nil }
        
        guard let range = line.range(from: lineMatched.range) else { return nil }
        let lineTimeTag = line.substring(with: range)
        
        guard
            let commaIndex = lineTimeTag.index(of: ","),
            let lineBeginTime = Int(lineTimeTag.substring(with: lineTimeTag.index(after: lineTimeTag.startIndex) ..< commaIndex)),
            let lineDuration = Int(lineTimeTag.substring(with: lineTimeTag.index(after: commaIndex) ..< lineTimeTag.index(before: lineTimeTag.endIndex))),
            let words = getWord(with: line, lineBegin: lineBeginTime)
            else { return nil }
        
        var lyricsLine = LyricsLine()
        lyricsLine.reset(words: words, begin: lineBeginTime, duration: lineDuration)
        
        return lyricsLine
    }
    
    private func parse(infoLine: String) -> (String, String)? {
        guard
            let infoMatched = infoRex.firstMatch(in: infoLine, options: [], range: NSRange(location: 0, length: infoLine.characters.count)),
            let range = infoLine.range(from: infoMatched.range)
            else { return nil }
        
        let infoTag = infoLine.substring(with: range)
        guard let colonIndex = infoTag.index(of: ":") else { return nil }
        
        let keyStartIndex = infoTag.index(after: infoTag.startIndex)
        let valueEndIndex = infoTag.index(before: infoTag.endIndex)
        
        let key = infoTag.substring(with: keyStartIndex ..< colonIndex)
        let value = infoTag.substring(with: infoTag.index(after: colonIndex) ..< valueEndIndex)
        
        return (key,value)
    }
    
    private func getWord(with line: String, lineBegin: Int) -> [LyricsWord]? {
        
        let wordMatches = wordTimeRex.matches(in: line, options: [], range: NSRange(location: 0, length: line.characters.count))
        guard wordMatches.count > 0 else { return nil }
        
        var lyricsWords = [LyricsWord]()
        var currentTime = lineBegin
        for index in 0 ..< wordMatches.count {
            let match = wordMatches[index]
            // 获取时间标签中的时间
            guard let tagRange = line.range(from: match.range) else { continue }
            let wordTimeTag = line.substring(with: tagRange)
            let wordTimes = wordTimeTag.substring(with: wordTimeTag.index(after: wordTimeTag.startIndex) ..< wordTimeTag.index(before: wordTimeTag.endIndex))
            let times = wordTimes.components(separatedBy: ",")
            guard
                times.count >= 2,
                let begin = Int(times[0]),
                let duration = Int(times[1])
                else { continue }
            
            //获取单词开始index
            let startIndex = tagRange.upperBound
            //获取单词结束index
            let endIndex: String.Index
            if index + 1 >= wordMatches.count {
                endIndex = line.endIndex
            } else {
                let offset = wordMatches[index + 1].range.location
                guard let endIndexTemp = line.index(line.startIndex, offsetBy: offset, limitedBy: line.endIndex) else { continue }
                endIndex = endIndexTemp
            }
            //单词
            let word = line.substring(with: startIndex ..< endIndex)
            let lyricsWord = LyricsWord(word: word, begin: begin + currentTime, duration: duration)
            lyricsWords.append(lyricsWord)
            
            currentTime += (begin + duration)
        }
        
        return lyricsWords
    }
}
