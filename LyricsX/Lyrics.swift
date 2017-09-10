//
//  Lyrics.swift
//  LyricsX
//
//  Created by Eru on 2017/7/8.
//  Copyright © 2017年 Eru. All rights reserved.
//

import Cocoa

struct Lyrics {
    
    /// 歌词的原子组成
    enum BaseUnitType {
        case Word
        case Line
    }
    
    private(set) var lines: [LyricsLine]
    
    private(set) var type: BaseUnitType
    
    private(set) var info: MetaData
    
    var translationLanguages: Set<Language>
    
    init(lines: [LyricsLine], type: BaseUnitType, info: MetaData) {
        self.lines = lines
        self.type = type
        self.info = info
        translationLanguages = []
    }
    
    var stringValue: String {
        return lines.reduce("") { $0 + ($1.line + "\n") }
    }
    
    mutating func translate(line: String, for language: Language, at lineIndex: Int) {
        guard lineIndex < lines.count else { return }
        translationLanguages.insert(language)
        lines[lineIndex].translate(line: line, for: language)
    }
    
    mutating func translate(words romajis: [String], for language: Language, at lineIndex: Int) {
        guard lineIndex < lines.count else { return }
        
        translationLanguages.insert(language)
        
        //保存整句翻译
        let transLine = romajis.reduce("", { $0 + $1 })
        lines[lineIndex].translate(line: transLine, for: .Romaji)

        //保存单字翻译
        guard lines[lineIndex].words != nil else { return }
        let wordCount = lines[lineIndex].words!.count
        for romajiIndex in 0 ..< romajis.count {
            guard romajiIndex < wordCount else { break }
            lines[lineIndex].set(romajis: romajis)
        }
    }
}
