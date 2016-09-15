//
//  ChineseConverter.swift
//  Lyrics
//
//  Created by Eru on 15/11/10.
//  Copyright © 2015年 Eru. All rights reserved.
//

import Cocoa

func convertToSC(_ input: String) -> String {
    let profilePath: NSString = Bundle.main.path(forResource: "t2s", ofType: "json")! as NSString
    return convertToChineseUsingProfile(profilePath,inputStr: input as NSString)
}

func convertToTC(_ input: String) -> String {
    let profilePath: NSString = Bundle.main.path(forResource: "s2t", ofType: "json")! as NSString
    return convertToChineseUsingProfile(profilePath,inputStr: input as NSString)
}

func convertToTC_TW(_ input: String) -> String {
    let profilePath: NSString = Bundle.main.path(forResource: "s2tw", ofType: "json")! as NSString
    return convertToChineseUsingProfile(profilePath,inputStr: input as NSString)
}

func convertToTC_HK(_ input: String) -> String {
    let profilePath: NSString = Bundle.main.path(forResource: "s2hk", ofType: "json")! as NSString
    return convertToChineseUsingProfile(profilePath,inputStr: input as NSString)
}

private func convertToChineseUsingProfile(_ profile: NSString, inputStr: NSString) -> String {
    let cc: opencc_t = opencc_open(profile.utf8String)
    let cInput: UnsafePointer<Int8> = inputStr.utf8String!
    let cOutputStr: UnsafeMutablePointer<Int8> = opencc_convert_utf8(cc, cInput, Int(strlen(cInput)))
    let outputStr: String? = String(cString: cOutputStr)
    opencc_convert_utf8_free(cOutputStr)
    opencc_close(cc)
    if outputStr == nil {
        return ""
    } else {
        return outputStr!
    }
}
