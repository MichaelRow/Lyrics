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
    
    private var currentSongID: String!
    private var currentTitle: String!
    private var currentArtist: String!
    
    private var hideOptionConstraint: NSLayoutConstraint!
    private var showOptionConstraint: NSLayoutConstraint!
    
    convenience init() {
        self.init(windowNibName:"LyricsEditWindow")
        self.window?.level = Int(CGWindowLevelForKey(.NormalWindowLevelKey))
        textView.textColor = NSColor.whiteColor()
        textView.font = NSFont(name: "Helvetica-Bold", size: 14)
        
        hideOptionConstraint = NSLayoutConstraint(item: boxView, attribute: .Height, relatedBy: NSLayoutRelation.LessThanOrEqual, toItem: nil, attribute: .NotAnAttribute, multiplier: 1, constant: 0)
        showOptionConstraint = NSLayoutConstraint(item: boxView, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1, constant: 24)
        boxView.addConstraint(hideOptionConstraint)
        self.window?.makeFirstResponder(textView)
    }
    
    func setLyricsContents(contents: String, songID: String, songTitle: String, andArtist artist: String) {
        currentSongID = songID
        currentTitle = songTitle
        currentArtist = artist
        textView.string = contents
    }
    
    @IBAction func showAndHideOptions(sender: AnyObject) {
        if (sender as! NSButton).state == NSOnState {
            boxView.hidden = false
            boxView.removeConstraint(hideOptionConstraint)
            boxView.addConstraint(showOptionConstraint)
        }
        else {
            boxView.removeConstraint(showOptionConstraint)
            boxView.addConstraint(hideOptionConstraint)
            boxView.hidden = true
        }
    }
    
    @IBAction func cancelAction(sender: AnyObject) {
        self.window?.orderOut(nil)
    }
    
    @IBAction func okAction(sender: AnyObject) {
        let dic: [String:AnyObject] = ["SongID":currentSongID, "SongTitle":currentTitle, "SongArtist":currentArtist]
        NSNotificationCenter.defaultCenter().postNotificationName(LyricsUserEditLyricsNotification, object: nil, userInfo: dic)
        self.window?.orderOut(nil)
    }
    
    @IBAction func showHelp(sender: AnyObject) {
        let helpFilePath = NSBundle.mainBundle().pathForResource("关于双语歌词编辑工具", ofType: "pdf")
        NSWorkspace.sharedWorkspace().openFile(helpFilePath!)
    }
    
    @IBAction func applyOperation(sender: AnyObject) {
        if leftBracket.stringValue.characters.count != 1 {
            return
        }
        var newLyrics = String()
        let parser = LrcParser()
        parser.regularParse(textView.string!)
        for str in parser.idTags {
            newLyrics.appendContentsOf(str + "\n")
        }
        newLyrics.appendContentsOf("[offset:\(parser.timeDly)]\n")
        for line in parser.lyrics {
            newLyrics.appendContentsOf(line.timeTag + operationToString(line.lyricsSentence) + "\n")
        }
        self.textView.string = newLyrics
    }
    
    //MARK: - Other
    
    private func operationToString (str: String) -> String {
        if rightBracket.stringValue.characters.count == 1 {
            let rightBracketIdx = getRightBracketIndex(str)
            if rightBracketIdx == -1 {
                return str
            }
            let leftBracketIdx = getLeftBracketIndex(str, lastCharacterIndex: rightBracketIdx)
            if leftBracketIdx == -1 {
                return str
            }
            switch actionType.indexOfSelectedItem {
            case 0:
                return (str as NSString).substringToIndex(leftBracketIdx)
            case 1:
                let loc = leftBracketIdx + 1
                let len = rightBracketIdx - loc
                return (str as NSString).substringWithRange(NSMakeRange(loc, len))
            case 2:
                let loc = leftBracketIdx + 1
                let len = rightBracketIdx - loc
                let formmerPart = (str as NSString).substringToIndex(leftBracketIdx)
                let latterPart = (str as NSString).substringWithRange(NSMakeRange(loc, len))
                return latterPart + leftBracket.stringValue + formmerPart + rightBracket.stringValue
            case 3:
                let loc = leftBracketIdx + 1
                let len = rightBracketIdx - loc
                let formmerPart = (str as NSString).substringToIndex(leftBracketIdx)
                let latterPart = (str as NSString).substringWithRange(NSMakeRange(loc, len))
                return formmerPart + "【" + latterPart + "】"
            case 4:
                let loc = leftBracketIdx + 1
                let len = rightBracketIdx - loc
                let formmerPart = (str as NSString).substringToIndex(leftBracketIdx)
                let latterPart = convertToSC((str as NSString).substringWithRange(NSMakeRange(loc, len)))
                return formmerPart + "【" + latterPart + "】"
            case 5:
                let loc = leftBracketIdx + 1
                let len = rightBracketIdx - loc
                let formmerPart = (str as NSString).substringToIndex(leftBracketIdx)
                let latterPart = convertToTC((str as NSString).substringWithRange(NSMakeRange(loc, len)))
                return formmerPart + leftBracket.stringValue + latterPart + rightBracket.stringValue
            default:
                return str
            }
        }
        else if rightBracket.stringValue == "" {
            let leftBracketIdx = (str as NSString).rangeOfString(leftBracket.stringValue).location
            if leftBracketIdx == NSNotFound {
                return str
            }
            switch actionType.indexOfSelectedItem {
            case 0:
                return (str as NSString).substringToIndex(leftBracketIdx)
            case 1:
                if leftBracketIdx == str.characters.count - 1 {
                    return str
                }
                else {
                    return (str as NSString).substringFromIndex(leftBracketIdx + 1)
                }
            case 2:
                if leftBracketIdx == str.characters.count - 1 {
                    return str
                }
                else {
                    let formmerPart = (str as NSString).substringToIndex(leftBracketIdx)
                    let latterPart = (str as NSString).substringFromIndex(leftBracketIdx + 1)
                    return latterPart + "【" + formmerPart + "】"
                }
            case 3:
                if leftBracketIdx == str.characters.count - 1 {
                    return str
                }
                else {
                    let formmerPart = (str as NSString).substringToIndex(leftBracketIdx)
                    let latterPart = (str as NSString).substringFromIndex(leftBracketIdx + 1)
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
    
    private func getRightBracketIndex(str: NSString) -> Int {
        var index: Int = str.length - 1
        while index > -1 {
            let char: String = str.substringWithRange(NSMakeRange(index, 1))
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
    
    private func getLeftBracketIndex(str: NSString, lastCharacterIndex theIndex: Int) -> Int {
        var stack: [Int] = Array()
        var index: Int = 0
        while index < theIndex {
            let char: String = str.substringWithRange(NSMakeRange(index, 1))
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
