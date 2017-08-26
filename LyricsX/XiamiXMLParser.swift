//
//  XiamiXMLParser.swift
//  LyricsX
//
//  Created by Eru on 2017/7/2.
//  Copyright © 2017年 Eru. All rights reserved.
//

import Cocoa

class XiamiXMLParser: NSObject {
    
    fileprivate var currentString: String?
    fileprivate var currentField = [String:String]()
    
    func parse(data: Data, info: SongBasicInfo) -> WebLyrics? {
        
        currentString = nil
        currentField.removeAll()
        
        let xmlParser = XMLParser(data: data)
        xmlParser.delegate = self
        xmlParser.shouldProcessNamespaces = true
        xmlParser.parse()
        
        guard currentField.count > 0 else { return nil }
        
        return XiamiWebLyrics.webLyrics(info: info, dic: currentField)
    }
}

//MARK: XMLParserDelegate

extension XiamiXMLParser: XMLParserDelegate {
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        guard currentString != nil else { return }
        
        switch elementName {
        case "lyric":
            let trimmed = currentString!.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            currentField["lrcURL"] = trimmed
            
        case "album_pic":
            let trimmed = currentString!.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            currentField["artworkURL"] = trimmed
        
        case "songName":
            currentField["title"] = currentString!
            
        case "singers":
            currentField["artist"] = currentString!
            
        default:
            break
        }
        
        currentString = nil
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if currentString == nil {
            currentString = String()
        }
        currentString!.append(string)
    }
}
