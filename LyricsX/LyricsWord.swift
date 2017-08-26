//
//  LyricsWord.swift
//  LyricsX
//
//  Created by Eru on 2017/7/9.
//  Copyright © 2017年 Eru. All rights reserved.
//

import Foundation

struct LyricsWord {
    
    /// 单词
    private(set) var word: String
    
    /// 罗马音
    var romaji: String?
    
    /// 起始位置
    private(set) var begin: Int
    
    /// 长度
    private(set) var duration: Int
    
    /// 结束位置
    private(set) var end: Int
    
    init(word: String = "", begin: Int = 0, duration: Int = 0) {
        self.word = word
        self.begin = begin >= 0 ? begin : 0
        self.duration = duration >= 0 ? duration : 0
        self.end = self.begin + self.duration
    }
    
    func isInRange(position: Int) -> Bool {
        if position >= begin && position <= end {
            return true
        } else {
            return false
        }
    }
}
