//
//  GlobalDefine.swift
//  LyricsX
//
//  Created by Eru on 2017/4/23.
//  Copyright © 2017年 Eru. All rights reserved.
//

import Foundation

#if !DEBUG
    func NSLog(_ format: String, _ args: CVarArg...) {}
    func print(_ item: Any) {}
#endif
