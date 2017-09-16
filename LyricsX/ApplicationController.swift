//
//  ApplicationController.swift
//  LyricX
//
//  Created by Eru on 2017/3/17.
//  Copyright © 2017年 Eru. All rights reserved.
//

import Cocoa
import MusicPlayer

class ApplicationController: LyricsManagerDelegate, MusicPlayerManagerDelegate {

    private var statusMenu: StatusMenuController
    private var tracker: MusicPlayerManager
    
    let manager = LyricsManager()
    
    init() {
        // code for test
        statusMenu = StatusMenuController()
        statusMenu.setupStatusMenu()
        
        tracker = MusicPlayerManager()
        tracker.add(musicPlayers: [.iTunes, .spotify, .vox])
        tracker.delegate = self
        
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
    
    func manager(_ manager: MusicPlayerManager, trackingPlayer player: MusicPlayer, didChangeTrack track: MusicTrack, atPosition position: TimeInterval) {
        print(player.name.rawValue + " change Track: " + track.title)
    }
    
    func manager(_ manager: MusicPlayerManager, trackingPlayer player: MusicPlayer, playbackStateChanged playbackState: MusicPlaybackState, atPosition position: TimeInterval) {
        switch playbackState {
        case .paused:
            print(player.name.rawValue + " paused")
        case .playing:
            print(player.name.rawValue + " playing")
        case .fastForwarding:
            print(player.name.rawValue + " forward")
        case .rewinding:
            print(player.name.rawValue + " rewind")
        case .stopped:
            print(player.name.rawValue + " stopped")
        }
    }
    
    func manager(_ manager: MusicPlayerManager, trackingPlayerDidQuit player: MusicPlayer) {
        print(player.name.rawValue + " quit")
    }
    
    func manager(_ manager: MusicPlayerManager, trackingPlayerDidChange player: MusicPlayer) {
        print(player.name.rawValue + ": change player")
    }
}
