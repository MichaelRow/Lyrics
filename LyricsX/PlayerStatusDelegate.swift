//
//  PlayerStatusDelegate.swift
//  LyricsX
//
//  Created by Eru on 2017/3/20.
//  Copyright © 2017年 Eru. All rights reserved.
//

import Foundation

protocol PlayerStatusDelegate: class {
    
    /// 播放器当前播放中的歌曲变化
    ///
    /// - Parameters:
    ///   - player: 当前播放器，可以通过player获取当前歌曲信息
    func playerSongDidChange(tracker:Tracker)
    
    /// 播放器位置更新
    ///
    /// - Parameters:
    ///   - msPosition: 当前播放的位置（ms）
    func playerPlaying(tracker:Tracker, msPosition:Int)
    
    /// 播放器暂停或停止
    func playerDidPause(tracker:Tracker)
    
    /// 播放器退出
    func playerDidQuit(tracker:Tracker)
}
