//
//  Macros.swift
//  LrcMaker
//
//  Created by Eru on 15/12/4.
//  Copyright © 2015年 Eru. All rights reserved.
//

import Foundation

//disable NSLog all over the codes in release builds
#if !DEBUG
    func NSLog(format: String, _ args: CVarArgType...) {}
#endif

