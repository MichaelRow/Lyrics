//
//  AppPrefsWC+Shortcut.swift
//  Lyrics
//
//  Created by Eru on 16/1/13.
//  Copyright © 2016年 Eru. All rights reserved.
//

import Cocoa

extension AppPrefsWindowController {
    func setupShortcuts() {
        let appController = AppController.sharedAppController
        // User shortcuts
        lyricsModeSwitchShortcut.associatedUserDefaultsKey = ShortcutLyricsModeSwitch
        MASShortcutBinder.sharedBinder().bindShortcutWithDefaultsKey(ShortcutLyricsModeSwitch) { () -> Void in
            appController.changeLyricsMode(nil)
        }
        desktopMenubarSwitchShortcut.associatedUserDefaultsKey = ShortcutDesktopMenubarSwitch
        MASShortcutBinder.sharedBinder().bindShortcutWithDefaultsKey(ShortcutDesktopMenubarSwitch) { () -> Void in
            appController.switchDesktopMenuBarMode()
        }
        lrcSeekerShortcut.associatedUserDefaultsKey = ShortcutOpenLrcSeeker
        MASShortcutBinder.sharedBinder().bindShortcutWithDefaultsKey(ShortcutOpenLrcSeeker) { () -> Void in
            appController.searchLyricsAndArtworks(nil)
        }
        copyLrcToPbShortcut.associatedUserDefaultsKey = ShortcutCopyLrcToPb
        MASShortcutBinder.sharedBinder().bindShortcutWithDefaultsKey(ShortcutCopyLrcToPb) { () -> Void in
            appController.copyLyricsToPb(nil)
        }
        editLrcShortcut.associatedUserDefaultsKey = ShortcutEditLrc
        MASShortcutBinder.sharedBinder().bindShortcutWithDefaultsKey(ShortcutEditLrc) { () -> Void in
            appController.editLyrics(nil)
        }
        makeLrcShortcut.associatedUserDefaultsKey = ShortcutMakeLrc
        MASShortcutBinder.sharedBinder().bindShortcutWithDefaultsKey(ShortcutMakeLrc) { () -> Void in
            appController.makeLrc(nil)
        }
        writeLrcToiTunesShortcut.associatedUserDefaultsKey = ShortcutWriteLrcToiTunes
        MASShortcutBinder.sharedBinder().bindShortcutWithDefaultsKey(ShortcutWriteLrcToiTunes) { () -> Void in
            appController.writeLyricsToiTunes(nil)
        }
        // Hard-Coded shortcuts
        let offsetIncr: MASShortcut = MASShortcut(keyCode: UInt(kVK_ANSI_Equal), modifierFlags: NSEventModifierFlags.CommandKeyMask.rawValue | NSEventModifierFlags.AlternateKeyMask.rawValue)
        MASShortcutMonitor.sharedMonitor().registerShortcut(offsetIncr) { () -> Void in
            appController.increaseTimeDly()
        }
        let offsetDecr: MASShortcut = MASShortcut(keyCode: UInt(kVK_ANSI_Minus), modifierFlags: NSEventModifierFlags.CommandKeyMask.rawValue | NSEventModifierFlags.AlternateKeyMask.rawValue)
        MASShortcutMonitor.sharedMonitor().registerShortcut(offsetDecr) { () -> Void in
            appController.decreaseTimeDly()
        }
    }

}
