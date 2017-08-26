//
//  TTPodSource.swift
//  LyricsX
//
//  Created by Eru on 2017/7/4.
//  Copyright © 2017年 Eru. All rights reserved.
//

import Cocoa
import Alamofire

private let TTPodSearchURL = "http://lp.music.ttpod.com/lrc/down?lrcid=&artist=%@&title=%@"

class TTPodSource: LyricsSource {

    weak var delegate: LyricsSourceDelegate?
    private var request: DataRequest?
    
    var name: LyricsSourceName {
        return .TTPod
    }
    
    func startSearch(info: SongBasicInfo) {
        stopSearch()
        let searchURL = String(format: TTPodSearchURL, info.artist, info.title).urlEncoding
        
        Alamofire.request(searchURL).responseJSON { (response) in
            guard
                response.result.isSuccess,
                let rootDic = response.result.value as? [String:Any],
                let lrcData = rootDic["data"] as? [String:Any],
                let webLyrics = TTPodWebLyrics.webLyrics(info: info, dic: lrcData)
                else { return }
            
            let lyricsList = WebLyricsList([webLyrics], source: .TTPod)
            self.delegate?.lyricsSource(self, didCompleteWith: lyricsList, songInfo: info)
        }
    }
    
    func stopSearch() {
        request?.cancel()
    }
}
