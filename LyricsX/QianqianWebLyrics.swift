//
//  QianqianWebLyrics.swift
//  LyricsX
//
//  Created by Eru on 2017/7/1.
//  Copyright © 2017年 Eru. All rights reserved.
//

import Cocoa
import Alamofire

class QianqianWebLyrics: Downloadable, WebLyrics {
    
    var info: SongBasicInfo
    
    var serverTitle: String?
    
    var serverArtist: String?
    
    fileprivate var lyricsURL: String
    
    var _lyricsText: String?
    
    var _lyrics: Lyrics?
    
    fileprivate init(info: SongBasicInfo, lyricsURL: String) {
        self.info = info
        self.lyricsURL = lyricsURL
    }
    
    var lyricsSource: LyricsSourceName {
        return .Qianqian
    }
    
    var lyricsType: LyricsType {
        return .Lrc
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

extension QianqianWebLyrics {
    
    static func webLyrics(info: SongBasicInfo, dic:[String:Any]) -> WebLyrics? {
        guard let lyricsURL = dic["url"] as? String else { return nil }
        
        let qianqianLyrics = QianqianWebLyrics(info: info, lyricsURL: lyricsURL)
        qianqianLyrics.serverTitle = dic["title"] as? String
        qianqianLyrics.serverArtist = dic["artist"] as? String
        
        return qianqianLyrics
    }
    
}
