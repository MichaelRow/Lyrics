//
//  SongBasicInfo.swift
//  LyricsX
//
//  Created by lialong on 2017/8/16.
//  Copyright © 2017年 Eru. All rights reserved.
//

import Foundation

struct SongBasicInfo: Equatable {
    
    var title: String
    var artist: String
    var album: String?
    var duration: Int?
    
    static func ==(lhs: SongBasicInfo, rhs: SongBasicInfo) -> Bool {
        guard
            lhs.title == rhs.title,
            lhs.artist == rhs.artist
            else { return false }
        
        if
            let la = lhs.album,
            let ra = lhs.album {
            if la != ra {
                return false
            }
        }
        
        if
            let ld = lhs.duration,
            let rd = lhs.duration {
            if ld != rd {
                return false
            }
        }
        
        return true
    }
}
