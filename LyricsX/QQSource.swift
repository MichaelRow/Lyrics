//
//  QQSource.swift
//  LyricsX
//
//  Created by Eru on 2017/7/5.
//  Copyright © 2017年 Eru. All rights reserved.
//

import Cocoa
import Alamofire

private let QQSearchURL = "http://s.music.qq.com/fcgi-bin/music_search_new_platform?t=0&n=10&aggr=1&cr=1&loginUin=0&format=json&inCharset=GB2312&outCharset=utf-8&notice=0&platform=jqminiframe.json&needNewCode=0&p=1&catZhida=0&remoteplace=sizer.newclient.next_song&w=%@ %@"

class QQSource: LyricsSource {
    
    weak var delegate: LyricsSourceDelegate?
    
    private var request: DataRequest?
    
    var name: LyricsSourceName {
        return .QQMusic
    }
    
    func startSearch(info: SongBasicInfo) {
        stopSearch()
        
        let searchURL = String(format: QQSearchURL, info.title, info.artist).urlEncoding
        request = Alamofire.request(searchURL, parameters: nil, encoding: URLEncoding.queryString )
        request!.responseJSON(completionHandler: { (response) in
            guard
                response.result.isSuccess,
                let rootDic = response.result.value as? [String:Any],
                let dataDic = rootDic["data"] as? [String:Any],
                let songDic = dataDic["song"] as? [String:Any],
                let songArray = songDic["list"] as? [[String:Any]]
                else { return }
            
            var lyricsArray = [WebLyrics]()
            for song in songArray {
                guard let lyrics = QQWebLyrics.webLyrics(info: info, dic: song) else { continue }
                lyricsArray.append(lyrics)
            }

            let lyricsList = WebLyricsList(lyricsArray, source: .QQMusic)
            self.delegate?.lyricsSource(self, didCompleteWith: lyricsList, songInfo: info)
        })
    }
    
    func stopSearch() {
        request?.cancel()
    }
    
}
