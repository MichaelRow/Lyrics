//
//  KugouSource.swift
//  LyricsX
//
//  Created by Eru on 2017/6/18.
//  Copyright © 2017年 Eru. All rights reserved.
//

import Cocoa
import Alamofire

private let KugouSearchURL = "http://lyrics.kugou.com/search"

class KugouSource: LyricsSource {
    
    weak var delegate: LyricsSourceDelegate?
    private var request: DataRequest?
    
    var name: LyricsSourceName {
        return .Kugou
    }
    
    func startSearch(info: SongBasicInfo) {
        // 停止请求
        stopSearch()
        
        // 发起新请求
        var params = [ "ver"     : "1",
                       "man"     : "yes",
                       "client"  : "pc",
                       "keyword" : info.title + " " + info.artist ]
        if info.duration != nil {
            params["duration"] = String(info.duration!)
        }
        
        request = Alamofire.request(KugouSearchURL, parameters: params)
        request!.responseJSON { response in
            guard
                response.result.isSuccess,
                let rootDic = response.result.value as? [String:Any],
                let candidates = rootDic["candidates"] as? [[String:Any]]
                else { return }
            
            var lyricsArray = [WebLyrics]()
            for candidate in candidates {
                guard let kugouLyrics = KugouWebLyrics.webLyrics(info:info, dic: candidate) else { continue }
                lyricsArray.append(kugouLyrics)
            }

            let lyricsList = WebLyricsList(lyricsArray, source: .Kugou)
            self.delegate?.lyricsSource(self, didCompleteWith: lyricsList, songInfo: info)
        }
    }

    func stopSearch() {
        request?.cancel()
    }
}
