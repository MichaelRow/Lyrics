//
//  UserDefaults+Subscript.swift
//  LyricsX
//
//  Created by Michael Row on 2017/8/12.
//  Copyright © 2017年 Eru. All rights reserved.
//

import Foundation

extension UserDefaults {
    
    subscript(key: PreferenceKey<Bool>) -> Bool {
        set { set(newValue, forKey: key.identifier) }
        get { return bool(forKey: key.identifier) }
    }
    
    subscript(key: PreferenceKey<Int>) -> Int {
        set { set(newValue, forKey: key.identifier) }
        get { return integer(forKey: key.identifier) }
    }
    
    subscript(key: PreferenceKey<Double>) -> Double {
        set { set(newValue, forKey: key.identifier) }
        get { return double(forKey: key.identifier) }
    }
    
    subscript(key: PreferenceKey<Float>) -> Float {
        set { set(newValue, forKey: key.identifier) }
        get { return float(forKey: key.identifier) }
    }
    
    subscript(key: PreferenceKey<Data>) -> Data? {
        set { set(newValue, forKey: key.identifier) }
        get { return data(forKey: key.identifier) }
    }
    
    subscript(key: PreferenceKey<String>) -> String? {
        set { set(newValue, forKey: key.identifier) }
        get { return string(forKey: key.identifier) }
    }

    subscript(key: PreferenceKey<Any>) -> Any? {
        set { set(newValue, forKey: key.identifier) }
        get { return value(forKey: key.identifier) }
    }
    
    subscript<T>(key: PreferenceKey<[T]>) -> [T]? {
        set { set(newValue, forKey: key.identifier) }
        get { return array(forKey: key.identifier) as? [T]}
    }
    
    func remove<T>(key: PreferenceKey<T>) {
        removeObject(forKey: key.identifier)
    }
}
