//
//  KugouWebLyrics.swift
//  LyricsX
//
//  Created by Eru on 2017/6/30.
//  Copyright © 2017年 Eru. All rights reserved.
//

import Cocoa
import Alamofire

private let KugouGetLyricsURL = "http://lyrics.kugou.com/download"

class KugouWebLyrics: Downloadable, WebLyrics {
    
    var info: SongBasicInfo
    
    var serverTitle: String?
    
    var serverArtist: String?
    
    var _lyricsText: String?
    
    var _lyrics: Lyrics?
    
    fileprivate var accessKey: String
    
    fileprivate var songID: String
    
    fileprivate init(info: SongBasicInfo, accessKey: String, songID: String) {
        self.info = info
        self.accessKey = accessKey
        self.songID = songID
    }
    
    var lyricsSource: LyricsSourceName {
        return .Kugou
    }
    
    var lyricsType: LyricsType {
        return .Krc
    }
    
    func loadLyrics(completeHandler: @escaping (String?) -> Void) {
        //获取歌词
        let params = [ "ver"       :  "1",
                       "client"    :  "pc",
                       "charset"   :  "utf8",
                       "fmt"       :  "krc",
                       "id"        :  songID,
                       "accesskey" :  accessKey]
        Alamofire.request(KugouGetLyricsURL, parameters: params).responseJSON { (response) in
            //错误处理
            guard
                response.result.isSuccess,
                let rootDic = response.result.value as? [String:Any],
                let status = rootDic["status"] as? Int,
                let content = rootDic["content"] as? String,
                status == 200,
                content != ""
                else {
                    completeHandler(nil)
                    return
            }
            
            self._lyricsText = content
            completeHandler(content)
        }
    }
}

//MARK: - Class Method

extension KugouWebLyrics {
    
    static func webLyrics(info: SongBasicInfo, dic:[String:Any]) -> WebLyrics? {
        guard let accessKey = dic["accesskey"] as? String else { return nil }
        guard let songID = dic["id"] as? String else { return nil }
        
        guard accessKey != "", songID != "" else { return nil }
        
        let serverTitle = dic["song"] as? String
        let serverArtist = dic["singer"] as? String
        
        let kugouLyrics = KugouWebLyrics(info: info, accessKey: accessKey, songID: songID)
        kugouLyrics.serverTitle = serverTitle
        kugouLyrics.serverArtist = serverArtist
        
        return kugouLyrics
    }
    
}

