//
//  GecimiWebLyrics.swift
//  LyricsX
//
//  Created by Eru on 2017/7/4.
//  Copyright © 2017年 Eru. All rights reserved.
//

import Cocoa
import Alamofire

class GecimiWebLyrics: Downloadable, WebLyrics {

    var info: SongBasicInfo
    
    var serverTitle: String?
    
    var serverArtist: String?
    
    var _lyricsText: String?
    
    var _lyrics: Lyrics?
    
    private var lyricsURL: String
    
    var lyricsSource: LyricsSourceName {
        return .Gecimi
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
        }
    }
}

//MARK: - Class Method

extension GecimiWebLyrics {
    static func webLyrics(info: SongBasicInfo, dic:[String:Any]) -> WebLyrics? {
        guard let lrcURL = dic["lrc"] as? String else { return nil }
        let title = dic["song"] as? String
        
        let webLyrics = GecimiWebLyrics(info: info, lyricsURL: lrcURL)
        webLyrics.serverTitle = title
        
        return webLyrics
    }
}
