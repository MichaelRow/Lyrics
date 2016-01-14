//
//  ClickView.swift
//  Lyrics
//
//  Created by Eru on 15/12/23.
//  Copyright © 2015年 Eru. All rights reserved.
//

import Cocoa

// This subclass is used to make NSTextField, NSTableView, etc resign first responder

class ClickView: NSView {
    override func mouseDown(theEvent: NSEvent) {
        self.window?.makeFirstResponder(nil)
        super.mouseDown(theEvent)
    }
}
