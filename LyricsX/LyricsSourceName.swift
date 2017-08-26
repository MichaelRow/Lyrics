//
//  LyricsSourceName.swift
//  LyricsX
//
//  Created by Eru on 2017/7/26.
//  Copyright © 2017年 Eru. All rights reserved.
//

import Foundation

enum LyricsSourceName: String, RawRepresentable {
    
    typealias RawValue = String
    
    case NetEase = "网易云音乐"
    
    case QQMusic = "QQ音乐"
    
    case TTPod = "天天动听"
    
    case Gecimi = "歌词迷"
    
    case Xiami = "虾米音乐"
    
    case Qianqian = "千千静听"
    
    case Kugou = "酷狗音乐"
    
    /// 该歌词源是否支持逐字歌词
    var supportWordBase: Bool {
        switch self {
        case .NetEase, .Kugou:
            return true
        default:
            return false
        }
    }
    
    /// 该歌词源是否支持翻译
    var supportTranslation: Bool {
        switch self {
        case .NetEase, .Kugou:
            return true
        default:
            return  false
        }
    }
}
