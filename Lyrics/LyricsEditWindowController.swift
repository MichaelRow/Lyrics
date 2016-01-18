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
    
    private var currentSongID: String!
    private var currentTitle: String!
    private var currentArtist: String!
    
    convenience init() {
        self.init(windowNibName:"LyricsEditWindow")
        self.window?.level = Int(CGWindowLevelForKey(.NormalWindowLevelKey))
        textView.textColor = NSColor.whiteColor()
        textView.font = NSFont(name: "Helvetica-Bold", size: 16)
    }
    
    func setLyricsContents(contents: String, songID: String, songTitle: String, andArtist artist: String) {
        currentSongID = songID
        currentTitle = songTitle
        currentArtist = artist
        textView.string = contents
    }
    
    @IBAction func copyToPb(sender: AnyObject) {
        let pb: NSPasteboard = NSPasteboard.generalPasteboard()
        pb.clearContents()
        pb.writeObjects([textView.string!])
    }
    
    @IBAction func cancelAction(sender: AnyObject) {
        self.window?.orderOut(nil)
    }
    
    @IBAction func okAction(sender: AnyObject) {
        let dic: [String:AnyObject] = ["SongID":currentSongID, "SongTitle":currentTitle, "SongArtist":currentArtist]
        NSNotificationCenter.defaultCenter().postNotificationName(LyricsUserEditLyricsNotification, object: nil, userInfo: dic)
        self.window?.orderOut(nil)
    }
    
}
