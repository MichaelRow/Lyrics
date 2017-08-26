//
//  Identiferable.swift
//  LyricsX
//
//  Created by Michael Row on 2017/8/12.
//  Copyright © 2017年 Eru. All rights reserved.
//

import Foundation

protocol Identiferable { }

extension Identiferable where Self: RawRepresentable {
    
    var identifier: String {
        return "\(Self.self).\(rawValue)"
    }
    
}
