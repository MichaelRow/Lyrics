//
//  NetEaseSource.swift
//  LyricsX
//
//  Created by Eru on 2017/7/7.
//  Copyright © 2017年 Eru. All rights reserved.
//

import Cocoa
import Alamofire

private let NetEaseSearchURL = "http://music.163.com/api/search/pc?"

class NetEaseSource: LyricsSource {
    
    weak var delegate: LyricsSourceDelegate?
    private var request: DataRequest?
    
    var name: LyricsSourceName {
        return .NetEase
    }
    
    func startSearch(info: SongBasicInfo) {
        stopSearch()
        
        let params = [ "offset" : "1",
                       "limit"  : "15",
                       "type"   : "1",
                       "s"      : info.title + " " + info.artist ]
        var headers = Alamofire.SessionManager.defaultHTTPHeaders
        headers["Cookie"]  = "appver=1.5.0.75771;"
        headers["Referer"] = "http://music.163.com/"
        request = Alamofire.request(NetEaseSearchURL, method: .post, parameters: params, headers: headers)
        request?.responseJSON(completionHandler: { (response) in
            guard
                response.result.isSuccess,
                let rootDic = response.result.value as? [String:Any],
                let resultDic = rootDic["result"] as? [String:Any],
                let songArray = resultDic["songs"] as? [[String:Any]]
                else { return }
            
            var webLyrics = [WebLyrics]()
            for songDic in songArray {
                guard let lyrics = NetEaseWebLyrics.webLyrics(info: info, dic: songDic) else { continue }
                webLyrics.append(lyrics)
            }
            
            let lyricsList = WebLyricsList(webLyrics, source: .NetEase)
            self.delegate?.lyricsSource(self, didCompleteWith: lyricsList, songInfo: info)
        })
    }
    
    func stopSearch() {
        request?.cancel()
    }
    
}
