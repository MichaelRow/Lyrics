//
//  String+Custom.swift
//  LyricsX
//
//  Created by Eru on 2017/7/6.
//  Copyright © 2017年 Eru. All rights reserved.
//

import Cocoa

extension String {
    
    var urlEncoding: String {
        if let encoded = self.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) {
            return encoded
        } else {
            return ""
        }
    }
    
    func range(from nsRange: NSRange) -> Range<String.Index>? {
        guard
            let from16 = utf16.index(utf16.startIndex, offsetBy: nsRange.location, limitedBy: utf16.endIndex),
            let to16 = utf16.index(from16, offsetBy: nsRange.length, limitedBy: utf16.endIndex),
            let from = String.Index(from16, within: self),
            let to = String.Index(to16, within: self)
            else { return nil }
        
        return from ..< to
    }
}
