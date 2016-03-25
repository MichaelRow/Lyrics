//
//  LyricsEditView.swift
//  Lyrics
//
//  Created by Eru on 15/11/24.
//  Copyright © 2015年 Eru. All rights reserved.
//

import Cocoa

// http://stackoverflow.com/questions/36156712/the-selector-keyword-has-been-deprecated-in-future-versions-of-swift-how-can-i

@objc protocol UndoActionRespondable {
    func undo(sender: AnyObject)
    func redo(sender: AnyObject)
}

class LyricsEditView: NSTextView {

    private let commandKey = NSEventModifierFlags.CommandKeyMask.rawValue
    private let commandShiftKey = NSEventModifierFlags.CommandKeyMask.rawValue | NSEventModifierFlags.ShiftKeyMask.rawValue
    
    override func performKeyEquivalent(event: NSEvent) -> Bool {
        if event.type == NSEventType.KeyDown {
            if (event.modifierFlags.rawValue & NSEventModifierFlags.DeviceIndependentModifierFlagsMask.rawValue) == commandKey {
                switch event.charactersIgnoringModifiers! {
                case "x":
                    if NSApp.sendAction(#selector(NSText.cut(_:)), to:nil, from:self) {
                        return true
                    }
                case "c":
                    if NSApp.sendAction(#selector(NSText.copy(_:)), to:nil, from:self) {
                        return true
                    }
                case "v":
                    if NSApp.sendAction(#selector(NSText.paste(_:)), to:nil, from:self) {
                        return true
                    }
                case "z":
                    if NSApp.sendAction(#selector(UndoActionRespondable.undo(_:)), to:nil, from:self) {
                        return true
                    }
                case "a":
                    if NSApp.sendAction(#selector(NSResponder.selectAll(_:)), to:nil, from:self) {
                        return true
                    }
                case "w":
                    self.window?.close()
                    return true
                default:
                    break
                }
            }
            else if (event.modifierFlags.rawValue & NSEventModifierFlags.DeviceIndependentModifierFlagsMask.rawValue) == commandShiftKey {
                if event.charactersIgnoringModifiers == "Z" {
                    if NSApp.sendAction(#selector(UndoActionRespondable.redo(_:)), to:nil, from:self) { return true }
                }
            }
        }
        return super.performKeyEquivalent(event)
    }
    
    override func paste(sender: AnyObject?) {
        self.pasteAsPlainText(sender)
    }
    
}
