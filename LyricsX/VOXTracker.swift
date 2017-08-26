//
//  VOXTracker.swift
//  LyricsX
//
//  Created by Eru on 2017/4/1.
//  Copyright © 2017年 Eru. All rights reserved.
//

import Cocoa

class VOXTracker: Tracker {
    
    weak var delegate: PlayerStatusDelegate?
    private(set) var trackerState: TrackerState
    private var vox: VOXBridge
    private var backbroundQueue: DispatchQueue
    private var isTrackingInBackground: Bool
    
    var identifier: String
    
    var title: String {
        return vox.title()
    }
    
    var artist: String {
        return vox.artist()
    }
    
    var album: String {
        return vox.album()
    }
    
    var albumArtwork: Data? {
        return vox.artwork()
    }
    
    var playerName: PlayerName {
        return .VOX
    }
    
    required init?() {
        let _vox: VOXBridge? = VOXBridge()
        guard _vox != nil else { return nil }
        vox = _vox!
        trackerState = .Stopped
        identifier = ""
        backbroundQueue = DispatchQueue(label: "LyricsX.VOX", qos: .background, attributes: .concurrent, autoreleaseFrequency: .inherit, target: nil)
        isTrackingInBackground = false        
    }
    
    deinit {
        trackerState = .Stopped
        DistributedNotificationCenter.default.removeObserver(self);
    }
    
    //MARK: - Public
    
    func startTracking() {
        
        if isTrackingInBackground {
            return
        }
        trackerState = .EventTracking
        
        DistributedNotificationCenter.default().addObserver(self, selector: #selector(voxPlayerInfoChanged(_:)), name: NSNotification.Name(rawValue: "com.coppertino.Vox.trackChanged"), object: nil)
        
        if vox.running() && vox.playing() {
            identifier = vox.uniqueID()
            self.delegate?.playerSongDidChange(tracker: self)
        } else {
            identifier = ""
        }
        
        backbroundQueue.async {
            self.voxPlayPositionTracking()
        }
    }
    
    func stopTracking() {
        trackerState = .Stopped
        DistributedNotificationCenter.default.removeObserver(self);
    }
    
    func currentPlayerState() -> PlayerState {
        if let state = PlayerState(rawValue: vox.playerState()) {
            return state
        } else {
            return .NotRunning
        }
    }
    
    //MARK: - Private
    
    /// 开始监听vox播放进度
    private func voxPlayPositionTracking() {
        
        if isTrackingInBackground {
            return
        }
        isTrackingInBackground = true
        
        var playerState: PlayerState = .NotRunning
        NSLog("VOX Tracking Start")
        
        while trackerState != .Stopped {
    
            if !vox.running() {
                if playerState != .NotRunning {
                    playerState = .NotRunning
                    trackerState = .EventTracking
                    DispatchQueue.global(qos: .default).async {
                        self.delegate?.playerDidQuit(tracker: self)
                    }
                }
            } else if !vox.playing() {
                if playerState != .Paused {
                    playerState = .Paused
                    trackerState = .EventTracking
                    DispatchQueue.global(qos: .default).async {
                        self.delegate?.playerDidPause(tracker: self)
                    }
                }
            } else {
                if playerState != .Playing {
                    playerState = .Playing
                    trackerState = .TimeTracking
                }
                
                DispatchQueue.global(qos: .default).async {
                    self.delegate?.playerPlaying(tracker: self, msPosition: self.vox.playerPosition())
                }
            }
            
            Thread.sleep(forTimeInterval: 0.5)
        }
        
        NSLog("VOX Tracking Ended")
        isTrackingInBackground = false
        self.delegate?.playerDidPause(tracker: self);
    }
    
    //MARK: - Notification
    
    @objc func voxPlayerInfoChanged(_ notification: Notification) {
        
        let oldIdentifier = identifier
        identifier = vox.uniqueID()
        
        if oldIdentifier != identifier {
            delegate?.playerSongDidChange(tracker: self)
        }
    }
    
}
