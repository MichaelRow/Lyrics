//
//  ContextMenuDelegate.swift
//  Lyrics
//
//  Created by Eru on 16/1/14.
//  Copyright © 2016年 Eru. All rights reserved.
//

import Cocoa

protocol ContextMenuDelegate {
    func tableView(aTableView: NSTableView, menuForRows rows: NSIndexSet) -> NSMenu
}
