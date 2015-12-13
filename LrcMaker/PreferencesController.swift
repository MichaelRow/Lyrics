//
//  PreferencesController.swift
//  Lyrics
//
//  Created by Eru on 15/12/13.
//  Copyright © 2015年 Eru. All rights reserved.
//

import Cocoa

class PreferencesController: NSWindowController {
    
    static let sharedPreferences = PreferencesController()
    
    convenience init() {
        self.init(windowNibName: "Preferences")
    }

}
