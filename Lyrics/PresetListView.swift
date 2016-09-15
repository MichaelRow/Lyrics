//
//  PresetListView.swift
//  Lyrics
//
//  Created by Eru on 16/1/14.
//  Copyright © 2016年 Eru. All rights reserved.
//

import Cocoa

class PresetListView: NSTableView {

    override func menu(for event: NSEvent) -> NSMenu? {
        if event.type != NSEventType.rightMouseDown {
            return super.menu(for: event)
        }
        let location: NSPoint = self.convert(event.locationInWindow, from: nil)
        let row: Int = self.row(at: location)
        if row < 0 {
            self.deselectAll(nil)
            return super.menu(for: event)
        }
        var selected: IndexSet = self.selectedRowIndexes
        if !selectedRowIndexes.contains(row) {
            selected = IndexSet(integer: row)
            self.selectRowIndexes(selected, byExtendingSelection: false)
        }
        if self.delegate is ContextMenuDelegate {
            return (self.delegate as! ContextMenuDelegate).tableView(self, menuForRows: selected)
        }
        else {
            return super.menu(for: event)
        }
    }
    
    override func keyDown(with theEvent: NSEvent) {
        // delete key
        if theEvent.keyCode == 0x33 {
            AppPrefsWindowController.sharedPrefsWindowController.removePreset(nil)
        } else {
            super.keyDown(with: theEvent)
        }
    }
    
}
