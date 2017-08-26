//
//  iTunesTracker.swift
//  LyricsX
//
//  Created by Eru on 2017/3/20.
//  Copyright © 2017年 Eru. All rights reserved.
//

import Cocoa

class iTunesTracker: Tracker {
    
    weak var delegate: PlayerStatusDelegate?
    private(set) var trackerState: TrackerState
    private var iTunes: iTunesBridge
    private var timer: Timer?
    private var backbroundQueue: DispatchQueue
    
    var identifier: String
    var title: String
    var artist: String
    var album: String
    
    var albumArtwork: Data? {
        return iTunes.artwork()
    }
    
    var playerName: PlayerName {
        return .iTunes
    }
    
    required init?() {
        let _iTunes: iTunesBridge? = iTunesBridge()
        guard _iTunes != nil else { return nil }
        iTunes = _iTunes!
        trackerState = .Stopped
        identifier = ""
        title = ""
        artist = ""
        album = ""
        backbroundQueue = DispatchQueue(label: "LyricsX.iTunes", qos: .background, attributes: .concurrent, autoreleaseFrequency: .inherit, target: nil)
    }
    
    deinit {
        DistributedNotificationCenter.default.removeObserver(self);
    }
    
//MARK: - Public
    
    func startTracking() {
        
        if trackerState != .Stopped {
            return
        }
        trackerState = .EventTracking
        clearSongInfo()
        
        DistributedNotificationCenter.default().addObserver(self, selector: #selector(iTunesPlayerInfoChanged(_:)), name: NSNotification.Name(rawValue: "com.apple.iTunes.playerInfo"), object: nil)
        
        if iTunes.running() && iTunes.playing() {
            setSongInfoFromiTunes()
            if identifier == "" {
                // iTunes在播放AppleMusic，API无法获取歌曲信息
                // 播放暂停使iTunes发送通知，间接获取歌曲信息
                iTunes.pause()
                iTunes.play()
            } else {
                self.delegate?.playerSongDidChange(tracker: self)
                backbroundQueue.async {
                    self.iTunesPlayPositionTracking()
                }
            }
        }
    }
    
    func stopTracking() {
        trackerState = .Stopped
        DistributedNotificationCenter.default.removeObserver(self);
    }
    
    func currentPlayerState() -> PlayerState {
        if let state = PlayerState(rawValue: iTunes.playerState()) {
            return state
        } else {
            return .NotRunning
        }
    }
    
//MARK: - Private

    private func clearSongInfo() {
        identifier = ""
        title = ""
        artist = ""
        album = ""
    }
    
    private func setSongInfoFromiTunes() {
        identifier = iTunes.persistentID()
        title = iTunes.title()
        artist = iTunes.artist()
        album = iTunes.album()
    }
    
    /// 开始监听iTunes播放进度
    private func iTunesPlayPositionTracking() {
        
        if trackerState == .TimeTracking {
            return
        }
        trackerState = .TimeTracking
        
        NSLog("iTunes Tracking Start")
        
        // iTunes每秒更新一次位置，每250ms查询一次减小误差.
        var iTunesPosition: Int = 0
        var currentPosition: Int = 0
        
        // iTunes暂停时结束监听
        while iTunes.playing() && trackerState == .TimeTracking {
            iTunesPosition = iTunes.playerPosition()
            if (currentPosition < iTunesPosition) || ((currentPosition / 1000) != (iTunesPosition / 1000) && currentPosition % 1000 < 750) {
                currentPosition = iTunesPosition
            }
            DispatchQueue.global(qos: .default).async {
                self.delegate?.playerPlaying(tracker: self, msPosition: currentPosition)
            }

            Thread.sleep(forTimeInterval: 0.25)
            currentPosition += 250
        }
        
        DispatchQueue.global(qos: .default).async {
            self.delegate?.playerDidPause(tracker: self);
        }
        
        NSLog("iTunes Tracking Ended")
        trackerState = .EventTracking
    }
    
//MARK: - Notification
    
    @objc func iTunesPlayerInfoChanged(_ notification: Notification) {
        
        guard
            let userInfo = notification.userInfo,
            let playerState = userInfo["Player State"] as? String
            else { return }
        
        switch playerState {
            
        case "Paused":
            //暂停事件在Tracking中处理，不再重复向代理发送事件
            iTunesRunningDelayCheck()
            return
            
        case "Stopped":
            clearSongInfo()
            iTunesRunningDelayCheck()
            self.delegate?.playerDidPause(tracker: self);
            return
            
        case "Playing":
            if trackerState != .TimeTracking {
                backbroundQueue.async {
                    self.iTunesPlayPositionTracking()
                }
            }
            
            // 检查歌曲是否变更
            let oldIdentifier = identifier
            setSongInfoFromiTunes()
            // 处理Apple Music情况，从通知中获取歌曲信息
            if identifier == "" {
                if let newIdentifier = userInfo["PersistentID"] as? Int {
                    identifier = String(newIdentifier)
                }
                if let newTitle = userInfo["Name"] as? String {
                    title = newTitle
                }
                if let newArtist = userInfo["Artist"] as? String {
                    artist = newArtist
                }
                if let newAlbum = userInfo["Album"] as? String {
                    album = newAlbum
                }
            }
            if identifier != oldIdentifier {
                delegate?.playerSongDidChange(tracker: self)
            }
            
        default:
            break
        }
    }

//MARK: - Other
    
    private func iTunesRunningDelayCheck() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(checkiTunesRunning), userInfo: nil, repeats: false)
    }
    
    @objc func checkiTunesRunning() {
        if !iTunes.running() {
            delegate?.playerDidQuit(tracker: self)
        }
    }
    
}
