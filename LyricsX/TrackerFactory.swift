//
//  TrackerFactory.swift
//  LyricsX
//
//  Created by Eru on 2017/8/26.
//  Copyright © 2017年 Eru. All rights reserved.
//

import Foundation

struct TrackerFactory {
    
    static func tracker(with name: PlayerName) -> Tracker? {
        switch name {
        case .iTunes:
            return iTunesTracker()
        case .VOX:
            return VOXTracker()
        }
    }
    
    private init() {}
}
