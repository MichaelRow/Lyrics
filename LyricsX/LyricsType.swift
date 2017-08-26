//
//  LyricsType.swift
//  LyricsX
//
//  Created by lialong on 2017/8/13.
//  Copyright © 2017年 Eru. All rights reserved.
//

import Foundation

enum LyricsType: String {
    
    case Lrc = "Lrc"
    case Krc = "Krc"
    case Jrc = "Jrc"
    
    var decoder: LyricsDecoder {
        switch self {
        case .Jrc:
            return JrcDecoder.shared
        case .Krc:
            return KrcDecoder.shared
        case .Lrc:
            return LrcDecoder.shared
        }
    }
    
    var encoder: LyricsEncoder {
        switch self {
        case .Jrc:
            return JrcEncoder.shared
        case .Krc:
            return KrcEncoder.shared
        case .Lrc:
            return LrcEncoder.shared
        }
    }
}
