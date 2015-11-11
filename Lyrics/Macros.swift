//
//  Macros.swift
//  Lyrics
//
//  Created by Eru on 15/11/6.
//  Copyright © 2015年 Eru. All rights reserved.
//

import Foundation

//disable NSLog all over the codes in release builds
#if !DEBUG
    func NSLog(format: String, _ args: CVarArgType...) {}
#endif

//Notifications
let LyricsAttributesChangedNotification:String="LyricsAttributesChanged"

//User Defaults
let LyricsQuitWithITunes:String="LyricsQuitWithITunes"
let LyricsDisabledWhenPaused:String="LyricsDisabledWhenPaused"
let LyricsDisabledWhenSreenShot:String="LyricsDisabledWhenSreenShot"
let LyricsTextColor:String="LyricsTextColor"
let LyricsBackgroundColor:String="LyricsBackgroundColor"
let LyricsShadowColor:String="LyricsShadowColor"
let LyricsShadowRadius:String="LyricsShadowRadius"
let LyricsShadowModeEnable:String="LyricsShadowModeEnable"
let LyricsTwoLineMode:String="LyricsTwoLineMode"
let LyricsDisplayInAllSpaces:String="LyricsDisplayInAllSpaces"
let LyricsAutoAdjustWithDock:String="LyricsAutoAdjustWithDock"
let LyricsHeightFromDockToLyrics:String="LyricsHeightFromDockToLyrics"