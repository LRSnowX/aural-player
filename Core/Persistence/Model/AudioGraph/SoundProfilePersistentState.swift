//
//  SoundProfilePersistentState.swift
//  Aural
//
//  Copyright © 2021 Kartik Venugopal. All rights reserved.
//
//  This software is licensed under the MIT software license.
//  See the file "LICENSE" in the project root directory for license terms.
//
import Foundation

///
/// Persistent state for a single sound profile.
///
/// - SeeAlso:  `SoundProfile`
///
struct SoundProfilePersistentState: Codable {
    
    let file: URLPath?
    
    let volume: Float?
    let pan: Float?
    let effects: MasterPresetPersistentState?
    
    init(file: URLPath?, volume: Float?, pan: Float?, effects: MasterPresetPersistentState?) {
        
        self.file = file
        self.volume = volume
        self.pan = pan
        self.effects = effects
    }
    
    init(profile: SoundProfile) {
        
        self.file = profile.file.path
        self.volume = profile.volume
        self.pan = profile.pan
        self.effects = MasterPresetPersistentState(preset: profile.effects)
    }
}
