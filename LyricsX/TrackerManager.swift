//
//  TrackerManager.swift
//  LyricsX
//
//  Created by Eru on 2017/4/1.
//  Copyright © 2017年 Eru. All rights reserved.
//

import Cocoa

class TrackerManager: NSObject {

    enum Priority: Int {
        case Low     = 1
        case Default = 2
        case High    = 3
    }
    
    fileprivate var currentTracker: Tracker?
    fileprivate var trackers: [Tracker]
    fileprivate var trackerPriority: [PlayerName : Priority]
    
    override init() {
        trackerPriority = Dictionary()
        trackers = []
        super.init()
    }

//MARK: Public
    
    /// 添加播放器
    ///
    /// - Parameters:
    ///   - tracker: 播放器
    ///   - priority: 优先级
    ///   - shouldStart: 是否直接开始监听
    func add(player name:PlayerName, priority:Priority, shouldStart:Bool) {
        for existTracker in trackers {
            if existTracker.playerName == name {
                return
            }
        }
        
        guard let tracker = TrackerFactory.tracker(with: name) else { return }
        tracker.delegate = self
        trackers.append(tracker)
        trackerPriority.updateValue(priority, forKey: tracker.playerName)
        
        if shouldStart {
            tracker.startTracking()
            if currentTracker == nil {
                currentTracker = tracker
            }
        }
    }
    
    /// 移除播放器
    ///
    /// - Parameter trackerName: 播放器名称
    func remove(tracker trackerName:PlayerName) {
        let index = trackers.index(where: { (tracker) -> Bool in
            return tracker.playerName == trackerName
        })
        guard index != nil else { return }
        trackers.remove(at: index!)
        trackerPriority.removeValue(forKey: trackerName)
        
        if currentTracker != nil && currentTracker!.playerName == trackerName {
            currentTracker = nil;
        }
    }
    
    /// 改变指定播放器监听状态
    ///
    /// - Parameters:
    ///   - names: 播放器名称
    ///   - startTrack: true开始监听, false停止监听
    func trackers(_ trackerNames:[PlayerName], startTrack: Bool) {
        for name in trackerNames {
            guard let tracker = tracker(from: name) else { continue }
            if startTrack {
                tracker.startTracking()
                if currentTracker == nil {
                    currentTracker = tracker
                }
            } else {
                tracker.stopTracking()
                if currentTracker != nil && currentTracker!.playerName == name {
                    currentTracker = nil;
                }
            }
        }
    }
    
    /// 改变播放器的监听优先级
    ///
    /// - Parameters:
    ///   - priority: 监听优先级
    ///   - player: 播放器
    func change(priority: Priority, forTracker name: PlayerName) {
        guard tracker(from: name) != nil else {
            return
        }
        trackerPriority.updateValue(priority, forKey:name)
    }
    
//MARK: Private
    
    private func tracker(from name: PlayerName) -> Tracker? {
        for tracker in trackers {
            if tracker.playerName == name {
                return tracker
            }
        }
        return nil
    }
}

//MARK: -

extension TrackerManager: PlayerStatusDelegate {
    
    func playerSongDidChange(tracker: Tracker) {
        if !shouldHandleTrackerEvent(tracker) {
            return
        }
        
        NSLog("%@:%@", tracker.playerName.rawValue, tracker.title)
    }
    
    func playerPlaying(tracker: Tracker, msPosition: Int) {
        if !shouldHandleTrackerEvent(tracker) {
            return
        }
    }
    
    func playerDidPause(tracker: Tracker) {
        if !shouldHandleTrackerEvent(tracker) {
            return
        }
        
        NSLog("%@ Pause", tracker.playerName.rawValue)
    }
    
    func playerDidQuit(tracker: Tracker) {
        if currentTracker == nil {
            currentTracker = tracker
        }
        if currentTracker!.playerName != tracker.playerName {
            return
        }
        
        NSLog("%@ Quit", tracker.playerName.rawValue)
    }
    
    /// 检查是否需要响应当前的播放器事件，并更新跟踪的播放器
    ///
    /// - Returns: 是否需要响应事件
    private func shouldHandleTrackerEvent(_ tracker: Tracker) -> Bool {
        
        if currentTracker == nil {
            currentTracker = tracker
            return true
        }
        
        if currentTracker!.playerName == tracker.playerName {
            return true
        }
        
        if currentTracker!.currentPlayerState() != .Playing {
            currentTracker = tracker
            return true
        } else {
            guard let oldPriority = trackerPriority[currentTracker!.playerName] else { return false }
            guard let newPriority = trackerPriority[tracker.playerName] else { return false }
            if newPriority.rawValue > oldPriority.rawValue {
                currentTracker = tracker
                return true
            } else {
                return false
            }
        }
    }
}
