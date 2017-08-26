//
//  WebLyricsList.swift
//  LyricsX
//
//  Created by Eru on 2017/7/3.
//  Copyright © 2017年 Eru. All rights reserved.
//

import Cocoa

class WebLyricsList: DefaultIterator {
    
    var sourceName: LyricsSourceName
    
    fileprivate var webLyrics: [WebLyrics]
    
    /// 默认遍历器
    fileprivate(set) var defaultIterator: WebLyricesIterator
    
    init(_ webLyrics: [WebLyrics], source name: LyricsSourceName) {
        self.webLyrics = webLyrics
        self.sourceName = name
        self.defaultIterator = WebLyricesIterator(webLyrics: webLyrics)
    }
    
    func resetIterator() {
        defaultIterator = WebLyricesIterator(webLyrics: webLyrics)
    }
}

//MARK: Sequence

extension WebLyricsList: Sequence {
    
    typealias Iterator = WebLyricesIterator
    
    func makeIterator() -> WebLyricsList.Iterator {
        return WebLyricesIterator(webLyrics: webLyrics)
    }
}

//MARK: Collection

extension WebLyricsList: Collection {
    
    typealias Element = WebLyrics
    
    var startIndex: Int {
        return 0
    }
    
    var endIndex: Int {
        return webLyrics.count
    }
    
    subscript(i: Int) -> Element {
        precondition((0 ..< endIndex).contains(i), "序列越界")
        return webLyrics[i]
    }
    
    func index(after i: Int) -> Int {
        if i < endIndex {
            return i + 1
        } else {
            return endIndex
        }
    }
}

