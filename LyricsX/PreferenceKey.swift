//
//  PreferenceKey.swift
//  LyricsX
//
//  Created by Michael Row on 2017/8/12.
//  Copyright © 2017年 Eru. All rights reserved.
//

import Foundation

struct PreferenceKey<T>: RawRepresentable {
        
    typealias RawValue = String
    
    var rawValue: RawValue

    init(rawValue: RawValue) {
        self.rawValue = rawValue
    }
}

extension PreferenceKey: Identiferable { }
