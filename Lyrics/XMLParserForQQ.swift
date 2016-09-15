//
//  XMLParserForQQ.swift
//  111
//
//  Created by Eru on 15/12/27.
//  Copyright © 2015年 Eru. All rights reserved.
//

import Cocoa

class XMLParserForQQ: NSObject, XMLParserDelegate {
    
    var lrcContents: String
    
    override init() {
        lrcContents = String()
        super.init()
    }
    
    func stringWithData(_ data:Data) -> String? {
        let parser = XMLParser(data: data)
        parser.delegate = self
        let success: Bool = parser.parse()
        if !success {
            return nil
        }
        return lrcContents
    }
    
    func parser(_ parser: XMLParser, foundCDATA CDATABlock: Data) {
        let str = String(data: CDATABlock, encoding: String.Encoding.utf8)
        if str != nil {
            lrcContents.append(str!)
        }
    }
    
}
