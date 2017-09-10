//
//  LyricsViewController.swift
//  LyricsX
//
//  Created by Eru on 2017/8/21.
//  Copyright © 2017年 Eru. All rights reserved.
//

import Cocoa

class LyricsViewController: NSViewController {
    
    /// 工具栏
    lazy var toolbar = NSStackView()
    /// 上一首歌
    lazy var previousBtn = NSButton()
    /// 下一首歌
    lazy var nextBtn = NSButton()
    /// 播放/暂停
    lazy var playBtn = NSButton()
    /// 排版方向
    lazy var directionBtn = NSButton()
    /// 罗马音
    lazy var romajiBtn = NSButton()
    /// 翻译
    lazy var translateBtn = NSButton()
    /// 歌词设置
    lazy var settingBtn = NSButton()
    /// 添加歌词
    lazy var addBtn = NSButton()
    /// 歌词错误
    lazy var wrongBtn = NSButton()
    /// 锁定
    lazy var lockBtn = NSButton()
    
    /// 歌词绘制视图
    lazy var lyricsView = LyricsDisplayView()
    
}
