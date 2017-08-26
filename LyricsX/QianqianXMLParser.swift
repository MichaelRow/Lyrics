//
//  QianqianXMLParser.swift
//  LyricsX
//
//  Created by Eru on 2017/7/1.
//  Copyright © 2017年 Eru. All rights reserved.
//

import Cocoa

/// 歌词获取地址（电信）
private let QianqianGetLyricsURLCT = "http://ttlrcct.qianqian.com/dll/lyricsvr.dll?dl?Id=%@&Code=%@"
/// 歌词获取地址（联通）
private let QianqianGetLyricsURLCU = "http://ttlrccnc.qianqian.com/dll/lyricsvr.dll?dl?Id=%@&Code=%@"

class QianqianXMLParser: NSObject {
    
    fileprivate var qianqianLyrics: [WebLyrics]
    fileprivate var info: SongBasicInfo!
    fileprivate var qianqianGetLyricsURL: String!
    
    override init() {
        qianqianLyrics = []
        super.init()
        
        loadServer()
    }
    
    func parse(lyricsData: Data, info: SongBasicInfo) -> [WebLyrics] {
        self.info = info
        qianqianLyrics.removeAll()
        
        let xmlParser = XMLParser(data: lyricsData)
        xmlParser.delegate = self
        xmlParser.parse()
        return qianqianLyrics
    }
    
    private func loadServer() {
        let index = UserDefaults.standard[GeneralSetting.qianqianServer]
        qianqianGetLyricsURL = index == 0 ? QianqianGetLyricsURLCT : QianqianGetLyricsURLCU
    }
    
}

//MARK: XMLParserDelegate

extension QianqianXMLParser: XMLParserDelegate {
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        
        guard
            elementName == "lrc",
            let songID = attributeDict["id"],
            let artist = attributeDict["artist"],
            let title = attributeDict["title"],
            let accessKey = QianqianDecrypt.accessCode(withArtist: artist, title: title, songID: Int(songID)!)
            else { return }
        
        let url = String(format: qianqianGetLyricsURL, songID, accessKey)
        
        let dic = [ "artist" : artist,
                    "title"  : title,
                    "url"    : url ]
        
        guard let webLyrics = QianqianWebLyrics.webLyrics(info: info, dic: dic) else { return }
        qianqianLyrics.append(webLyrics)
    }
}
