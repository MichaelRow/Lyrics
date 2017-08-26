//
//  ApplicationController.swift
//  LyricX
//
//  Created by Eru on 2017/3/17.
//  Copyright © 2017年 Eru. All rights reserved.
//

import Cocoa

class ApplicationController: NSObject, LyricsManagerDelegate {

    private var statusMenu: StatusMenuController
    private var tracker: TrackerManager
    
    let manager = LyricsManager()
    
    override init() {
        // code for test
        statusMenu = StatusMenuController()
        statusMenu.setupStatusMenu()
        tracker = TrackerManager()
        tracker.add(player: .iTunes, priority: .High, shouldStart: true)
        tracker.add(player: .VOX, priority: .High, shouldStart: true)

        super.init()
        
        manager.delegate = self
        let info = SongBasicInfo(title: "only my railgun", artist: "fripside", album: nil, duration: 257000)
        manager.add(source: .Gecimi)
        manager.add(source: .QQMusic)
        manager.add(source: .Kugou)
        manager.add(source: .Qianqian)
        manager.add(source: .NetEase)
        manager.add(source: .TTPod)
        manager.add(source: .Xiami)
        manager.startSearch(info: info)
    }
    
    func lyricsManager(_ manager: LyricsManager, didUpdate lyrics: Lyrics) {
        print(lyrics)
    }
}
