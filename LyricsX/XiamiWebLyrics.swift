//
//  XiamiWebLyrics.swift
//  LyricsX
//
//  Created by Eru on 2017/7/2.
//  Copyright © 2017年 Eru. All rights reserved.
//

import Cocoa
import Alamofire

class XiamiWebLyrics: Downloadable, WebLyrics {

    var info: SongBasicInfo
    
    var serverTitle: String?
    
    var serverArtist: String?
    
    var _lyricsText: String?
    
    var _lyrics: Lyrics?
    
    private var lyricsURL: String
    
    var lyricsSource: LyricsSourceName {
        return .Xiami
    }
    
    var lyricsType: LyricsType {
        return .Lrc
    }
    
    fileprivate init(info: SongBasicInfo, lyricsURL: String) {
        self.info = info
        self.lyricsURL = lyricsURL
    }
    
    func loadLyrics(completeHandler: @escaping (String?) -> Void) {
        Alamofire.request(lyricsURL).responseString(encoding: .utf8) { (response) in
            guard response.result.isSuccess else {
                completeHandler(nil)
                return
            }
            let text = response.result.value
            self._lyricsText = text
            completeHandler(text)
            return
        }
    }
}

//MARK: - Class Method

extension XiamiWebLyrics {
    
    static func webLyrics(info: SongBasicInfo, dic:[String:Any]) -> WebLyrics? {
        guard let lyricsURL = dic["lrcURL"] as? String else { return nil }
        
        let xiamiLyrics = XiamiWebLyrics(info: info, lyricsURL: lyricsURL)
        xiamiLyrics.serverTitle = dic["title"] as? String
        xiamiLyrics.serverArtist = dic["artist"] as? String
        
        return xiamiLyrics
    }
}
