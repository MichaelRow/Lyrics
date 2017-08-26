//
//  WebLyricesIterator.swift
//  LyricsX
//
//  Created by Eru on 2017/6/29.
//  Copyright © 2017年 Eru. All rights reserved.
//

import Foundation

class WebLyricesIterator {
    
    fileprivate var index = 0
    fileprivate var webLyrics: [WebLyrics]
    
    init(webLyrics: [WebLyrics]) {
        self.webLyrics = webLyrics
    }
}

extension WebLyricesIterator: IteratorProtocol {
    
    typealias Element = WebLyrics
    
    func next() -> WebLyrics? {
        if index < webLyrics.count {
            let element = webLyrics[index]
            index += 1
            return element
        } else {
            return nil
        }
    }
}
