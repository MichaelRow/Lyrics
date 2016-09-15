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
        keyword = aDecoder.decodeObject(forKey: "keyword") as! String
        if let aCaseSensitive = aDecoder.decodeObject(forKey: "caseSensitive") {
            caseSensitive = aCaseSensitive as! Bool
        } else {
            caseSensitive = false
        }
        super.init()
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(keyword, forKey: "keyword")
        aCoder.encode(NSNumber(value:caseSensitive), forKey: "caseSensitive")
    }
}
