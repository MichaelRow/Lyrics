//
//  QQWebLyrics.swift
//  LyricsX
//
//  Created by Eru on 2017/7/5.
//  Copyright © 2017年 Eru. All rights reserved.
//

import Cocoa
import Alamofire

private let QQLyricsURL = "http://music.qq.com/miniportal/static/lyric/%li/%li.xml"

class QQWebLyrics: Downloadable, WebLyrics {

    var info: SongBasicInfo
    
    var serverTitle: String?
    
    var serverArtist: String?
    
    var _lyricsText: String?
    
    var _lyrics: Lyrics?
    
    fileprivate var lyricsURL: String
    
    var lyricsSource: LyricsSourceName {
        return .QQMusic
    }
    
    var lyricsType: LyricsType {
        return .Lrc
    }
    
    fileprivate init(info: SongBasicInfo, lyricsURL: String) {
        self.info = info
        self.lyricsURL = lyricsURL
    }
    
    func loadLyrics(completeHandler: @escaping (String?) -> Void) {
        Alamofire.request(lyricsURL).responseData { (response) in
            guard
                response.result.isSuccess,
                let data = response.result.value
                else {
                    completeHandler(nil)
                    return
            }
            
            let text = QQXMLParser().parse(data: data)
            self._lyricsText = text
            completeHandler(text)
            return
        }
    }
}

//MARK: - Class Method

extension QQWebLyrics {
    
    static func webLyrics(info: SongBasicInfo, dic: [String : Any]) -> WebLyrics? {
        guard
            let fCode = dic["f"] as? String,
            let lrcURL = lrcURL(fCode: fCode)
            else { return nil }
        
        let webLyrics = QQWebLyrics(info: info, lyricsURL: lrcURL)
        webLyrics.serverTitle = dic["fsong"] as? String
        webLyrics.serverArtist = dic["fsinger"] as? String
        
        return webLyrics
    }
    
    static private func lrcURL(fCode: String) -> String? {
        guard
            let range = fCode.range(of: "|"),
            let code = Int(fCode.substring(to: range.lowerBound))
            else { return nil }
        
        return String(format: QQLyricsURL, code % 100, code)
    }
}
