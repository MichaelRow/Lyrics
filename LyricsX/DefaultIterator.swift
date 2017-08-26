//
//  DefaultIterator.swift
//  LyricsX
//
//  Created by lialong on 2017/8/16.
//  Copyright © 2017年 Eru. All rights reserved.
//

import Foundation

protocol DefaultIterator {
    
    associatedtype Iterator: IteratorProtocol
    
    var defaultIterator: Iterator { get }
    
    func resetIterator()
    
}
