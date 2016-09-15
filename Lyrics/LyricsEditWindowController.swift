//
//  LyricsEditWindowController.swift
//  Lyrics
//
//  Created by Eru on 15/11/19.
//  Copyright © 2015年 Eru. All rights reserved.
//

import Cocoa

class LyricsEditWindowController: NSWindowController {
    
    static let sharedController = LyricsEditWindowController()
    
    @IBOutlet var textView: NSTextView!
    @IBOutlet var boxView: NSBox!
    @IBOutlet var leftBracket: NSTextField!
    @IBOutlet var rightBracket: NSTextField!
    @IBOutlet var actionType: NSPopUpButton!
    
    fileprivate var currentSongID: String!
    fileprivate var currentTitle: String!
    fileprivate var currentArtist: String!
    
    fileprivate var hideOptionConstraint: NSLayoutConstraint!
    fileprivate var showOptionConstraint: NSLayoutConstraint!
    
    convenience init() {
        self.init(windowNibName:"LyricsEditWindow")
        self.window?.level = Int(CGWindowLevelForKey(.normalWindow))
        textView.textColor = NSColor.white
        textView.font = NSFont(name: "Helvetica-Bold", size: 14)
        
        hideOptionConstraint = NSLayoutConstraint(item: boxView, attribute: .height, relatedBy: NSLayoutRelation.lessThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 0)
        showOptionConstraint = NSLayoutConstraint(item: boxView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 24)
        boxView.addConstraint(hideOptionConstraint)
        self.window?.makeFirstResponder(textView)
    }
    
    func setLyricsContents(_ contents: String, songID: String, songTitle: String, andArtist artist: String) {
        currentSongID = songID
        currentTitle = songTitle
        currentArtist = artist
        textView.string = contents
    }
    
    @IBAction func showAndHideOptions(_ sender: AnyObject) {
        if (sender as! NSButton).state == NSOnState {
            boxView.isHidden = false
            boxView.removeConstraint(hideOptionConstraint)
            boxView.addConstraint(showOptionConstraint)
        }
        else {
            boxView.removeConstraint(showOptionConstraint)
            boxView.addConstraint(hideOptionConstraint)
            boxView.isHidden = true
        }
    }
    
    @IBAction func cancelAction(_ sender: AnyObject) {
        self.window?.orderOut(nil)
    }
    
    @IBAction func okAction(_ sender: AnyObject) {
        let dic: [String:AnyObject] = ["SongID":currentSongID as AnyObject, "SongTitle":currentTitle as AnyObject, "SongArtist":currentArtist as AnyObject]
        NotificationCenter.default.post(name: Notification.Name(rawValue: LyricsUserEditLyricsNotification), object: nil, userInfo: dic)
        self.window?.orderOut(nil)
    }
    
    @IBAction func showHelp(_ sender: AnyObject) {
        let helpFilePath = Bundle.main.path(forResource: "关于双语歌词编辑工具", ofType: "pdf")
        NSWorkspace.shared().openFile(helpFilePath!)
    }
    
    @IBAction func applyOperation(_ sender: AnyObject) {
        if leftBracket.stringValue.characters.count != 1 {
            return
        }
        var newLyrics = String()
        let parser = LrcParser()
        parser.regularParse(textView.string!)
        for str in parser.idTags {
            newLyrics.append(str + "\n")
        }
        newLyrics.append("[offset:\(parser.timeDly)]\n")
        for line in parser.lyrics {
            newLyrics.append(line.timeTag + operationToString(line.lyricsSentence) + "\n")
        }
        self.textView.string = newLyrics
    }
    
    //MARK: - Other
    
    fileprivate func operationToString (_ str: String) -> String {
        if rightBracket.stringValue.characters.count == 1 {
            let rightBracketIdx = getRightBracketIndex(str as NSString)
            if rightBracketIdx == -1 {
                return str
            }
            let leftBracketIdx = getLeftBracketIndex(str as NSString, lastCharacterIndex: rightBracketIdx)
            if leftBracketIdx == -1 {
                return str
            }
            switch actionType.indexOfSelectedItem {
            case 0:
                return (str as NSString).substring(to: leftBracketIdx)
            case 1:
                let loc = leftBracketIdx + 1
                let len = rightBracketIdx - loc
                return (str as NSString).substring(with: NSMakeRange(loc, len))
            case 2:
                let loc = leftBracketIdx + 1
                let len = rightBracketIdx - loc
                let formmerPart = (str as NSString).substring(to: leftBracketIdx)
                let latterPart = (str as NSString).substring(with: NSMakeRange(loc, len))
                return latterPart + leftBracket.stringValue + formmerPart + rightBracket.stringValue
            case 3:
                let loc = leftBracketIdx + 1
                let len = rightBracketIdx - loc
                let formmerPart = (str as NSString).substring(to: leftBracketIdx)
                let latterPart = (str as NSString).substring(with: NSMakeRange(loc, len))
                return formmerPart + "【" + latterPart + "】"
            case 4:
                let loc = leftBracketIdx + 1
                let len = rightBracketIdx - loc
                let formmerPart = (str as NSString).substring(to: leftBracketIdx)
                let latterPart = convertToSC((str as NSString).substring(with: NSMakeRange(loc, len)))
                return formmerPart + "【" + latterPart + "】"
            case 5:
                let loc = leftBracketIdx + 1
                let len = rightBracketIdx - loc
                let formmerPart = (str as NSString).substring(to: leftBracketIdx)
                let latterPart = convertToTC((str as NSString).substring(with: NSMakeRange(loc, len)))
                return formmerPart + leftBracket.stringValue + latterPart + rightBracket.stringValue
            default:
                return str
            }
        }
        else if rightBracket.stringValue == "" {
            let leftBracketIdx = (str as NSString).range(of: leftBracket.stringValue).location
            if leftBracketIdx == NSNotFound {
                return str
            }
            switch actionType.indexOfSelectedItem {
            case 0:
                return (str as NSString).substring(to: leftBracketIdx)
            case 1:
                if leftBracketIdx == str.characters.count - 1 {
                    return str
                }
                else {
                    return (str as NSString).substring(from: leftBracketIdx + 1)
                }
            case 2:
                if leftBracketIdx == str.characters.count - 1 {
                    return str
                }
                else {
                    let formmerPart = (str as NSString).substring(to: leftBracketIdx)
                    let latterPart = (str as NSString).substring(from: leftBracketIdx + 1)
                    return latterPart + "【" + formmerPart + "】"
                }
            case 3:
                if leftBracketIdx == str.characters.count - 1 {
                    return str
                }
                else {
                    let formmerPart = (str as NSString).substring(to: leftBracketIdx)
                    let latterPart = (str as NSString).substring(from: leftBracketIdx + 1)
                    return formmerPart + "【" + latterPart + "】"
                }
            default:
                return str
            }
        }
        else {
            return str
        }
    }
    
    fileprivate func getRightBracketIndex(_ str: NSString) -> Int {
        var index: Int = str.length - 1
        while index > -1 {
            let char: String = str.substring(with: NSMakeRange(index, 1))
            if char == " " {
                index -= 1
                continue
            }
            else if char == rightBracket.stringValue {
                return index
            }
            else {
                return -1
            }
        }
        return -1
    }
    
    fileprivate func getLeftBracketIndex(_ str: NSString, lastCharacterIndex theIndex: Int) -> Int {
        var stack: [Int] = Array()
        var index: Int = 0
        while index < theIndex {
            let char: String = str.substring(with: NSMakeRange(index, 1))
            if char == leftBracket.stringValue {
                stack.append(index)
            }
            else if char == rightBracket.stringValue {
                if stack.count == 0 {
                    return -1
                }
                stack.removeLast()
            }
            index += 1
        }
        if stack.count == 1 {
            return stack.first!
        } else {
            return -1
        }
    }

}
