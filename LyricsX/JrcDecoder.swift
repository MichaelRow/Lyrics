//
//  JrcDecoder.swift
//  LyricsX
//
//  Created by Eru on 2017/8/2.
//  Copyright © 2017年 Eru. All rights reserved.
//

import Cocoa

/// 网易云音乐接口使用的组合歌词解析器
final class JrcDecoder: LyricsDecoder {
    
    static let shared: LyricsDecoder = JrcDecoder()
    
    func decode(_ text: String) -> Lyrics? {
        
        guard
            let data = text.data(using: .utf8),
            let jrcDic = (try? JSONSerialization.jsonObject(with: data, options: .allowFragments)) as? [String : Any]
            else { return nil }
        
        var lyrics: Lyrics?
        
        // 歌词主体
        if
            let kLyricDic = jrcDic["klyric"] as? [String : Any],
            let kLyric = kLyricDic["lyric"] as? String {
            
            lyrics = KLyricDecoder.shared.decode(kLyric)
            
        }
        
        if
            lyrics == nil,
            let lrcDic = jrcDic["lrc"] as? [String : Any],
            let lrc = lrcDic["lyric"] as? String {
            
            lyrics = LrcDecoder.shared.decode(lrc)
        }

        guard lyrics != nil else { return nil }
        
        // 翻译
        if
            let tLyricDic = jrcDic["tlyric"] as? [String : Any],
            let tLyric = tLyricDic["lyric"] as? String {
            translate(lyrics: &lyrics!, tLyrics: tLyric)
        }
        
        return lyrics
    }
    
    func translate(lyrics: inout Lyrics, tLyrics: String) {
        guard let translations = (LrcDecoder.shared as! LrcDecoder).parse(tLyrics)?.timeTrack else { return }
        var sortedTimes = translations.keys.sorted { $0 < $1 }
        for lineIndex in 0 ..< lyrics.lines.count {
            if (lyrics.lines[lineIndex].line.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty) {
                continue
            }
            for timeIndex in 0 ..< sortedTimes.count {
                let time = sortedTimes[timeIndex]
                let trans = translations[time]!
                if (trans.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty) {
                    continue
                }
                if abs(lyrics.lines[lineIndex].begin - time) < 200 {
                    lyrics.translate(line: trans, for: .Chinese, at: lineIndex)
                    sortedTimes.remove(at: timeIndex)
                    break
                }
            }
        }
    }
    
    private init() {}
}


