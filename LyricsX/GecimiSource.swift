//
//  GecimiSource.swift
//  LyricsX
//
//  Created by Eru on 2017/7/4.
//  Copyright © 2017年 Eru. All rights reserved.
//

import Cocoa
import Alamofire

private let GecimiSearchURL = "http://geci.me/api/lyric/%@/%@"

class GecimiSource: LyricsSource {
    
    weak var delegate: LyricsSourceDelegate?
    private var request: DataRequest?
    
    var name: LyricsSourceName {
        return .Gecimi
    }
    
    func startSearch(info: SongBasicInfo) {
        stopSearch()
        
        let url = String(format: GecimiSearchURL, info.title, info.artist).urlEncoding
        request = Alamofire.request(url)
        request!.responseJSON { (response) in
            guard
                response.result.isSuccess,
                let rootDic = response.result.value as? [String:Any],
                let resultArray = rootDic["result"] as? [[String:Any]]
                else { return }

            var lyricsArray = [WebLyrics]()
            for result in resultArray {
                guard let webLyrics = GecimiWebLyrics.webLyrics(info: info, dic: result) else { continue }
                lyricsArray.append(webLyrics)
            }
            
            let lyricsList = WebLyricsList(lyricsArray, source: .Gecimi)
            self.delegate?.lyricsSource(self, didCompleteWith: lyricsList, songInfo: info)
        }
    }
    
    func stopSearch() {
        request?.cancel()
    }
}
