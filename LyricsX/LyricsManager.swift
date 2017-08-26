//
//  LyricsManager.swift
//  LyricsX
//
//  Created by Michael Row on 2017/8/12.
//  Copyright © 2017年 Eru. All rights reserved.
//

import Cocoa

class LyricsManager {
    
    var currentSearchInfo: SongBasicInfo?
    
    var currentLyrics: Lyrics?
    
    weak var delegate: LyricsManagerDelegate?
    
    fileprivate var sources: [LyricsSource]

    fileprivate var webLyrics: [WebLyricsList]
    
    fileprivate var handleQueue: DispatchQueue
    
    init() {
        sources = []
        webLyrics = []
        handleQueue = DispatchQueue(label: "LyricsX.SourceManager", qos: .default, attributes: .init(rawValue: 0), autoreleaseFrequency: .inherit, target: nil)
    }
    
    /// 添加歌词源
    ///
    /// - Parameters:
    ///   - source: 歌词源
    func add(source name: LyricsSourceName) {
        for src in sources {
            guard src.name != name else { return }
        }
        let source = LyricsSourceFactory.source(with: name)
        source.delegate = self
        sources.append(source)
    }
    
    /// 移除歌词源
    ///
    /// - Parameters:
    ///   - source: 歌词源名称
    func remove(source name: LyricsSourceName) {
        for index in 0 ..< sources.count {
            let source = sources[index]
            
            if source.name == name {
                source.stopSearch()
                sources.remove(at: index)
            }
        }
    }
    
    /// 开始搜索
    func startSearch(info: SongBasicInfo) {
        currentSearchInfo = info
        webLyrics.removeAll()
        for source in sources {
            source.startSearch(info: info)
        }
    }
    
    /// 停止搜索
    func stopSearch() {
        for source in sources {
            source.stopSearch()
        }
    }
    
    /// 在歌词list中挑选
    fileprivate func pickLyrics(in list: WebLyricsList) {
        // list中是否还有未处理歌词
        guard let webLyrics = list.defaultIterator.next() else { return }
        // 在已经有歌词并且当前list无详细歌词的时候结束挑选
        let hasDetail = list.sourceName.supportWordBase || list.sourceName.supportTranslation
        if currentLyrics != nil && !hasDetail {
            return
        }
        
        webLyrics.lyrics { lyrics in
            guard lyrics != nil else {
                self.pickLyrics(in: list)
                return
            }
            
            self.handleQueue.async {
                if self.handle(lyrics: lyrics!, in: list) {
                    DispatchQueue.global(qos: .default).async {
                        self.pickLyrics(in: list)
                    }
                }
            }
        }
    }
    
    /// 处理并替换使用符合条件的歌词
    ///
    /// - Parameter lyrics: 歌词
    /// - Returns: 是否需要继续遍历
    fileprivate func handle(lyrics: Lyrics, in list: WebLyricsList) -> Bool {
        // 如果没有歌词
        if currentLyrics == nil {
            currentLyrics = lyrics
            delegate?.lyricsManager(self, didUpdate: lyrics)
            return quantization(with: lyrics).match == 1
        }
        
        let newQtz = quantization(with: lyrics)
        let oldQtz = quantization(with: currentLyrics!)
        
        if newQtz.match > oldQtz.match {
            currentLyrics = lyrics
            delegate?.lyricsManager(self, didUpdate: lyrics)
            return newQtz.match == 1

        } else if newQtz.match == oldQtz.match && newQtz.totoal > oldQtz.match {
            currentLyrics = lyrics
            delegate?.lyricsManager(self, didUpdate: lyrics)
            return newQtz.match == 1
        }
        
        return oldQtz.match == 1
    }
    
    /// 根据一些条件量化歌词的好坏详细程度
    ///
    /// - Parameter lyrics: 歌词
    /// - Returns: 总量化值与符合用户要求的量化值
    fileprivate func quantization(with lyrics: Lyrics) -> (totoal: Double, match: Double) {
        
        var totoal = 0.0
        var match = 0.0
        
        let downloadTrans = true//UserDefaults.standard[LyricSetting.downloadTranslation]
        let downloadWordBase = true//UserDefaults.standard[LyricSetting.downloadWordBase]
        let count = 2.0;
        
        var lyricsTrans = false
        var lyricsWordBase = false
        
        if lyrics.translationLanguages.count > 0 {
            lyricsTrans = true
            totoal += 1
        }
        if lyrics.type == .Word {
            lyricsWordBase = true
            totoal += 1
        }
        
        if lyricsTrans || lyricsTrans == downloadTrans {
            match += 1
        }
        if lyricsWordBase || lyricsWordBase == downloadWordBase {
            match += 1
        }
        
        return (totoal/count, match/count)
    }
}

extension LyricsManager: LyricsSourceDelegate {
    
    func lyricsSource(_ source: LyricsSource, didCompleteWith list: WebLyricsList, songInfo: SongBasicInfo) {
        guard songInfo == currentSearchInfo else { return }
        pickLyrics(in: list)
    }
}

