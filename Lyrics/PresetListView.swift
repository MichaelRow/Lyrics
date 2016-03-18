//
//  PresetListView.swift
//  Lyrics
//
//  Created by Eru on 16/1/14.
//  Copyright © 2016年 Eru. All rights reserved.
//

import Cocoa

class PresetListView: NSTableView {

    override func menuForEvent(event: NSEvent) -> NSMenu? {
        if event.type != NSEventType.RightMouseDown {
            return super.menuForEvent(event)
        }
        let location: NSPoint = self.convertPoint(event.locationInWindow, fromView: nil)
        let row: Int = self.rowAtPoint(location)
        if row < 0 {
            self.deselectAll(nil)
            return super.menuForEvent(event)
        }
        var selected: NSIndexSet = self.selectedRowIndexes
        if !selectedRowIndexes.containsIndex(row) {
            selected = NSIndexSet(index: row)
            self.selectRowIndexes(selected, byExtendingSelection: false)
        }
        if self.delegate() is ContextMenuDelegate {
            return (self.delegate() as! ContextMenuDelegate).tableView(self, menuForRows: selected)
        }
        else {
            return super.menuForEvent(event)
        }
    }
    
    override func keyDown(theEvent: NSEvent) {
        // delete key
        if theEvent.keyCode == 0x33 {
            AppPrefsWindowController.sharedPrefsWindowController.removePreset(nil)
        } else {
            super.keyDown(theEvent)
        }
    }
    
}
