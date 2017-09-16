//
//  QianqianSource.swift
//  LyricsX
//
//  Created by Eru on 2017/7/1.
//  Copyright © 2017年 Eru. All rights reserved.
//

import Cocoa
import Alamofire
import OpenCCSwift

/// 千千静听(电信)
private let QianqianSearchURLCT = "http://ttlrcct.qianqian.com/dll/lyricsvr.dll?sh?Artist=%@&Title=%@&Flags=0"
/// 千千静听(联通)
private let QianqianSearchURLCU = "http://ttlrccnc.qianqian.com/dll/lyricsvr.dll?sh?Artist=%@&Title=%@&Flags=0"
private let HexChar: [UInt8] = [41, 42, 43, 44, 45, 46]

class QianqianSource:LyricsSource {
    
    weak var delegate: LyricsSourceDelegate?
    private var request: DataRequest?
    var searchURL: String!
    
    var name: LyricsSourceName {
        return .Qianqian
    }
    
    init() {
        loadServer()
    }
    
    private func loadServer() {
        let index = UserDefaults.standard[GeneralSetting.qianqianServer]
        searchURL = index == 0 ? QianqianSearchURLCT : QianqianSearchURLCU
    }
    
    func startSearch(info: SongBasicInfo) {
        
        stopSearch()
        
        guard let coverter = ChineseConverter(Simplize.default) else { return }
        let titleSC_NoSpace = coverter.convert(string: info.title).replacingOccurrences(of: " ", with: "")
        let artistSC_NoSpace = coverter.convert(string: info.artist).replacingOccurrences(of: " ", with: "")
        
        guard let hexTitle = QianqianDecrypt.hexEncodedString(titleSC_NoSpace),
              let hexArtist = QianqianDecrypt.hexEncodedString(artistSC_NoSpace)
        else { return }
        
        let url = String(format: searchURL, hexArtist, hexTitle)
        
        request = Alamofire.request(url)
        request!.responseData { (response) in
            guard
                response.result.isSuccess,
                let data = response.result.value
                else { return }
            
            let webLyrics = QianqianXMLParser().parse(lyricsData: data, info: info)

            let lyricsList = WebLyricsList(webLyrics, source: .Qianqian)
            self.delegate?.lyricsSource(self, didCompleteWith: lyricsList, songInfo: info)
        }
    }
    
    func stopSearch() {
        request?.cancel()
    }    
}
