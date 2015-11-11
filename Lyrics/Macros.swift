//
//  Macros.swift
//  Lyrics
//
//  Created by Eru on 15/11/6.
//  Copyright © 2015年 Eru. All rights reserved.
//

import Foundation

//disable NSLog all over the codes
#if !DEBUG
    func NSLog(format: String, _ args: CVarArgType...) {}
#endif

//Globle Const Variables
let LYRICS_ATTRIBUTES_CHANGED:String="LYRICS_ATTRIBUTES_CHANGED"