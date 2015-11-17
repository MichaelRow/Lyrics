//
//  LyricsWindowController.swift
//  Lyrics
//
//  Created by Eru on 15/11/9.
//  Copyright © 2015年 Eru. All rights reserved.
//


/************************ IMPORTANT ************************/
/*                                                         */
/*     LyricsWindowController Must Run in Main Thread      */
/*   In other threads may cause some unexpected problems   */
/*                                                         */
/************************ IMPORTANT ************************/

import Cocoa

class LyricsWindowController: NSWindowController {
    
    var baseLayer: CALayer!
    var firstLyricsLayer: CATextLayer!
    var secondlyricsLayer: CATextLayer!
    var attrs: [String:AnyObject]!
    var visibleSize: NSSize!
    var visibleOrigin: NSPoint!
    var userDefaults: NSUserDefaults!
    
    convenience init() {
        self.init(windowNibName:"LyricsWindow")
        userDefaults = NSUserDefaults.standardUserDefaults()
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    override func windowDidLoad() {
        super.windowDidLoad()
        NSLog("Init Lyrics window")
        self.window?.backgroundColor=NSColor.clearColor()
        self.window?.opaque=false
        self.window?.hasShadow=false
        self.window?.ignoresMouseEvents=true
        self.window?.level=Int(CGWindowLevelForKey(.FloatingWindowLevelKey))
        self.window?.contentView?.layer=CALayer()
        self.window?.contentView?.wantsLayer=true
        
        if userDefaults.boolForKey(LyricsDisabledWhenSreenShot) {
            self.window?.sharingType=NSWindowSharingType.None
        }
        if userDefaults.boolForKey(LyricsDisplayInAllSpaces) {
            self.window?.collectionBehavior=NSWindowCollectionBehavior.CanJoinAllSpaces
        }
        
        baseLayer=CALayer()
        firstLyricsLayer=CATextLayer()
        secondlyricsLayer=CATextLayer()
        
        baseLayer.anchorPoint=CGPointZero
        baseLayer.position=CGPointMake(0, 0)
        baseLayer.cornerRadius=20
        
        firstLyricsLayer.anchorPoint=CGPointZero
        firstLyricsLayer.position=CGPointMake(0, 0)
        firstLyricsLayer.alignmentMode=kCAAlignmentCenter
        
        secondlyricsLayer.anchorPoint=CGPointZero
        secondlyricsLayer.position=CGPointMake(0, 0)
        secondlyricsLayer.alignmentMode=kCAAlignmentCenter
        
        self.window?.contentView?.layer!.addSublayer(baseLayer)
        baseLayer.addSublayer(firstLyricsLayer)
        baseLayer.addSublayer(secondlyricsLayer)
        setAttributes()
        setScreenResolution()
        baseLayer.speed=1.1
        displayLyrics("LyricsX", secondLyrics: nil)
        
        let nc:NSNotificationCenter=NSNotificationCenter.defaultCenter()
        nc.addObserver(self, selector: "setAttributes", name: LyricsAttributesChangedNotification, object: nil)
        nc.addObserver(self, selector: "setScreenResolution", name: NSApplicationDidChangeScreenParametersNotification, object: nil)

    }

    func displayLyrics(firstLyrics:NSString?, secondLyrics:NSString?) {
        if (firstLyrics==nil) || (firstLyrics?.isEqualToString(""))! {
            // first Lyrics empty means it's instrument time
            baseLayer.speed=0.2
            baseLayer.frame = NSMakeRect(baseLayer.frame.origin.x+baseLayer.frame.size.width/2, 0, 0, 0)
            firstLyricsLayer.string = ""
            secondlyricsLayer.string = ""
            firstLyricsLayer.hidden=true
            secondlyricsLayer.hidden=true
            baseLayer.hidden=true
        }
        else if (secondLyrics==nil) || (secondLyrics?.isEqualToString(""))! {
            // One-Line Mode or sencond lyrics is instrument time
            baseLayer.speed = 1.1
            firstLyricsLayer.string = ""
            secondlyricsLayer.string = ""
            firstLyricsLayer.hidden = false
            secondlyricsLayer.hidden = true
            baseLayer.hidden = false
            
            let strSize:NSSize = firstLyrics!.sizeWithAttributes(attrs)
            let x:CGFloat
            let y:CGFloat
            
            if userDefaults.boolForKey(LyricsUseAutoLayout) {
                let frameSize = NSMakeSize(strSize.width+50, strSize.height)
                x = visibleOrigin.x+(visibleSize.width-frameSize.width)/2
                y = visibleOrigin.y+CGFloat(userDefaults.integerForKey(LyricsHeightFromDockToLyrics))
                
                baseLayer.frame=CGRectMake(x, y, frameSize.width, frameSize.height)
                firstLyricsLayer.frame=CGRectMake(0, 0, frameSize.width, frameSize.height)
            } else {
                
                let frameSize = NSMakeSize(CGFloat(userDefaults.integerForKey(LyricsConstWidth)), CGFloat(userDefaults.integerForKey(LyricsConstHeight)))
                x = CGFloat(userDefaults.integerForKey(LyricsConstToLeft))
                y = CGFloat(userDefaults.integerForKey(LyricsConstToBottom))
                
                baseLayer.frame=CGRectMake(x, y, frameSize.width, frameSize.height)
                firstLyricsLayer.frame=CGRectMake(0, (frameSize.height-strSize.height)/2, frameSize.width, strSize.height)
            }
            
            firstLyricsLayer.string=firstLyrics
        }
        else {
            // Two-Line Mode
            baseLayer.speed = 1.1
            firstLyricsLayer.string = ""
            secondlyricsLayer.string = ""
            firstLyricsLayer.hidden=false
            secondlyricsLayer.hidden=false
            baseLayer.hidden=false
            var size2nd:NSSize=secondLyrics!.sizeWithAttributes(attrs)
            size2nd.width=size2nd.width+50
            size2nd.height=size2nd.height*0.9
            secondlyricsLayer.string=secondLyrics
            
            var size1st:NSSize=firstLyrics!.sizeWithAttributes(attrs)
            size1st.width=size1st.width+50
            size1st.height=size1st.height*0.9
            firstLyricsLayer.string=firstLyrics
            
            var width: CGFloat
            var height: CGFloat
            let x: CGFloat
            let y: CGFloat
            var rect1st: CGRect
            var rect2nd: CGRect
            
            if size1st.width>=size2nd.width {
                width=size1st.width
                rect1st=CGRectMake(0, size2nd.height, size1st.width, size1st.height)
                rect2nd=CGRectMake(0, 0, size1st.width, size2nd.height)
            }
            else {
                width=size2nd.width
                rect1st=CGRectMake(0, size2nd.height, size2nd.width, size1st.height)
                rect2nd=CGRectMake(0, 0, size2nd.width, size2nd.height)
            }
            
            if userDefaults.boolForKey(LyricsUseAutoLayout) {
                x = visibleOrigin.x+(visibleSize.width-width)/2
                y = visibleOrigin.y+CGFloat(userDefaults.integerForKey(LyricsHeightFromDockToLyrics))
                height=size1st.height+size2nd.height
                
            } else {
                x = CGFloat(userDefaults.integerForKey(LyricsConstToLeft))
                y = CGFloat(userDefaults.integerForKey(LyricsConstToBottom))
                width = CGFloat(userDefaults.integerForKey(LyricsConstWidth))
                height = CGFloat(userDefaults.integerForKey(LyricsConstHeight))
                
                rect1st.origin.x += (width-rect1st.size.width)/2
                rect1st.origin.y = height/2
                rect2nd.origin.x += (width-rect2nd.size.width)/2
                rect2nd.origin.y = height/2-rect2nd.size.height
            }
            
            baseLayer.frame = CGRectMake(x, y, width, height)
            firstLyricsLayer.frame = rect1st
            secondlyricsLayer.frame = rect2nd
            firstLyricsLayer.string = firstLyrics
            secondlyricsLayer.string = secondLyrics
        }
    }
    
    func setAttributes() {
        let bkColor:NSColor=NSColor.blackColor().colorWithAlphaComponent(0)
        let fontColor:NSColor=NSColor.redColor()
        let fontSize:CGFloat=36
        let cgfont:CGFontRef=CGFontCreateWithFontName("PingFangSC-Semibold")!
        let font:NSFont=NSFont(name: "PingFangSC-Semibold", size: fontSize)!
        let shadowColor:NSColor=NSColor.yellowColor()
        let shadowRadius:CGFloat=2
        
        attrs=[NSFontAttributeName:font]
        
        baseLayer.backgroundColor=bkColor.CGColor
        
        firstLyricsLayer.foregroundColor = fontColor.CGColor
        firstLyricsLayer.fontSize = fontSize
        firstLyricsLayer.font = cgfont
        firstLyricsLayer.shadowColor = shadowColor.CGColor
        firstLyricsLayer.shadowRadius=shadowRadius
        firstLyricsLayer.shadowOpacity=1
        firstLyricsLayer.shadowOffset=CGSizeMake(0,0)
        
        
        secondlyricsLayer.foregroundColor=fontColor.CGColor
        secondlyricsLayer.fontSize=fontSize
        secondlyricsLayer.font=cgfont
        secondlyricsLayer.shadowColor=shadowColor.CGColor
        secondlyricsLayer.shadowRadius=shadowRadius
        secondlyricsLayer.shadowOpacity=1
        secondlyricsLayer.shadowOffset=CGSizeMake(0,0)
    }
    
    func setScreenResolution() {
        let visibleFrame:NSRect=(NSScreen.mainScreen()?.visibleFrame)!
        visibleSize=visibleFrame.size
        visibleOrigin=visibleFrame.origin
        self.window?.setFrame(CGRectMake(0, 0, visibleSize.width, visibleSize.height), display: true)
        firstLyricsLayer.contentsScale=(NSScreen.mainScreen()?.backingScaleFactor)!
        secondlyricsLayer.contentsScale=firstLyricsLayer.contentsScale
        NSLog("Screen Visible Res Changed to:(%f,%f) O:(%f,%f)", visibleSize.width,visibleSize.height,visibleOrigin.x,visibleOrigin.y)
    }

}
