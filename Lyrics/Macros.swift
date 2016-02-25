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
let LyricsUserEditLyricsNotification:String="LyricsUserEditLyrics"
let LyricsPresetDidChangedNotification:String="LyricsPresetDidChanged"

//Menu
let LyricsDesktopLyricsEnabled:String="LyricsDesktopLyricsEnabled"
let LyricsMenuBarLyricsEnabled:String="LyricsMenuBarLyricsEnabled"
let LyricsIsVerticalLyrics:String="LyricsIsVerticalLyrics"

//General Preferences Defaults
let LyricsSavingPathPopUpIndex:String="LyricsSavingPathPopUpIndex"
let LyricsUserSavingPath:String="LyricsUserSavingPath"
let LyricsAutoLaunches:String="LyricsAutoLaunches"
let LyricsLaunchTpyePopUpIndex:String="LyricsLaunchTpyePopUpIndex"
let LyricsServerIndex:String="LyricsServerIndex"
let LyricsQuitWithITunes:String="LyricsQuitWithITunes"
let LyricsDisableAllAlert:String="LyricsDisableAllAlert"
let LyricsUseAutoLayout:String="LyricsUseAutoLayout"
let LyricsHeightFromDockToLyrics:String="LyricsHeightFromDockToLyrics"
let LyricsConstWidth:String="LyricsConstWidth"
let LyricsConstHeight:String="LyricsConstHeight"

//Lyrics Preferences Defaults
let LyricsAutoConvertChinese:String="LyricsAutoConvertChinese"
let LyricsVerticalLyricsPosition:String="LyricsVerticalLyricsPosition"
let LyricsChineseTypeIndex:String="LyricsChineseTypeIndex"
let LyricsTwoLineMode:String="LyricsTwoLineMode"
let LyricsTwoLineModeIndex:String="LyricsTwoLineModeIndex"
let LyricsDisabledWhenPaused:String="LyricsDisabledWhenPaused"
let LyricsDisabledWhenSreenShot:String="LyricsDisabledWhenSreenShot"
let LyricsSearchForDiglossiaLrc:String="LyricsSearchForDiglossiaLrc"
let LyricsDisplayInAllSpaces:String="LyricsDisplayInAllSpaces"

//Font and Color Preferences Defaults
let LyricsFontName:String="LyricsFontName"
let LyricsFontSize:String="LyricsFontSize"
let LyricsShadowModeEnable:String="LyricsShadowModeEnable"
let LyricsTextColor:String="LyricsTextColor"
let LyricsBackgroundColor:String="LyricsBackgroundColor"
let LyricsShadowColor:String="LyricsShadowColor"
let LyricsShadowRadius:String="LyricsShadowRadius"
let LyricsBgHeightINCR:String="LyricsBgHeightINCR"
let LyricsYOffset:String="LyricsYOffset"

//Shortcut
let ShortcutLyricsModeSwitch:String="ShortcutLyricsModeSwitch"
let ShortcutDesktopMenubarSwitch:String="ShortcutDesktopMenubarSwitch"
let ShortcutOpenLrcSeeker:String="ShortcutOpenLrcSeeker"
let ShortcutCopyLrcToPb:String="ShortcutCopyLrcToPb"
let ShortcutEditLrc:String="ShortcutEditLrc"
let ShortcutMakeLrc:String="ShortcutMakeLrc"
let ShortcutWriteLrcToiTunes:String="ShortcutWriteLrcToiTunes"
