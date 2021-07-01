//
//  RemoteControlPreferences.swift
//  Aural
//
//  Copyright © 2021 Kartik Venugopal. All rights reserved.
//
//  This software is licensed under the MIT software license.
//  See the file "LICENSE" in the project root directory for license terms.
//
import Foundation

class RemoteControlPreferences: PersistentPreferencesProtocol {
    
    var enabled: Bool
    var trackChangeOrSeekingOption: TrackChangeOrSeekingOptions
    
    private static let keyPrefix: String = "controls.remoteControl"
    
    private static let key_enabled: String = "\(keyPrefix).enabled"
    private static let key_trackChangeOrSeekingOption: String = "\(keyPrefix).trackChangeOrSeekingOption"
    
    private typealias Defaults = PreferencesDefaults.Controls.RemoteControl
    
    internal required init(_ dict: [String: Any]) {
        
        enabled = dict[Self.key_enabled, Bool.self] ?? Defaults.enabled
        
        trackChangeOrSeekingOption = dict.enumValue(forKey: Self.key_trackChangeOrSeekingOption,
                                                    ofType: TrackChangeOrSeekingOptions.self) ?? Defaults.trackChangeOrSeekingOption
    }
    
    func persist(to defaults: UserDefaults) {
        
        defaults[Self.key_enabled] = enabled 
        defaults[Self.key_trackChangeOrSeekingOption] = trackChangeOrSeekingOption.rawValue 
    }
}

enum TrackChangeOrSeekingOptions: String {
    
    case trackChange
    case seeking
}
