//
//  FilterString.swift
//  Lyrics
//
//  Created by Eru on 16/3/26.
//  Copyright © 2016年 Eru. All rights reserved.
//

import Cocoa

class FilterString: NSObject, NSCoding {
    
    var keyword: String
    var caseSensitive: Bool
    
    
    override init() {
        keyword = NSLocalizedString("NEW_KEYWORD", comment: "")
        caseSensitive = false
        super.init()
    }
    
    init(keyword: String, caseSensitive: Bool) {
        self.keyword = keyword
        self.caseSensitive = caseSensitive
        super.init()
    }
    
    required init(coder aDecoder: NSCoder) {
        keyword = aDecoder.decodeObjectForKey("keyword") as! String
        caseSensitive = aDecoder.decodeObjectForKey("caseSensitive") as! Bool
        super.init()
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(keyword, forKey: "keyword")
        aCoder.encodeObject(caseSensitive, forKey: "caseSensitive")
    }
}
