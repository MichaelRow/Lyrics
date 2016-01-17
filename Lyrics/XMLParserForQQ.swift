//
//  XMLParserForQQ.swift
//  111
//
//  Created by Eru on 15/12/27.
//  Copyright © 2015年 Eru. All rights reserved.
//

import Cocoa

class XMLParserForQQ: NSObject, NSXMLParserDelegate {
    
    var lrcContents: String
    
    override init() {
        lrcContents = String()
        super.init()
    }
    
    func stringWithData(data:NSData) -> String? {
        let parser = NSXMLParser(data: data)
        parser.delegate = self
        let success: Bool = parser.parse()
        if !success {
            return nil
        }
        return lrcContents
    }
    
    func parser(parser: NSXMLParser, foundCDATA CDATABlock: NSData) {
        let str = String(data: CDATABlock, encoding: NSUTF8StringEncoding)
        if str != nil {
            lrcContents.appendContentsOf(str!)
        }
    }
    
}
