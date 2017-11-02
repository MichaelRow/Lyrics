//
//  ApplicationController.swift
//  LyricX
//
//  Created by Eru on 2017/3/17.
//  Copyright © 2017年 Eru. All rights reserved.
//

import Cocoa
import MusicPlayer
import LyricsService

class ApplicationController: MusicPlayerManagerDelegate {

    private var statusMenu: StatusMenuController
    private var tracker: MusicPlayerManager
    
    let manager = LyricsSourceManager()
    
    init() {
        // code for test
        statusMenu = StatusMenuController()
        statusMenu.setupStatusMenu()
        
        tracker = MusicPlayerManager()
        tracker.delegate = self
        tracker.add(musicPlayers: [.iTunes, .spotify, .vox])
        
        let info = SearchInfo(title:"only my railgun", artist:"fripside", duration:257000)
        manager.add(sourceNames: [.Gecimi,.Kugou,.NetEase,.Qianqian,.QQMusic,.TTPod,.Xiami])
        manager.searchLyrics(with: info, inProgress: { (lyrics) in
            print(lyrics.lyricsValue)
        }) { (allLyrics, error) in
            print(allLyrics.count)
        }
    }
    
    func manager(_ manager: MusicPlayerManager, trackingPlayer player: MusicPlayer, didChangeTrack track: MusicTrack, atPosition position: TimeInterval) {
        print(player.name.rawValue + " change Track: " + track.title)
    }
    
    func manager(_ manager: MusicPlayerManager, trackingPlayer player: MusicPlayer, playbackStateChanged playbackState: MusicPlaybackState, atPosition position: TimeInterval) {
        print("\(player.name.rawValue) \(playbackState)")
    }
    
    func manager(_ manager: MusicPlayerManager, trackingPlayerDidQuit player: MusicPlayer) {
        print(player.name.rawValue + " quit")
    }
    
    func manager(_ manager: MusicPlayerManager, trackingPlayerDidChange player: MusicPlayer) {
        print(player.name.rawValue + ": change player")
    }
}
