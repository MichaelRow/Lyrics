//
//  MetaData.swift
//  LyricsX
//
//  Created by Michael Row on 2017/8/6.
//  Copyright © 2017年 Eru. All rights reserved.
//

import Foundation

struct MetaData {
    
    ///歌名 Tag: ti
    private(set) var title: String?
    
    ///歌手名 Tag: ar
    private(set) var artist: String?
    
    ///专辑名 Tag: al
    private(set) var album: String?
    
    ///偏移量 Tag: offset
    private(set) var offset: Int
    
    ///其他信息
    private(set) var otherInfo: [String : String]
    
    init() {
        offset = 0
        otherInfo = [:]
    }
    
    mutating func set(value: String, forKey key: String) {
        switch key.lowercased() {
        case "ti", "title":
            title = value
        case "ar", "artist":
            artist = value
        case "al", "album":
            album = value
        case "offset":
            if let intValue = Int(value) {
                offset = intValue
            }
        default:
            otherInfo[key] = value
        }
    }
}
