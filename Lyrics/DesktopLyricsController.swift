//
//  DesktopLyricsController.swift
//  Lyrics
//
//  Created by Eru on 15/11/9.
//  Copyright © 2015年 Eru. All rights reserved.
//


/************************ IMPORTANT ************************/
/*                                                         */
/*     DesktopLyricsController Must Run in Main Thread     */
/*        In other threads may no response or crash        */
/*                                                         */
/************************ IMPORTANT ************************/

import Cocoa
import QuartzCore
import CoreGraphics

class DesktopLyricsController: NSWindowController, NSWindowDelegate {
    
    static let sharedController = DesktopLyricsController()
    
    var isFullScreen: Bool = false
    fileprivate var firstLyrics: String?
    fileprivate var secondLyrics: String?
    fileprivate var backgroundLayer: CALayer!
    fileprivate var firstLyricsLayer: CATextLayer!
    fileprivate var secondLyricsLayer: CATextLayer!
    fileprivate var attrs: [String:AnyObject]!
    fileprivate var visibleSize: NSSize!
    fileprivate var visibleOrigin: NSPoint!
    fileprivate var yOffset: CGFloat!
    fileprivate var bgHeightIncreasement: CGFloat!
    fileprivate var lyricsHeightIncreasement: CGFloat!
    fileprivate var userDefaults: UserDefaults!
    fileprivate var rollingOver: Bool = true
    fileprivate var isRotated: Bool = false
    fileprivate var verticalStyle: Int = 0
    
    convenience fileprivate init() {
        NSLog("Init Lyrics window")
        let lyricsWindow = NSWindow(contentRect: NSMakeRect(0, 0, 100, 100), styleMask: [NSBorderlessWindowMask, NSTexturedBackgroundWindowMask], backing: NSBackingStoreType.buffered, defer: false)
        self.init(window: lyricsWindow)
        lyricsWindow.delegate = self
        lyricsWindow.backgroundColor = NSColor.clear
        lyricsWindow.isOpaque = false
        lyricsWindow.hasShadow = false
        lyricsWindow.ignoresMouseEvents = true
        lyricsWindow.level = Int(CGWindowLevelForKey(.floatingWindow))
        lyricsWindow.contentView?.layer = CALayer()
        lyricsWindow.contentView?.wantsLayer=true
                
        userDefaults = UserDefaults.standard
        if userDefaults.bool(forKey: LyricsDisabledWhenSreenShot) {
            lyricsWindow.sharingType = .none
        }
        if userDefaults.bool(forKey: LyricsDisplayInAllSpaces) {
            lyricsWindow.collectionBehavior = .canJoinAllSpaces
        }
        
        backgroundLayer = CALayer()
        firstLyricsLayer = CATextLayer()
        secondLyricsLayer = CATextLayer()
        
        backgroundLayer.anchorPoint = CGPoint.zero
        backgroundLayer.position = CGPoint(x: 0, y: 0)
        backgroundLayer.cornerRadius = 12
        
        firstLyricsLayer.anchorPoint = CGPoint.zero
        firstLyricsLayer.position = CGPoint(x: 0, y: 0)
        firstLyricsLayer.alignmentMode = kCAAlignmentCenter
        
        secondLyricsLayer.anchorPoint = CGPoint.zero
        secondLyricsLayer.position = CGPoint(x: 0, y: 0)
        secondLyricsLayer.alignmentMode = kCAAlignmentCenter
        
        lyricsWindow.contentView?.layer!.addSublayer(backgroundLayer)
        backgroundLayer.addSublayer(firstLyricsLayer)
        backgroundLayer.addSublayer(secondLyricsLayer)
        setAttributes()
        setScreenResolution()
        checkAutoLayout()
        displayLyrics("LyricsX", secondLyrics: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleScreenResolutionChange), name: NSNotification.Name.NSApplicationDidChangeScreenParameters, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
// MARK: - set lyrics properties
    
    func setAttributes() {
        let bkColor:NSColor = NSKeyedUnarchiver.unarchiveObject(with: userDefaults.data(forKey: LyricsBackgroundColor)!) as! NSColor
        let textColor:NSColor = NSKeyedUnarchiver.unarchiveObject(with: userDefaults.data(forKey: LyricsTextColor)!) as! NSColor
        let textSize:CGFloat = CGFloat(userDefaults.float(forKey: LyricsFontSize))
        let font:NSFont = NSFont(name: userDefaults.string(forKey: LyricsFontName)!, size: textSize)!
        
        yOffset = CGFloat(userDefaults.float(forKey: LyricsYOffset))
        bgHeightIncreasement = CGFloat(userDefaults.float(forKey: LyricsBgHeightINCR))
        if bgHeightIncreasement < 0 {
            lyricsHeightIncreasement = 0
        } else {
            lyricsHeightIncreasement = bgHeightIncreasement
        }
        attrs=[NSFontAttributeName:font]
        attrs[NSForegroundColorAttributeName] = textColor
        
        backgroundLayer.backgroundColor = bkColor.cgColor
        
        firstLyricsLayer.foregroundColor = textColor.cgColor
        firstLyricsLayer.fontSize = textSize
        firstLyricsLayer.font = font
        
        secondLyricsLayer.foregroundColor = textColor.cgColor
        secondLyricsLayer.fontSize = textSize
        secondLyricsLayer.font = font
        
        if userDefaults.bool(forKey: LyricsShadowModeEnable) {
            let shadowColor:NSColor = NSKeyedUnarchiver.unarchiveObject(with: userDefaults.object(forKey: LyricsShadowColor) as! Data) as! NSColor
            let shadowRadius:CGFloat = CGFloat(userDefaults.float(forKey: LyricsShadowRadius))
            
            let shadow:NSShadow = NSShadow()
            shadow.shadowColor = shadowColor
            shadow.shadowBlurRadius = shadowRadius
            attrs[NSShadowAttributeName] = shadow
            
            firstLyricsLayer.shadowColor = shadowColor.cgColor
            firstLyricsLayer.shadowRadius = shadowRadius
            firstLyricsLayer.shadowOpacity = 1
            firstLyricsLayer.shadowOffset = CGSize(width: 0,height: 0)
            
            secondLyricsLayer.shadowColor = shadowColor.cgColor
            secondLyricsLayer.shadowRadius = shadowRadius
            secondLyricsLayer.shadowOpacity = 1
            secondLyricsLayer.shadowOffset = CGSize(width: 0,height: 0)
        } else {
            firstLyricsLayer.shadowOpacity = 0
            secondLyricsLayer.shadowOpacity = 0
        }
        changeVerticalStyle()
    }
    
    func setScreenResolution() {
        self.window!.setFrameOrigin(NSZeroPoint)
        let visibleFrame: NSRect = self.window!.screen!.visibleFrame
        visibleSize = visibleFrame.size
        visibleOrigin = visibleFrame.origin
        if userDefaults.bool(forKey: LyricsUseAutoLayout) {
            self.window!.setFrame(self.window!.screen!.frame, display: true)
        }
        firstLyricsLayer.contentsScale = self.window!.screen!.backingScaleFactor
        secondLyricsLayer.contentsScale = firstLyricsLayer.contentsScale
        NSLog("Screen Visible Res Changed to:(%f,%f) O:(%f,%f)", visibleSize.width,visibleSize.height,visibleOrigin.x,visibleOrigin.y)
    }
    
    func handleAttributesUpdate() {
        DispatchQueue.main.async { () -> Void in
            self.setAttributes()
            self.reflash()
        }
    }
    
    //如果在竖直属性下，当前字形如果翻转了英文，那么我们只好只对中文添加翻转属性不翻转英文
    //（一行一个字母简直不能看，只好帮助大家治疗颈椎病了，哇哈哈）
    //主要我还没时间搞Core Text下的实现，所以这么随便的单字翻转在中英混排下简直是噩梦，英文太偏右，中文太偏左。
    func changeVerticalStyle() {
        let testAttrStr: NSMutableAttributedString = NSMutableAttributedString(string: "ThisIsATestStringToTestLyricsIn vertical", attributes: attrs)
        let normalSize = testAttrStr.size()
        testAttrStr.addAttribute(kCTVerticalFormsAttributeName as String, value: NSNumber(value: true as Bool), range: NSMakeRange(0, testAttrStr.length))
        let verticalSize = testAttrStr.size()
        if verticalSize.width > normalSize.width*1.7 {
            verticalStyle = 1
        } else {
            verticalStyle = 0
        }
    }
    
    func checkAutoLayout() {
        if userDefaults.bool(forKey: LyricsUseAutoLayout) {
            self.window!.ignoresMouseEvents = true
            self.window!.setFrame(self.window!.screen!.frame, display: true)
            self.window!.styleMask = [NSBorderlessWindowMask, NSTexturedBackgroundWindowMask]
        }
        else {
            let frameSize = NSMakeRect(100, 100, CGFloat(userDefaults.float(forKey: LyricsConstWidth)), CGFloat(userDefaults.float(forKey: LyricsConstHeight)))
            self.window!.setFrame(frameSize, display: true)
            self.window!.ignoresMouseEvents = false
            self.window!.styleMask = [NSBorderlessWindowMask, NSTexturedBackgroundWindowMask, NSResizableWindowMask]
        }
        reflash()
    }
    
// MARK: - display lyrics methods
    
    func displayLyrics(_ theFirstLyrics: String?, secondLyrics theSecondLyrics: String?) {
        if theFirstLyrics != nil && theFirstLyrics?.replacingOccurrences(of: " ", with: "") == "" {
           firstLyrics = nil
        } else {
            firstLyrics = theFirstLyrics
        }
        if theSecondLyrics != nil && theSecondLyrics?.replacingOccurrences(of: " ", with: "") == "" {
            secondLyrics = nil
        } else {
            secondLyrics = theSecondLyrics
        }
        
        if isRotated {
            backgroundLayer.transform = CATransform3DMakeRotation(0, 0, 0, 1)
            isRotated = false
        }
        
        if userDefaults.bool(forKey: LyricsIsVerticalLyrics) && userDefaults.bool(forKey: LyricsUseAutoLayout) {
            displayVerticalLyrics()
        } else {
            displayHorizontalLyrics()
        }
    }
    
    func displayHorizontalLyrics() {
        if firstLyrics == nil || firstLyrics == "" {
            // first Lyrics empty means it's in instrumental time, hide lyrics
            rollingOver = true
            firstLyricsLayer.speed = 0.4
            secondLyricsLayer.speed = 0.4
            if self.window!.ignoresMouseEvents {
                backgroundLayer.speed=0.4
                backgroundLayer.isHidden = true
            }
            else {
                backgroundLayer.frame = CGRect(x: 0, y: 0, width: self.window!.frame.width, height: self.window!.frame.height)
                backgroundLayer.isHidden = false
            }
            firstLyricsLayer.isHidden = true
            secondLyricsLayer.isHidden = true
            
            firstLyricsLayer.string = ""
            secondLyricsLayer.string = ""
        }
        else if secondLyrics == nil || secondLyrics == "" {
            // one lyrics
            rollingOver = true
            backgroundLayer.speed = 1
            firstLyricsLayer.speed = 1
            secondLyricsLayer.speed = 1
            secondLyricsLayer.string = ""
            firstLyricsLayer.isHidden = false
            secondLyricsLayer.isHidden = true
            backgroundLayer.isHidden = false
            
            let strSize:NSSize = firstLyrics!.size(withAttributes: attrs)
            
            if userDefaults.bool(forKey: LyricsUseAutoLayout) {
                var x:CGFloat
                let y:CGFloat
                var frameSize = NSMakeSize(strSize.width+50, strSize.height)
                if !isFullScreen {
                    x = visibleOrigin.x+(visibleSize.width-frameSize.width)/2
                    y = visibleOrigin.y+CGFloat(userDefaults.integer(forKey: LyricsHeightFromDockToLyrics))
                } else {
                    x = (visibleSize.width-frameSize.width)/2
                    y = CGFloat(userDefaults.integer(forKey: LyricsHeightFromDockToLyrics))
                }
                // lyrics too long, show former part
                if x < 4 {
                    if userDefaults.bool(forKey: LyricsTwoLineMode) && userDefaults.integer(forKey: LyricsTwoLineModeIndex)==1 {
                        clipLyrics(visibleSize.width-54)
                        displayLyrics(firstLyrics, secondLyrics: secondLyrics)
                        return
                    } else {
                        x = 4
                        frameSize.width = visibleSize.width
                    }
                }
                backgroundLayer.frame = CGRect(x: x, y: y, width: frameSize.width, height: frameSize.height+bgHeightIncreasement)
                firstLyricsLayer.frame = CGRect(x: 0, y: yOffset, width: frameSize.width, height: frameSize.height+lyricsHeightIncreasement)
            }
            else {
                let frameSize = self.window!.frame.size
                var layerY = (frameSize.height - strSize.height)/2
                if layerY < 0 {
                    layerY = 0
                }
                backgroundLayer.frame = CGRect(x: 0, y: 0, width: frameSize.width, height: frameSize.height)
                firstLyricsLayer.frame = CGRect(x: 0, y: layerY, width: frameSize.width, height: strSize.height)
            }
            
            firstLyricsLayer.string = firstLyrics
        }
        else {
            // Two lyrics
            backgroundLayer.speed = 1
            firstLyricsLayer.speed = 1
            secondLyricsLayer.speed = 1
            
            firstLyricsLayer.isHidden = false
            secondLyricsLayer.isHidden = false
            backgroundLayer.isHidden = false
            
            var size2nd:NSSize = secondLyrics!.size(withAttributes: attrs)
            size2nd.width = size2nd.width+50
            size2nd.height = size2nd.height*0.9
            
            var size1st:NSSize = firstLyrics!.size(withAttributes: attrs)
            size1st.width = size1st.width+50
            size1st.height = size1st.height*0.9
            
            var width: CGFloat
            var height: CGFloat
            var x: CGFloat
            let y: CGFloat
            var rect1st: CGRect
            var rect2nd: CGRect
            
            if userDefaults.bool(forKey: LyricsUseAutoLayout) {
                if size1st.width >= size2nd.width {
                    width = size1st.width
                }
                else {
                    width = size2nd.width
                }
                if width > visibleSize.width {
                    width = visibleSize.width
                }
                
                rect1st = CGRect(x: 0, y: size2nd.height+yOffset, width: width, height: size1st.height+lyricsHeightIncreasement)
                rect2nd = CGRect(x: 0, y: yOffset, width: width, height: size2nd.height+lyricsHeightIncreasement)
                
                if !isFullScreen {
                    x = visibleOrigin.x+(visibleSize.width-width)/2
                    y = visibleOrigin.y+CGFloat(userDefaults.integer(forKey: LyricsHeightFromDockToLyrics))
                } else {
                    x = (visibleSize.width-width)/2
                    y = CGFloat(userDefaults.integer(forKey: LyricsHeightFromDockToLyrics))
                }
                if x < 4 {
                    x = 4
                }
                height = rect1st.size.height+rect2nd.size.height
                backgroundLayer.frame = CGRect(x: x, y: y, width: width, height: height)
            }
            else {
                width = self.window!.frame.width
                height = self.window!.frame.height
                
                rect1st = CGRect(x: 0, y: height/2, width: width, height: size1st.height)
                rect2nd = CGRect(x: 0, y: height/2-size2nd.height, width: width, height: size2nd.height)
                backgroundLayer.frame = CGRect(x: 0, y: 0, width: width, height: height)
            }
            
            // whether needs rolling-over to show animation
            if rollingOver {
                firstLyricsLayer.string = firstLyrics
                secondLyricsLayer.string = secondLyrics
                firstLyricsLayer.frame = rect1st
                secondLyricsLayer.frame = rect2nd
                
            } else {
                firstLyricsLayer.string = secondLyrics
                secondLyricsLayer.string = firstLyrics
                firstLyricsLayer.frame = rect2nd
                secondLyricsLayer.frame = rect1st
            }
            
            rollingOver = !rollingOver
        }
    }
    
    func displayVerticalLyrics() {
        //Current vertical lyrics mode is not perfect, it should be implemented by core text.
        if firstLyrics == nil || firstLyrics == "" {
            // first Lyrics empty means it's in instrumental time, hide lyrics
            rollingOver = true
            backgroundLayer.speed=0.4
            firstLyricsLayer.speed = 0.4
            secondLyricsLayer.speed = 0.4
            
            firstLyricsLayer.string = ""
            secondLyricsLayer.string = ""
            firstLyricsLayer.isHidden = true
            secondLyricsLayer.isHidden = true
            backgroundLayer.isHidden = true
            
            backgroundLayer.transform = CATransform3DMakeRotation(CGFloat(-M_PI_2), 0, 0, 1)
            isRotated = true
        }
        else if secondLyrics == nil || secondLyrics == "" {
            //one lyrics
            rollingOver = true
            backgroundLayer.speed = 1
            firstLyricsLayer.speed = 1
            secondLyricsLayer.speed = 1
            
            secondLyricsLayer.string = ""
            firstLyricsLayer.isHidden = false
            secondLyricsLayer.isHidden = true
            backgroundLayer.isHidden = false
            
            let attributedStr: NSMutableAttributedString = NSMutableAttributedString(string: firstLyrics!, attributes: attrs)
            if verticalStyle == 1 {
                for i in 0 ..< firstLyrics!.characters.count {
                    if isChinese((firstLyrics! as NSString).substring(with: NSMakeRange(i, 1)) as NSString) {
                        attributedStr.addAttribute(kCTVerticalFormsAttributeName as String, value: NSNumber(value: true as Bool), range: NSMakeRange(i, 1))
                    }
                }
            } else {
                attributedStr.addAttribute(kCTVerticalFormsAttributeName as String, value: NSNumber(value: true as Bool), range: NSMakeRange(0, firstLyrics!.characters.count))
            }
            
            let strSize:NSSize = attributedStr.size()
            var frameSize = NSMakeSize(strSize.width+50, strSize.height)
            let heightWithDock = visibleOrigin.y + visibleSize.height
            let x: CGFloat
            let y: CGFloat
            
            var deltaH = heightWithDock - frameSize.width
            if deltaH < 8 {
                if userDefaults.bool(forKey: LyricsTwoLineMode) && userDefaults.integer(forKey: LyricsTwoLineModeIndex)==1 {
                    clipLyrics(heightWithDock-54)
                    displayLyrics(firstLyrics, secondLyrics: secondLyrics)
                    return
                } else {
                    deltaH = 8
                    frameSize.width = visibleSize.height
                }
            }
            y = heightWithDock - deltaH/2
            
            //lyrics on left or right side
            if userDefaults.integer(forKey: LyricsVerticalLyricsPosition) == 0 {
                x = visibleOrigin.x
            } else {
                x = visibleOrigin.x + visibleSize.width - frameSize.height - bgHeightIncreasement - 8
            }
            backgroundLayer.frame = CGRect(x: x, y: y, width: frameSize.width, height: frameSize.height*1.15+bgHeightIncreasement)
            firstLyricsLayer.frame = CGRect(x: 0, y: -frameSize.height*0.15+yOffset, width: frameSize.width, height: frameSize.height*1.08+lyricsHeightIncreasement)
            firstLyricsLayer.string=attributedStr
            backgroundLayer.transform = CATransform3DMakeRotation(CGFloat(-M_PI_2), 0, 0, 1)
            isRotated = true
        }
        else {
            //two lyrics
            backgroundLayer.speed = 1.5
            firstLyricsLayer.speed = 1.5
            secondLyricsLayer.speed = 1.5
            
            firstLyricsLayer.isHidden = false
            secondLyricsLayer.isHidden = false
            backgroundLayer.isHidden = false
            
            let firstAttrStr: NSMutableAttributedString = NSMutableAttributedString(string: firstLyrics!, attributes: attrs)
            let secondAttrStr: NSMutableAttributedString = NSMutableAttributedString(string: secondLyrics!, attributes: attrs)
            if verticalStyle == 0 {
                firstAttrStr.addAttribute(kCTVerticalFormsAttributeName as String, value: NSNumber(value: true as Bool), range: NSMakeRange(0, firstLyrics!.characters.count))
                secondAttrStr.addAttribute(kCTVerticalFormsAttributeName as String, value: NSNumber(value: true as Bool), range: NSMakeRange(0, secondLyrics!.characters.count))
            } else {
                for i in 0 ..< firstLyrics!.characters.count {
                    if isChinese((firstLyrics! as NSString).substring(with: NSMakeRange(i, 1)) as NSString) {
                        firstAttrStr.addAttribute(kCTVerticalFormsAttributeName as String, value: NSNumber(value: true as Bool), range: NSMakeRange(i, 1))
                    }
                }
                for i in 0 ..< secondLyrics!.characters.count {
                    if isChinese((secondLyrics! as NSString).substring(with: NSMakeRange(i, 1)) as NSString) {
                        secondAttrStr.addAttribute(kCTVerticalFormsAttributeName as String, value: NSNumber(value: true as Bool), range: NSMakeRange(i, 1))
                    }
                }
            }
            
            var size1st:NSSize=firstAttrStr.size()
            size1st.width=size1st.width+50
            
            var size2nd:NSSize=secondAttrStr.size()
            size2nd.width=size2nd.width+50
            
            var width: CGFloat
            var height: CGFloat
            let x: CGFloat
            let y: CGFloat
            
            if size1st.width>=size2nd.width {
                width=size1st.width
            }
            else {
                width=size2nd.width
            }
            if width > visibleSize.height {
                width = visibleSize.height
            }
            
            let rect1st: NSRect = CGRect(x: 0, y: size2nd.height+yOffset, width: width, height: size1st.height+lyricsHeightIncreasement)
            let rect2nd: NSRect = CGRect(x: 0, y: yOffset, width: width, height: size2nd.height+lyricsHeightIncreasement)
            let heightWithDock = visibleOrigin.y + visibleSize.height
            
            height=rect1st.size.height+rect2nd.size.height
            var deltaH = heightWithDock - width
            if deltaH < 8 {
                deltaH = 8
            }
            y = heightWithDock - deltaH/2
            
            //lyrics on left or right side
            if userDefaults.integer(forKey: LyricsVerticalLyricsPosition) == 0 {
                x = visibleOrigin.x
            } else {
                x = visibleOrigin.x + visibleSize.width - height - 8
            }
            
            backgroundLayer.frame = CGRect(x: x, y: y, width: width, height: height*1.15)
            backgroundLayer.transform = CATransform3DMakeRotation(CGFloat(-M_PI_2), 0, 0, 1)
            isRotated = true
            
            // whether needs rolling-over to show animation
            if rollingOver {
                firstLyricsLayer.string = firstAttrStr
                secondLyricsLayer.string = secondAttrStr
                firstLyricsLayer.frame = rect1st
                secondLyricsLayer.frame = rect2nd
                
            } else {
                firstLyricsLayer.string = secondAttrStr
                secondLyricsLayer.string = firstAttrStr
                firstLyricsLayer.frame = rect2nd
                secondLyricsLayer.frame = rect1st
            }
            rollingOver = !rollingOver
        }
    }
    
    func reflash () {
        rollingOver = !rollingOver
        displayLyrics(firstLyrics, secondLyrics: secondLyrics)
    }
    
//MARK: - clip lyrics
    
    fileprivate func clipLyrics (_ widthLimite: CGFloat) {
        var index: Int = firstLyrics!.characters.count - 1
        var leftBracket: Int?
        NSLog("Clip Lyrics")
        //1.clip when bracket found.
        Loop: while index >= 0 {
            let lastCharacter = (firstLyrics! as NSString).substring(with: NSMakeRange(index, 1))
            if lastCharacter == " " {
                index -= 1
                continue
            }
            else {
                switch lastCharacter {
                case "】":
                    leftBracket = getLeftBracketIndex(["【","】"], lastCharacterIndex: index)
                    break Loop
                case "〗":
                    leftBracket = getLeftBracketIndex(["〖","〗"], lastCharacterIndex: index)
                    break Loop
                case "」":
                    leftBracket = getLeftBracketIndex(["「","」"], lastCharacterIndex: index)
                    break Loop
                case "]":
                    leftBracket = getLeftBracketIndex(["[","]"], lastCharacterIndex: index)
                    break Loop
                case "}":
                    leftBracket = getLeftBracketIndex(["{","}"], lastCharacterIndex: index)
                    break Loop
                case ">":
                    leftBracket = getLeftBracketIndex(["<",">"], lastCharacterIndex: index)
                    break Loop
                case "）":
                    leftBracket = getLeftBracketIndex(["（","）"], lastCharacterIndex: index)
                    break Loop
                case ")":
                    leftBracket = getLeftBracketIndex(["(",")"], lastCharacterIndex: index)
                    break Loop
                default:
                    break Loop
                }
            }
        }
        if leftBracket != nil && leftBracket != -1 {
            let formerPart = (firstLyrics! as NSString).substring(with: NSMakeRange(0, leftBracket!))
            let latterPart = (firstLyrics! as NSString).substring(with: NSMakeRange(leftBracket!, index-leftBracket!+1))
            if formerPart.size(withAttributes: attrs).width<=widthLimite && latterPart.size(withAttributes: attrs).width<=widthLimite {
                firstLyrics = formerPart
                secondLyrics = latterPart
                return
            }
        }
        //2.clip when slash or comma found.
        for str in ["/","，",","] {
            let range: NSRange = (firstLyrics! as NSString).range(of: str)
            if range.length != 0 {
                let endIndex = range.location
                let startIndex = range.location + 1
                if endIndex == 0 || startIndex == firstLyrics!.characters.count {
                    continue
                }
                let formerPart = (firstLyrics! as NSString).substring(to: endIndex)
                let latterPart = (firstLyrics! as NSString).substring(from: startIndex)
                if formerPart.size(withAttributes: attrs).width<=widthLimite && latterPart.size(withAttributes: attrs).width<=widthLimite {
                    firstLyrics = formerPart
                    secondLyrics = latterPart
                    return
                }
            }
        }
        //3.clip in the first space near center of the string.
        let halfLength = firstLyrics!.characters.count/2
        var spaceRange: NSRange = (firstLyrics! as NSString).range(of: " ", options: NSString.CompareOptions.anchored, range: NSMakeRange(halfLength, firstLyrics!.characters.count - halfLength))
        if spaceRange.length == 0 {
            spaceRange = (firstLyrics! as NSString).range(of: " ", options: NSString.CompareOptions.backwards, range: NSMakeRange(0, halfLength))
        }
        if spaceRange.length != 0 {
            let endIndex = spaceRange.location
            let startIndex = spaceRange.location + 1
            if endIndex>0 && startIndex<firstLyrics!.characters.count {
                let formerPart = (firstLyrics! as NSString).substring(to: endIndex)
                let latterPart = (firstLyrics! as NSString).substring(from: startIndex)
                if formerPart.size(withAttributes: attrs).width<=widthLimite && latterPart.size(withAttributes: attrs).width<=widthLimite {
                    firstLyrics = formerPart
                    secondLyrics = latterPart
                    return
                }
            }
        }
        //4.just clip in the center
        let formerPart = (firstLyrics! as NSString).substring(to: halfLength)
        let latterPart = (firstLyrics! as NSString).substring(from: halfLength)
        firstLyrics = formerPart
        secondLyrics = latterPart
    }
    
    fileprivate func getLeftBracketIndex(_ bracket: [String], lastCharacterIndex theIndex: Int) -> Int {
        var stack: [Int] = Array()
        var index: Int = 0
        while index < theIndex {
            let char: String = (firstLyrics! as NSString).substring(with: NSMakeRange(index, 1))
            if char == bracket.first {
                stack.append(index)
            }
            else if char == bracket.last {
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

//MARK: - Notification Methods
    
    func handleScreenResolutionChange() {
        DispatchQueue.main.async { () -> Void in
            self.setScreenResolution()
            self.reflash()
        }
    }
    
//MARK: - Other Method
    
    fileprivate func isChinese (_ character: NSString) -> Bool {
        let char: UnsafePointer<Int8> = character.utf8String!
        if strlen(char) == 3 {
            return true
        } else {
            return false
        }
    }
    
    func storeWindowSize() {
        let position = self.window!.frame
        userDefaults.set(Float(position.width), forKey: LyricsConstWidth)
        userDefaults.set(Float(position.height), forKey: LyricsConstHeight)
    }
    
//MARK: - Delegate
    
    func windowDidResize(_ notification: Notification) {
        if !userDefaults.bool(forKey: LyricsUseAutoLayout) {
            reflash()
        }
    }
    
}
