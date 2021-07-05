//
//  ReverbPresets.swift
//  Aural
//
//  Copyright © 2021 Kartik Venugopal. All rights reserved.
//
//  This software is licensed under the MIT software license.
//  See the file "LICENSE" in the project root directory for license terms.
//
import Foundation

///
/// Manages a mapped collection of presets that can be applied to the Reverb effects unit.
///
class ReverbPresets: EffectsPresets<ReverbPreset> {
    
    init(persistentState: ReverbUnitPersistentState?) {
        
        let userDefinedPresets = (persistentState?.userPresets ?? []).compactMap {ReverbPreset(persistentState: $0)}
        super.init(systemDefinedPresets: [], userDefinedPresets: userDefinedPresets)
    }
}

///
/// Represents a single Reverb effects unit preset.
///
class ReverbPreset: EffectsUnitPreset {
    
    let space: ReverbSpaces
    let amount: Float
    
    init(_ name: String, _ state: EffectsUnitState, _ space: ReverbSpaces, _ amount: Float, _ systemDefined: Bool) {
        
        self.space = space
        self.amount = amount
        super.init(name, state, systemDefined)
    }
    
    init?(persistentState: ReverbPresetPersistentState) {
        
        guard let name = persistentState.name, let unitState = persistentState.state,
              let space = persistentState.space,
              let amount = persistentState.amount else {return nil}
        
        self.space = space
        self.amount = amount
        
        super.init(name, unitState, false)
    }
}
