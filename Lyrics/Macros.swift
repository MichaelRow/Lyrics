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
let LyricsSavingPathPopUpIndex:String="LyricsSavingPathPopUpIndex"
let LyricsUserSavingPath:String="LyricsUserSavingPath"
let LyricsQuitWithITunes:String="LyricsQuitWithITunes"
let LyricsDisabledWhenPaused:String="LyricsDisabledWhenPaused"
let LyricsDisabledWhenSreenShot:String="LyricsDisabledWhenSreenShot"

let LyricsTwoLineMode:String="LyricsTwoLineMode"
let LyricsSearchForBetterLrc:String="LyricsSearchForBetterLrc"
let LyricsDisplayInAllSpaces:String="LyricsDisplayInAllSpaces"
let LyricsUseAutoLayout:String="LyricsUseAutoLayout"
let LyricsHeightFromDockToLyrics:String="LyricsHeightFromDockToLyrics"
let LyricsConstToLeft:String="LyricsConstToLeft"
let LyricsConstToBottom:String="LyricsConstToBottom"
let LyricsConstWidth:String="LyricsConstWidth"
let LyricsConstHeight:String="LyricsConstHeight"

let LyricsFontName:String="LyricsFontName"
let LyricsFontSize:String="LyricsFontSize"
let LyricsShadowModeEnable:String="LyricsShadowModeEnable"
let LyricsTextColor:String="LyricsTextColor"
let LyricsBackgroundColor:String="LyricsBackgroundColor"
let LyricsShadowColor:String="LyricsShadowColor"
let LyricsShadowRadius:String="LyricsShadowRadius"

