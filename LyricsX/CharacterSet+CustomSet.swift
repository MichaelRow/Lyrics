//
//  CharacterSet+CustomSet.swift
//  LyricsX
//
//  Created by Eru on 2017/7/16.
//  Copyright © 2017年 Eru. All rights reserved.
//

import Foundation

extension CharacterSet {
    
    /// 排版需要微调的常用标点
    static let punctuation = NSCharacterSet(charactersIn: "，。、．")
    
    static private var _ckjUnifiedIdeographs: NSCharacterSet?
    
    /// 中日韩表意文字集
    static var ckjUnifiedIdeographs: NSCharacterSet {
        if _ckjUnifiedIdeographs != nil {
            return _ckjUnifiedIdeographs!
        }
        
        let set = NSMutableCharacterSet()
        // Hangul Jamo
        set.addCharacters(in: NSRange(location: 0x1100, length: 256))
        // Enclosed Alphanumerics
        set.addCharacters(in: NSRange(location: 0x2460, length: 160))
        // Miscellaneous Symbols
        set.addCharacters(in: NSRange(location: 0x2600, length: 256))
        // Dingbats
        set.addCharacters(in: NSRange(location: 0x2700, length: 192))
        // CJK Radicals Supplement
        set.addCharacters(in: NSRange(location: 0x2E80, length: 128))
        // Kangxi Radicals
        set.addCharacters(in: NSRange(location: 0x2F00, length: 224))
        // Ideographic Description Characters
        set.addCharacters(in: NSRange(location: 0x2FF0, length: 16))
        // CJK Symbols and Punctuation
        set.addCharacters(in: NSRange(location: 0x3000, length: 64))
        set.removeCharacters(in: NSRange(location: 0x3008, length: 10))
        set.removeCharacters(in: NSRange(location: 0x3014, length: 12))
        // Hiragana
        set.addCharacters(in: NSRange(location: 0x3040, length: 96))
        // Katakana
        set.addCharacters(in: NSRange(location: 0x30A0, length: 96))
        // Bopomofo
        set.addCharacters(in: NSRange(location: 0x3100, length: 48))
        // Hangul Compatibility Jamo
        set.addCharacters(in: NSRange(location: 0x3130, length: 96))
        // Kanbun
        set.addCharacters(in: NSRange(location: 0x3190, length: 16))
        // Bopomofo Extended
        set.addCharacters(in: NSRange(location: 0x31A0, length: 32))
        // CJK Strokes
        set.addCharacters(in: NSRange(location: 0x31C0, length: 48))
        // Katakana Phonetic Extensions
        set.addCharacters(in: NSRange(location: 0x31F0, length: 16))
        // Enclosed CJK Letters and Months
        set.addCharacters(in: NSRange(location: 0x3200, length: 256))
        // CJK Compatibility
        set.addCharacters(in: NSRange(location: 0x3300, length: 256))
        // CJK Unified Ideographs Extension A
        set.addCharacters(in: NSRange(location: 0x3400, length: 2582))
        // CJK Unified Ideographs
        set.addCharacters(in: NSRange(location: 0x4E00, length: 20941))
        // Hangul Syllables
        set.addCharacters(in: NSRange(location: 0xAC00, length: 11172))
        // Hangul Jamo Extended-B
        set.addCharacters(in: NSRange(location: 0xD7B0, length: 80))
        // U+F8FF (Private Use Area)
        set.addCharacters(in: "")
        // CJK Compatibility Ideographs
        set.addCharacters(in: NSRange(location: 0xF900, length: 512))
        // Vertical Forms
        set.addCharacters(in: NSRange(location: 0xFE10, length: 16))
        // Halfwidth and Fullwidth Forms
        set.addCharacters(in: NSRange(location: 0xFF00, length: 240))
        // Enclosed Ideographic Supplement
        set.addCharacters(in: NSRange(location: 0x1F200, length: 256))
        // Enclosed Ideographic Supplement
        set.addCharacters(in: NSRange(location: 0x1F300, length: 768))
        // Emoticons (Emoji)
        set.addCharacters(in: NSRange(location: 0x1F600, length: 80))
        // Transport and Map Symbols
        set.addCharacters(in: NSRange(location: 0x1F680, length: 128))
        
        _ckjUnifiedIdeographs = set
        
        return set
    }
}
