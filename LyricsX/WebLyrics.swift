//
//  WebLyrics.swift
//  LyricsX
//
//  Created by Eru on 2017/6/22.
//  Copyright © 2017年 Eru. All rights reserved.
//

import Foundation

protocol Downloadable { }

protocol WebLyrics: class {
    
    /// 歌曲基本信息
    var info: SongBasicInfo { get set }
    
    /// 服务端的歌曲名
    var serverTitle: String? { get set }
    
    /// 服务端的歌手名
    var serverArtist: String? { get set }
    
    /// 歌词源
    var lyricsSource: LyricsSourceName { get }
    
    /// 歌词类型
    var lyricsType: LyricsType { get }
    
    /// 私有 歌词存储变量
    var _lyrics: Lyrics? { get set }
    
    /// 私有 歌词文本存储变量
    var _lyricsText: String? { get set }
    
    /// 获取歌词
    func lyricsText(_ completeHandler: @escaping (_ lyrics: String?) -> Void)
    
    /// 获取歌词
    func lyrics(_ completeHandler: @escaping (_ lyrics: Lyrics?) -> Void)
    
    /// 从服务器下载歌词
    func loadLyrics(completeHandler: @escaping (String?) -> Void)
    
    /// 初始化的类方法
    static func webLyrics(info: SongBasicInfo, dic: [String : Any]) -> WebLyrics?
}

extension WebLyrics where Self: Downloadable {
    
    func lyricsText(_ completeHandler: @escaping (_ lyrics: String?) -> Void) {
        if _lyricsText != nil {
            completeHandler(_lyricsText)
            return
        }
        loadLyrics { text in
            completeHandler(text)
        }
    }
    
    func lyrics(_ completeHandler: @escaping (_ lyrics: Lyrics?) -> Void) {
        if _lyrics != nil {
            completeHandler(_lyrics)
            return
        }
        loadLyrics { text in
            guard text != nil else {
                completeHandler(nil)
                return
            }
            
            let lyrics = self.lyricsType.decoder.decode(text!)
            self._lyrics = lyrics
            completeHandler(lyrics)
        }
    }
}

