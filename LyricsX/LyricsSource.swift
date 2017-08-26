//
//  LyricsSource.swift
//  LyricsX
//
//  Created by Eru on 2017/6/18.
//  Copyright © 2017年 Eru. All rights reserved.
//

import Foundation

protocol LyricsSource: class {
    
    weak var delegate: LyricsSourceDelegate? { get set }
    
    var name: LyricsSourceName { get }
    
    /// 开始搜索
    func startSearch(info: SongBasicInfo)
    
    /// 停止搜索
    func stopSearch()
    
}

protocol LyricsSourceDelegate: class {
    
    func lyricsSource(_ source: LyricsSource, didCompleteWith list: WebLyricsList, songInfo: SongBasicInfo)
}

