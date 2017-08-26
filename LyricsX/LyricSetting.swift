//
//  LyricSetting.swift
//  LyricsX
//
//  Created by lialong on 2017/8/15.
//  Copyright © 2017年 Eru. All rights reserved.
//

import Foundation

struct LyricSetting {
    
    /// 偏好翻译
    static let downloadTranslation = PreferenceKey<Bool>(rawValue: "downloadTranslation")
    
    /// 偏好逐字歌词
    static let downloadWordBase = PreferenceKey<Bool>(rawValue: "downloadWordBase")
    
}
