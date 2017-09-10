//
//  LyricsLine.swift
//  LyricsX
//
//  Created by Eru on 2017/7/8.
//  Copyright © 2017年 Eru. All rights reserved.
//

import Cocoa

enum Language {
    case Chinese
    case Japanese
    case English
    case Korea
    case Romaji
    case Other
}

struct LyricsLine {
    
    /// 歌词单词
    private(set) var words: [LyricsWord]?
    
    /// 翻译
    private(set) var translations: [Language : String]

    /// 歌词行
    private(set) var line: String
    
    /// 时间起点
    private(set) var begin: Int
    
    /// 时间终点
    private(set) var end: Int
    
    /// 时长
    private(set) var duration: Int
    
    init() {
        translations = [:]
        line = ""
        begin = 0
        end = 0
        duration = 0
    }
    
    mutating func reset(words: [LyricsWord], begin: Int, duration: Int) {
        
        guard duration > 0 else { return }
        self.duration = duration
        self.begin = max(begin, 0)
        self.end = self.begin + self.duration
                
        self.words = nil
        self.line.removeAll()
        self.translations.removeAll()
        
        self.words = words.sorted { $0.begin < $1.begin }
        self.line = self.words!.reduce("", { $0 + $1.word })
    }
    
    mutating func reset(line: String, begin: Int, end: Int) {
        
        self.words = nil
        self.line.removeAll()
        self.translations.removeAll()
        
        self.line = line
        self.begin = max(begin, 0)
        self.end = max(end, begin)
        self.duration = end - begin
    }
    
    func translation(for language: Language) -> String? {
        return translations[language]
    }
    
    mutating func translate(line translation: String, for language: Language) {
        translations[language] = translation
    }
    
    mutating func set(romajis: [String]) {
        guard
            words != nil,
            words!.count == romajis.count
            else { return }
        for index in 0 ..< words!.count {
            words![index].romaji = romajis[index]
        }
    }
    
    func isInRange(position: Int) -> Bool {
        if position >= begin && position <= end {
            return true
        } else {
            return false
        }
    }
}
