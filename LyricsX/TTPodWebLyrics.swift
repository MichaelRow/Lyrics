//
//  TTPodWebLyrics.swift
//  LyricsX
//
//  Created by Eru on 2017/7/4.
//  Copyright © 2017年 Eru. All rights reserved.
//

import Cocoa

class TTPodWebLyrics: WebLyrics {

    var info: SongBasicInfo
    
    var serverTitle: String?
    
    var serverArtist: String?
    
    var _lyricsText: String?
    
    var _lyrics: Lyrics?
    
    var lyricsSource: LyricsSourceName {
        return .TTPod
    }
    
    var lyricsType: LyricsType {
        return .Lrc
    }
    
    fileprivate init(info: SongBasicInfo, lyricsContent: String) {
        self.info = info
        self._lyricsText = lyricsContent
    }
    
    func lyrics(_ completeHandler: @escaping (_ lyrics: Lyrics?) -> Void) {
        let lyrics = self.lyricsType.decoder.decode(_lyricsText!)
        self._lyrics = lyrics
        completeHandler(lyrics)
    }
    
    func lyricsText(_ completeHandler: @escaping (_ lyrics: String?) -> Void) {
        completeHandler(_lyricsText)
    }
    
    func loadLyrics(completeHandler: @escaping (String?) -> Void) {
        
    }
}

//MARK: - Class Method

extension TTPodWebLyrics {
    static func webLyrics(info: SongBasicInfo, dic:[String:Any]) -> WebLyrics? {
        guard let lrc = dic["lrc"] as? String else { return nil }
        return TTPodWebLyrics(info: info, lyricsContent: lrc)
    }
}
