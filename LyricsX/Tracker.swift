//
//  Tracker.swift
//  LyricsX
//
//  Created by Eru on 2017/3/20.
//  Copyright © 2017年 Eru. All rights reserved.
//

import Foundation


enum PlayerState: Int {
    
    case NotRunning = 0
    
    case Playing = 1
    
    case Paused = 2
    
    case Stopped = 3
}


enum TrackerState {
    
    /// 跟踪播放时间（当前正在播放）
    case TimeTracking
    
    /// 等待播放事件（播放器不在播放）
    case EventTracking
    
    /// 停止跟踪
    case Stopped
}

enum PlayerName: String, RawRepresentable {
    
    typealias RawValue = String
    
    case iTunes = "iTunes"
    
    case VOX = "VOX"
}

protocol Tracker: class {
    
    init?()
    
    weak var delegate: PlayerStatusDelegate? { get set }
    
    /// 播放中的歌曲
    var title: String {get}
    
    /// 播放中的歌手名
    var artist: String {get}
    
    /// 播放中的专辑名
    var album: String {get}
    
    /// 播放中的歌曲标识
    var identifier: String {get}
    
    /// 播放中的专辑封面
    var albumArtwork: Data? {get}
    
    /// 播放器名称
    var playerName: PlayerName {get}
    
    /// 播放器当前状态
    func currentPlayerState() -> PlayerState
    
    /// 开始监听播放器
    func startTracking()
    
    /// 停止监听播放器
    func stopTracking()
}
