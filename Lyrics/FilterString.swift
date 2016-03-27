//
//  FilterString.swift
//  Lyrics
//
//  Created by Eru on 16/3/26.
//  Copyright © 2016年 Eru. All rights reserved.
//

import Cocoa

class FilterString: NSObject {
    
    var keyword: String
    
    override init() {
        keyword = NSLocalizedString("NEW_KEYWORD", comment: "")
        super.init()
    }
    
    init(keyword: String) {
        self.keyword = keyword
        super.init()
    }
    
    init(coder aDecoder: NSCoder) {
        keyword = aDecoder.decodeObjectForKey("keyword") as! String
        super.init()
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(keyword, forKey: "keyword")
    }
}
