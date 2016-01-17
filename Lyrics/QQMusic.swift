//
//  QQMusic.swift
//  LrcSeeker
//
//  Created by Eru on 15/12/27.
//  Copyright © 2015年 Eru. All rights reserved.
//

import Cocoa

class QQMusic: NSObject {

    var currentSongs: [SongInfos] = Array()
    var date: NSDate!
    
    func getLyricsWithTitle(title: String, artist: String, songID: String, titleForSearching: String, andArtistForSearching artistForSearching: String) {
        currentSongs.removeAll()
        date = NSDate()
        let dateWhenSearch = date
        
        NSLog("QQ Start to search Lrcs")
        let urlString: String = "http://s.music.qq.com/fcgi-bin/music_search_new_platform?t=0&n=10&aggr=1&cr=1&loginUin=0&format=json&inCharset=GB2312&outCharset=utf-8&notice=0&platform=jqminiframe.json&needNewCode=0&p=1&catZhida=0&remoteplace=sizer.newclient.next_song&w=\(titleForSearching) \(artistForSearching)"
        let convertedURLStr = urlString.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLFragmentAllowedCharacterSet())
        let req: NSMutableURLRequest = NSMutableURLRequest(URL: NSURL(string: convertedURLStr!)!, cachePolicy: .ReloadIgnoringLocalCacheData, timeoutInterval: 15)
        req.HTTPMethod = "GET"
        req.addValue("text/xml", forHTTPHeaderField: "Content-Type")
        let session: NSURLSession = NSURLSession.sharedSession()
        let dataTask: NSURLSessionDataTask = session.dataTaskWithRequest(req) { (data, response, error) -> Void in
            if response == nil {
                return
            }
            let httpResponse = response as! NSHTTPURLResponse
            let statusCode: Int = httpResponse.statusCode
            if !(statusCode>=200 && statusCode<300) || error != nil || data == nil {
                return
            }
            let rootDic: [String:AnyObject]
            do {
                rootDic = try NSJSONSerialization.JSONObjectWithData(data!, options: [.MutableContainers]) as! [String : AnyObject]
            } catch let theError as NSError {
                NSLog("%@", theError.localizedDescription)
                return
            }
            let dataDic = rootDic["data"] as! [String:AnyObject]
            let songDic = dataDic["song"] as! [String:AnyObject]
            let listArray = songDic["list"] as! [NSDictionary]
            var resultArray = [SongInfos]()
            for theDic in listArray {
                let info = SongInfos()
                info.songTitle = theDic.objectForKey("fsong") as! String
                info.artist = theDic.objectForKey("fsinger") as! String
                let fStr = theDic.objectForKey("f") as! NSString
                let theRange = fStr.rangeOfString("|")
                if theRange.length == 0 {
                    return
                }
                let lrcCode: String = fStr.substringToIndex(theRange.location)
                let lrcXMLURL: String = "http://music.qq.com/miniportal/static/lyric/\((lrcCode as NSString).integerValue%100)/\(lrcCode).xml"
                let lrcData: NSData? = NSData(contentsOfURL: NSURL(string: lrcXMLURL as String)!)
                if lrcData == nil {
                    continue
                } else {
                    let parser = XMLParserForQQ()
                    let lyricsContents: String? = parser.stringWithData(lrcData!)
                    if lyricsContents == nil {
                        continue
                    }
                    info.lyric = lyricsContents!
                    resultArray.append(info)
                }
            }
            if resultArray.count > 0 && self.date.isEqualToDate(dateWhenSearch) {
                self.currentSongs = resultArray
                let userInfo: [String:AnyObject] = [
                    "source" : NSNumber(int: 5),
                    "title" : title,
                    "artist" : artist,
                    "songID" : songID
                ]
                NSNotificationCenter.defaultCenter().postNotificationName(LrcLoadedNotification, object: nil, userInfo: userInfo)
            }
        }
        dataTask.resume()
    }
}
