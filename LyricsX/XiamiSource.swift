//
//  XiamiSource.swift
//  LyricsX
//
//  Created by Eru on 2017/7/1.
//  Copyright © 2017年 Eru. All rights reserved.
//

import Cocoa
import Alamofire

private let XiamiSearchURL = "http://www.xiami.com/web/search-songs"
private let XiamiLyricsURL = "http://www.xiami.com/song/playlist/id/%@"

class XiamiSource: LyricsSource {
    
    weak var delegate: LyricsSourceDelegate?
    /// 使用sessionManager方便取消所有请求
    private var manager: SessionManager?
    private var lyricsArray = [WebLyrics]()
    private var reqRemain = 0
    
    var name: LyricsSourceName {
        return .Xiami
    }
    
    func startSearch(info: SongBasicInfo) {
        stopSearch()
        
        reqRemain = 0
        lyricsArray.removeAll()
        
        let params = [ "key" : info.title + " " + info.artist ]
        manager = SessionManager()
        manager!.request(XiamiSearchURL, parameters: params).responseJSON { (response) in
            guard
                response.result.isSuccess,
                let rootArray = response.result.value as? [[String:Any]],
                rootArray.count > 0
                else { return }
            
            self.requestForSongDetail(sequance: rootArray, info: info)
        }
    }
    
    func stopSearch() {
        manager?.session.invalidateAndCancel()
        manager = nil
    }
    
    /// 发起单个查询请求
    private func requestForSongDetail(sequance: [[String:Any]], info: SongBasicInfo) {

        reqRemain = sequance.count
        
        for dic in sequance {
            guard
                let songID = dic["id"] as? String,
                let url = URL(string:String(format: XiamiLyricsURL, songID).urlEncoding)
                else {
                    reqRemain -= 1
                    continue
            }
            
            manager?.request(url).responseData(completionHandler: { (response) in
                self.reqRemain -= 1
                
                guard
                    response.result.isSuccess,
                    let data = response.result.value,
                    let xiamiLyrics = XiamiXMLParser().parse(data: data, info: info)
                    else {
                        self.notifyDelegateIfNeeded(info: info)
                        return
                }
                
                self.lyricsArray.append(xiamiLyrics)
                self.notifyDelegateIfNeeded(info: info)
            })
        }
    }
    
    private func notifyDelegateIfNeeded(info: SongBasicInfo) {
        if reqRemain == 0 {
            let lyricsList = WebLyricsList(lyricsArray, source: .Xiami)
            delegate?.lyricsSource(self, didCompleteWith: lyricsList, songInfo: info)
        }
    }
}
