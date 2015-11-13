//
//  LyricsWindowController.swift
//  Lyrics
//
//  Created by Eru on 15/11/9.
//  Copyright © 2015年 Eru. All rights reserved.
//


/************************ IMPORTANT ************************/
/*     LyricsWindowController Must Run in Main Thread      */


import Cocoa

class LyricsWindowController: NSWindowController {
    
    var baseLayer:CALayer!
    var firstLyricsLayer:CATextLayer!
    var secondlyricsLayer:CATextLayer!
    var attrs:[String:AnyObject]!
    var visibleSize:NSSize!
    var visibleOrigin:NSPoint!
    
    convenience init() {
        self.init(windowNibName:"LyricsWindow")
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
        self.window?.sharingType=NSWindowSharingType.None
        self.window?.collectionBehavior=NSWindowCollectionBehavior.CanJoinAllSpaces
        
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
            firstLyricsLayer.string = ""
            secondlyricsLayer.string = ""
            firstLyricsLayer.hidden=false
            secondlyricsLayer.hidden=true
            baseLayer.hidden=false
            
            baseLayer.speed=1.1
            var size:NSSize=firstLyrics!.sizeWithAttributes(attrs)
            size.width=ceil(size.width+50)
            size.height=ceil(size.height)
            

            let x:CGFloat=visibleOrigin.x+(visibleSize.width-size.width)/2
            let y:CGFloat=visibleOrigin.y+20
            
//            self.window?.setFrame(CGRectMake(x, y, size.width, size.height), display: true)
            baseLayer.frame=CGRectMake(x, y, size.width, size.height)
            firstLyricsLayer.frame=CGRectMake(0, 0, size.width, size.height)
            firstLyricsLayer.string=firstLyrics
        }
        else {
            // Two-Line Mode
            firstLyricsLayer.string = ""
            secondlyricsLayer.string = ""
            firstLyricsLayer.hidden=false
            secondlyricsLayer.hidden=false
            baseLayer.hidden=false
            baseLayer.speed=1.1
            var size2nd:NSSize=secondLyrics!.sizeWithAttributes(attrs)
            size2nd.width=ceil(size2nd.width+50)
            size2nd.height=ceil(size2nd.height*0.95)
            secondlyricsLayer.string=secondLyrics
            
            var size1st:NSSize=firstLyrics!.sizeWithAttributes(attrs)
            size1st.width=ceil(size1st.width+50)
            size1st.height=ceil(size1st.height*0.95)
            firstLyricsLayer.string=firstLyrics
            
            let width:CGFloat
            if size1st.width>=size2nd.width {
                width=size1st.width
                firstLyricsLayer.frame=CGRectMake(0, size2nd.height, size1st.width, size1st.height)
                secondlyricsLayer.frame=CGRectMake((size1st.width-size2nd.width)/2, 0, size2nd.width, size2nd.height)
            }
            else {
                width=size2nd.width
                firstLyricsLayer.frame=CGRectMake((size2nd.width-size1st.width)/2, size2nd.height, size1st.width, size1st.height)
                secondlyricsLayer.frame=CGRectMake(0, 0, size2nd.width, size2nd.height)
            }
            let height=size1st.height+size2nd.height
            let x:CGFloat=visibleOrigin.x+(visibleSize.width-width)/2
            let y:CGFloat=visibleOrigin.y+20
            
//            self.window?.setFrame(CGRectMake(x, y, width, height), display: true)
            baseLayer.frame=CGRectMake(x, y, width, height)
            firstLyricsLayer.string=firstLyrics
            secondlyricsLayer.string=secondLyrics
        }
    }
    
    
    func convertNSColorToCGColor(colorSpace:CGColorSpaceRef,color:NSColor)->CGColorRef {
        let deviceColor:NSColor=color.colorUsingColorSpaceName(NSDeviceRGBColorSpace)!
        var components:[CGFloat]=[0,0,0,0];
        deviceColor.getRed(&components[0], green: &components[2], blue: &components[2], alpha: &components[3])
        return CGColorCreate(colorSpace, components)!
    }
    
    
    func setAttributes() {
        let colorSpace:CGColorSpaceRef=CGColorSpaceCreateDeviceRGB()!
        let bkColor:NSColor=NSColor.blackColor().colorWithAlphaComponent(0.5)
        let fontColor:NSColor=NSColor.redColor()
        let fontSize:CGFloat=36
        let cgfont:CGFontRef=CGFontCreateWithFontName("PingFangSC-Semibold")!
        let font:NSFont=NSFont(name: "PingFangSC-Semibold", size: fontSize)!
        let shadowColor:NSColor=NSColor.blueColor()
        let shadowRadius:CGFloat=4
        
        attrs=[NSFontAttributeName:font]
        
        baseLayer.backgroundColor=convertNSColorToCGColor(colorSpace, color: bkColor)
        
        firstLyricsLayer.foregroundColor=convertNSColorToCGColor(colorSpace, color: fontColor)
        firstLyricsLayer.fontSize=fontSize
        firstLyricsLayer.font=cgfont
        firstLyricsLayer.shadowColor=convertNSColorToCGColor(colorSpace, color: shadowColor)
        firstLyricsLayer.shadowRadius=shadowRadius
        firstLyricsLayer.shadowOpacity=1
        firstLyricsLayer.shadowOffset=CGSizeMake(0,0)
        
        
        secondlyricsLayer.foregroundColor=convertNSColorToCGColor(colorSpace, color: fontColor)
        secondlyricsLayer.fontSize=fontSize
        secondlyricsLayer.font=cgfont
        secondlyricsLayer.shadowColor=convertNSColorToCGColor(colorSpace, color: shadowColor)
        secondlyricsLayer.shadowRadius=shadowRadius
        secondlyricsLayer.shadowOpacity=1
        secondlyricsLayer.shadowOffset=CGSizeMake(0,0)
    }
    
    func setScreenResolution() {
        let visibleFrame:NSRect=(NSScreen.mainScreen()?.visibleFrame)!
        visibleSize=visibleFrame.size
        visibleOrigin=visibleFrame.origin
        self.window?.setFrame(CGRectMake(0, 0, visibleSize.width, visibleSize.height/3), display: true)
        firstLyricsLayer.contentsScale=(NSScreen.mainScreen()?.backingScaleFactor)!
        secondlyricsLayer.contentsScale=firstLyricsLayer.contentsScale
        NSLog("Screen Visible Res Changed to:(%f,%f) O:(%f,%f)", visibleSize.width,visibleSize.height,visibleOrigin.x,visibleOrigin.y)
    }

}
