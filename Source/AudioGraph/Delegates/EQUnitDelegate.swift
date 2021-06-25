//
//  EQUnitDelegate.swift
//  Aural
//
//  Copyright © 2021 Kartik Venugopal. All rights reserved.
//
//  This software is licensed under the MIT software license.
//  See the file "LICENSE" in the project root directory for license terms.
//
import Foundation

class EQUnitDelegate: EffectsUnitDelegate<EQUnit>, EQUnitDelegateProtocol {
    
    let preferences: SoundPreferences
    
    init(_ unit: EQUnit, _ preferences: SoundPreferences) {
        
        self.preferences = preferences
        super.init(unit)
    }
    
    var type: EQType {
        
        get {unit.type}
        set(newType) {unit.type = newType}
    }
    
    var globalGain: Float {
        
        get {unit.globalGain}
        set {unit.globalGain = newValue}
    }
    
    var bands: [Float] {
        
        get {unit.bands}
        set {unit.bands = newValue}
    }
    
    var presets: EQPresets {return unit.presets}
    
    func setBand(_ index: Int, gain: Float) {
        unit.setBand(index, gain: gain)
    }
    
    func increaseBass() -> [Float] {
        
        ensureEQActive()
        return unit.increaseBass(preferences.eqDelta)
    }
    
    func decreaseBass() -> [Float] {
        
        ensureEQActive()
        return unit.decreaseBass(preferences.eqDelta)
    }
    
    func increaseMids() -> [Float] {
        
        ensureEQActive()
        return unit.increaseMids(preferences.eqDelta)
    }
    
    func decreaseMids() -> [Float] {
        
        ensureEQActive()
        return unit.decreaseMids(preferences.eqDelta)
    }
    
    func increaseTreble() -> [Float] {
        
        ensureEQActive()
        return unit.increaseTreble(preferences.eqDelta)
    }
    
    func decreaseTreble() -> [Float] {
        
        ensureEQActive()
        return unit.decreaseTreble(preferences.eqDelta)
    }
    
    private func ensureEQActive() {
        
        // If the EQ unit is currently inactive, activate it
        if state != .active {
            
            _ = toggleState()
            
            // Reset to "flat" preset (because it is equivalent to an inactive EQ)
            bands = presets.defaultPreset.bands
        }
    }
}
