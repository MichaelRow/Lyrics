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
    var date: Date!
    
    func getLyricsWithTitle(_ title: String, artist: String, songID: String, titleForSearching: String, andArtistForSearching artistForSearching: String) {
        currentSongs.removeAll()
        date = Date()
        let dateWhenSearch = date
        
        NSLog("QQ Start to search Lrcs")
        let urlString: String = "http://s.music.qq.com/fcgi-bin/music_search_new_platform?t=0&n=10&aggr=1&cr=1&loginUin=0&format=json&inCharset=GB2312&outCharset=utf-8&notice=0&platform=jqminiframe.json&needNewCode=0&p=1&catZhida=0&remoteplace=sizer.newclient.next_song&w=\(titleForSearching) \(artistForSearching)"
        let convertedURLStr = urlString.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlFragmentAllowed)
        let req: NSMutableURLRequest = NSMutableURLRequest(url: URL(string: convertedURLStr!)!, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 15)
        req.httpMethod = "GET"
        req.addValue("text/xml", forHTTPHeaderField: "Content-Type")
        let aDataTask = URLSession.shared.dataTask(with: req as URLRequest, completionHandler: { (data, response, error) -> Void in
            if response == nil {
                return
            }
            let httpResponse = response as! HTTPURLResponse
            let statusCode: Int = httpResponse.statusCode
            if !(statusCode>=200 && statusCode<300) || error != nil || data == nil {
                return
            }
            let rootDic: [String:AnyObject]
            do {
                rootDic = try JSONSerialization.jsonObject(with: data!, options: [.mutableContainers]) as! [String : AnyObject]
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
                info.songTitle = theDic.object(forKey: "fsong") as! String
                info.artist = theDic.object(forKey: "fsinger") as! String
                let fStr = theDic.object(forKey: "f") as! String
                let theRange = fStr.range(of: "|")
                if theRange == nil {
                    return
                }
                let lrcCode: String = fStr.substring(to: theRange!.lowerBound)
                let lrcXMLURL: String = "http://music.qq.com/miniportal/static/lyric/\((lrcCode as NSString).integerValue%100)/\(lrcCode).xml"
                let lrcData: Data?
                if let downloadURL = URL(string: lrcXMLURL) {
                    lrcData = try? Data(contentsOf: downloadURL)
                } else {
                    lrcData = nil
                }
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
            if resultArray.count > 0 && self.date == dateWhenSearch {
                self.currentSongs = resultArray
                let userInfo: [String : Any] = [
                    "source" : NSNumber(value: 5 as Int32),
                    "title"  : title,
                    "artist" : artist,
                    "songID" : songID
                ]
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "LrcLoaded"), object: nil, userInfo: userInfo)
            }
        }) 
        aDataTask.resume()
    }
}
