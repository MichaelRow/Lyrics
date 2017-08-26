//
//  LyricsDecoder.swift
//  LyricsX
//
//  Created by Eru on 2017/8/2.
//  Copyright © 2017年 Eru. All rights reserved.
//

import Foundation

protocol LyricsDecoder {
    
    static var shared: LyricsDecoder { get }
    
    /// 解析
    func decode(_ text: String) -> Lyrics?
}

