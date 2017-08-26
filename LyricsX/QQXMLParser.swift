//
//  QQXMLParser.swift
//  LyricsX
//
//  Created by Eru on 2017/7/5.
//  Copyright © 2017年 Eru. All rights reserved.
//

import Cocoa

class QQXMLParser: NSObject, XMLParserDelegate {

    private var lyrics: String?
    
    func parse(data: Data) -> String? {
        lyrics = String()
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
        return lyrics
    }
    
    func parser(_ parser: XMLParser, foundCDATA CDATABlock: Data) {
        guard let newStr = String(data: CDATABlock, encoding: .utf8) else { return }
        lyrics?.append(newStr)
    }
    
}
