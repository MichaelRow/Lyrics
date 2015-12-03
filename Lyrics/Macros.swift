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
let LyricsUserEditLyricsNotification:String="LyricsUserEditLyrics"
let LyricsLayoutChangeNotification:String="LyricsLayoutChange"

//Menu
let LyricsIsVerticalLyrics:String="LyricsIsVerticalLyrics"

//General Preferences Defaults
let LyricsSavingPathPopUpIndex:String="LyricsSavingPathPopUpIndex"
let LyricsUserSavingPath:String="LyricsUserSavingPath"
let LyricsAutoLaunches:String="LyricsAutoLaunches"
let LyricsLaunchTpyePopUpIndex:String="LyricsLaunchTpyePopUpIndex"
let LyricsQuitWithITunes:String="LyricsQuitWithITunes"
let LyricsDisableAllAlert:String="LyricsDisableAllAlert"
let LyricsUseAutoLayout:String="LyricsUseAutoLayout"
let LyricsHeightFromDockToLyrics:String="LyricsHeightFromDockToLyrics"
let LyricsConstToLeft:String="LyricsConstToLeft"
let LyricsConstToBottom:String="LyricsConstToBottom"
let LyricsConstWidth:String="LyricsConstWidth"
let LyricsConstHeight:String="LyricsConstHeight"

//Lyrics Preferences Defaults
let LyricsAutoConvertChinese:String="LyricsAutoConvertChinese"
let LyricsVerticalLyricsPosition:String="LyricsVerticalLyricsPosition"
let LyricsChineseTypeIndex:String="LyricsChineseTypeIndex"
let LyricsTwoLineMode:String="LyricsTwoLineMode"
let LyricsDisabledWhenPaused:String="LyricsDisabledWhenPaused"
let LyricsDisabledWhenSreenShot:String="LyricsDisabledWhenSreenShot"
let LyricsSearchForBetterLrc:String="LyricsSearchForBetterLrc"
let LyricsDisplayInAllSpaces:String="LyricsDisplayInAllSpaces"

//Font and Color Preferences Defaults
let LyricsFontName:String="LyricsFontName"
let LyricsFontSize:String="LyricsFontSize"
let LyricsShadowModeEnable:String="LyricsShadowModeEnable"
let LyricsTextColor:String="LyricsTextColor"
let LyricsBackgroundColor:String="LyricsBackgroundColor"
let LyricsShadowColor:String="LyricsShadowColor"
let LyricsShadowRadius:String="LyricsShadowRadius"
