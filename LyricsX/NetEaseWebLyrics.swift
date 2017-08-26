//
//  NetEaseWebLyrics.swift
//  LyricsX
//
//  Created by Eru on 2017/7/7.
//  Copyright © 2017年 Eru. All rights reserved.
//

import Cocoa
import Alamofire

private let NetEaseLyricsURL = "http://music.163.com/api/song/lyric?"

class NetEaseWebLyrics: Downloadable, WebLyrics {
    
    var info: SongBasicInfo
    
    var serverTitle: String?
        
    var serverArtist: String?
    
    var _lyricsText: String?
    
    var _lyrics: Lyrics?
    
    fileprivate var songID: Int
    
    var lyricsSource: LyricsSourceName {
        return .NetEase
    }
    
    var lyricsType: LyricsType {
        return .Jrc
    }
    
    fileprivate init(info: SongBasicInfo, songID: Int) {
        self.info = info
        self.songID = songID
    }
    
    func loadLyrics(completeHandler: @escaping (String?) -> Void) {
        let params: [String:Any] = [ "os" : "pc",
                                     "lv" : "-1",
                                     "kv" : "-1",
                                     "tv" : "-1",
                                     "id" : songID ]
        Alamofire.request(NetEaseLyricsURL, parameters: params)
            .responseString(encoding: .utf8) { (response) in
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

extension NetEaseWebLyrics {
    
    static func webLyrics(info: SongBasicInfo, dic: [String : Any]) -> WebLyrics? {
        guard let songID = dic["id"] as? Int else { return nil }
        let webLyrics = NetEaseWebLyrics(info: info, songID: songID)
        webLyrics.serverTitle = dic["name"] as? String
        
        // 读取歌手名
        guard
            let artists = dic["artists"] as? [[String:Any]],
            artists.count > 0
            else { return webLyrics }
        
        webLyrics.serverArtist = artists[0]["name"] as? String
        return webLyrics
    }
}
