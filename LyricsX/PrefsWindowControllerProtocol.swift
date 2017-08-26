//
//  PrefsWindowControllerProtocol.swift
//  PrefsWindowController
//
//  Created by Eru on 2016/12/31.
//
//

import Cocoa

@objc public protocol PrefsWindowControllerProtocol {
    /// The identifier of the prefs view controller.
    func preferencesIdentifier() -> String
    
    /// The title of the prefs view controller.
    func preferencesTitle() -> String
    
    /// The icon of the prefs view controller.
    func preferencesIcon() -> NSImage
    
    /// Ask the prefs view controller if can resign active view.
    @objc optional func canResignActiveView() -> Bool
    
    /// Call when canResignActiveView returns false.
    @objc optional func refuseResignActiveView()
    
    /// Ask the prefs view controller if can close prefs window.
    @objc optional func canClosePrefsWindow() -> Bool
    
    /// Call when canClosePrefsWindow returns false.
    @objc optional func refuseClosePrefsWindow()
    
    /// The prefs view controller's first responder.
    @objc optional func firstResponder() -> NSResponder
    
    /// The tooltip of the prefs view controller.
    @objc optional func preferencesToolTip() -> String
}
