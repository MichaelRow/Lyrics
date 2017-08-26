//
//  KrcDecoder.swift
//  LyricsX
//
//  Created by Eru on 2017/8/2.
//  Copyright © 2017年 Eru. All rights reserved.
//

import Cocoa

/// 酷狗使用的逐字歌词解析器
final class KrcDecoder: LyricsDecoder {
    
    static let shared: LyricsDecoder = KrcDecoder()
    
    /// 匹配歌词行开头
    private var lineTimeRex: NSRegularExpression
    
    /// 匹配歌词字的时间和字
    private var wordTimeRex: NSRegularExpression
    
    private var infoRex: NSRegularExpression

    private init() {
        lineTimeRex = try! NSRegularExpression(pattern: "\\[\\d+,\\d+\\]", options: [])
        wordTimeRex = try! NSRegularExpression(pattern: "<\\d+,\\d+,\\d+>", options: [])
        infoRex = try! NSRegularExpression(pattern: "\\[[^\\]]+:[^\\]]+\\]", options: [])
    }
    
    func decode(_ text: String) -> Lyrics? {
    
        guard let decrypt = KugouDecrypt.decrypt(base64: text) else { return nil }  
        var lines = [LyricsLine]()
        var info = LyricsInfo()
        //解析
        let paragraphs = decrypt.components(separatedBy: CharacterSet.newlines)
        for krcLine in paragraphs {
            if let lyricsLine = parse(line: krcLine) {
                lines.append(lyricsLine)
            } else if let infoPair = parse(infoLine: krcLine) {
                info.set(value: infoPair.value, forKey: infoPair.key)
            }
        }
        guard lines.count > 0 else { return nil }
        lines.sort { $0.begin < $1.begin }
        var lyrics = Lyrics(lines: lines, type: .Word, info: info)
        
        //翻译
        translate(lyrics: &lyrics)
        
        return lyrics
    }
    
    //MARK: Private
    private func parse(line: String) -> LyricsLine? {
        
        guard let lineMatched = lineTimeRex.firstMatch(in: line, options: [], range: NSRange(location: 0, length: line.characters.count)) else { return nil }
        
        guard let range = line.range(from: lineMatched.range) else { return nil }
        let lineTimeTag = line.substring(with: range)
        
        guard
            let commaIndex = lineTimeTag.index(of: ","),
            let lineBeginTime = Int(lineTimeTag.substring(with: lineTimeTag.index(after: lineTimeTag.startIndex) ..< commaIndex)),
            let lineDuration = Int(lineTimeTag.substring(with: lineTimeTag.index(after: commaIndex) ..< lineTimeTag.index(before: lineTimeTag.endIndex)))
            else { return nil }
        
        //解析歌词字
        guard let words = getWord(with: line, lineBegin: lineBeginTime) else { return nil }
        var lyricsLine = LyricsLine()
        lyricsLine.reset(words: words, begin: lineBeginTime, duration: lineDuration)
        
        return lyricsLine
    }
    
    private func parse(infoLine: String) -> (key: String, value: String)? {
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
            let lyricsWord = LyricsWord(word: word, begin: begin + lineBegin, duration: duration)
            
            lyricsWords.append(lyricsWord)
        }
        
        return lyricsWords
    }
    
    private func translate( lyrics: inout Lyrics) {
        guard
            let translationBase64 = lyrics.info.otherInfo["language"],
            let translationData = Data(base64Encoded: translationBase64),
            let rootDic = try? JSONSerialization.jsonObject(with: translationData, options: .allowFragments) as? [String : Any],
            let contentArray = rootDic?["content"] as? [[String : Any]]
            else { return }
        
        for content in contentArray {
            guard
                let translations = content["lyricContent"] as? [[String]],
                let type = content["type"] as? Int
                else { return }
            
            for index in 0 ..< translations.count {
                var translation = translations[index]
                guard translation.count != 0 else { continue }
                
                if type == 0 {
                    for wordIndex in 0 ..< translation.count {
                        if wordIndex != translation.count - 1 {
                            translation[wordIndex] += " "
                        }
                    }
                    lyrics.translate(words: translation, for: .Romaji, at: index)
                } else {
                    var transLine = translation.reduce("", { $0 + $1 + " " })
                    transLine.removeLast()
                    lyrics.translate(line: transLine, for: .Chinese, at: index)
                }
            }
        }
    }
}
