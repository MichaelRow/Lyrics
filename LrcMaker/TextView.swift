//
//  TextView.swift
//  LrcMaker
//
//  Created by Eru on 15/12/5.
//  Copyright © 2015年 Eru. All rights reserved.
//

import Cocoa

class TextView: NSTextView {
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.textColor = NSColor.blackColor()
        self.font = NSFont(name: "HiraginoSansGB-W3", size: 14)
    }

    override func paste(sender: AnyObject?) {
        self.pasteAsPlainText(sender)
    }
    
}
