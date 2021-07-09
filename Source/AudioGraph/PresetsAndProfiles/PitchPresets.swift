//
//  PitchShiftPresets.swift
//  Aural
//
//  Copyright © 2021 Kartik Venugopal. All rights reserved.
//
//  This software is licensed under the MIT software license.
//  See the file "LICENSE" in the project root directory for license terms.
//
import Foundation

///
/// Manages a mapped collection of presets that can be applied to the Pitch Shift effects unit.
///
class PitchShiftPresets: EffectsPresets<PitchShiftPreset> {
    
    init(persistentState: PitchShiftUnitPersistentState?) {
        
        let systemDefinedPresets = SystemDefinedPitchShiftPresetParams.allCases.map {$0.preset}
        let userDefinedPresets = (persistentState?.userPresets ?? []).compactMap {PitchShiftPreset(persistentState: $0)}
        
        super.init(systemDefinedPresets: systemDefinedPresets, userDefinedPresets: userDefinedPresets)
    }
    
    override var defaultPreset: PitchShiftPreset {systemDefinedPreset(named: SystemDefinedPitchShiftPresetParams.normal.rawValue)!}
}

///
/// Represents a single Pitch Shift effects unit preset.
///
class PitchShiftPreset: EffectsUnitPreset {
    
    let pitch: Float
    let overlap: Float
    
    init(_ name: String, _ state: EffectsUnitState, _ pitch: Float, _ overlap: Float, _ systemDefined: Bool) {
        
        self.pitch = pitch
        self.overlap = overlap
        super.init(name, state, systemDefined)
    }
    
    init?(persistentState: PitchShiftPresetPersistentState) {
        
        guard let name = persistentState.name, let unitState = persistentState.state,
              let pitch = persistentState.pitch else {return nil}
        
        self.pitch = pitch
        self.overlap = persistentState.overlap ?? AudioGraphDefaults.pitchOverlap
        
        super.init(name, unitState, false)
    }
}

///
/// An enumeration of system-defined (built-in) Pitch Shift presets the user can choose from.
///
fileprivate enum SystemDefinedPitchShiftPresetParams: String, CaseIterable {
    
    case normal = "Normal"  // default
    case happyLittleGirl = "Happy little girl"
    case chipmunk = "Chipmunk"
    case oneOctaveUp = "+1 8ve"
    case twoOctavesUp = "+2 8ve"
    
    case deep = "A bit deep"
    case robocop = "Robocop"
    case oneOctaveDown = "-1 8ve"
    case twoOctavesDown = "-2 8ve"
    
    // Converts a user-friendly display name to an instance of PitchShiftPresets
    static func fromDisplayName(_ displayName: String) -> SystemDefinedPitchShiftPresetParams {
        return SystemDefinedPitchShiftPresetParams(rawValue: displayName) ?? .normal
    }
    
    var pitch: Float {
        
        switch self {
            
        case .normal:   return 0
            
        case .happyLittleGirl: return 0.3 * ValueConversions.pitch_UIToAudioGraph
            
        case .chipmunk: return 0.5 * ValueConversions.pitch_UIToAudioGraph
            
        case .oneOctaveUp:  return 1 * ValueConversions.pitch_UIToAudioGraph
            
        case .twoOctavesUp: return 2 * ValueConversions.pitch_UIToAudioGraph
            
        case .deep: return -0.3 * ValueConversions.pitch_UIToAudioGraph
            
        case .robocop:  return -0.5 * ValueConversions.pitch_UIToAudioGraph
            
        case .oneOctaveDown:    return -1 * ValueConversions.pitch_UIToAudioGraph
            
        case .twoOctavesDown:   return -2 * ValueConversions.pitch_UIToAudioGraph
            
        }
    }
    
    var overlap: Float {
        return 8
    }
    
    var state: EffectsUnitState {
        return .active
    }
    
    var preset: PitchShiftPreset {
        PitchShiftPreset(rawValue, state, pitch, overlap, true)
    }
}
