//
//  DelayUnit.swift
//  Aural
//
//  Copyright © 2021 Kartik Venugopal. All rights reserved.
//
//  This software is licensed under the MIT software license.
//  See the file "LICENSE" in the project root directory for license terms.
//
import AVFoundation

///
/// An effects unit that produces an echo effect by repeatedly
/// replaying the original input signal after a configurable delay. Each replayed
/// signal decays over time, creating a repeating and decaying echo.
///
/// - SeeAlso: `DelayUnitProtocol`
///
class DelayUnit: EffectsUnit, DelayUnitProtocol {
    
    private let node: AVAudioUnitDelay = AVAudioUnitDelay()
    let presets: DelayPresets
    
    init(persistentState: DelayUnitPersistentState?) {
        
        presets = DelayPresets(persistentState: persistentState)
        super.init(.delay, persistentState?.state ?? AudioGraphDefaults.delayState)
        
        time = persistentState?.time ?? AudioGraphDefaults.delayTime
        amount = persistentState?.amount ?? AudioGraphDefaults.delayAmount
        feedback = persistentState?.feedback ?? AudioGraphDefaults.delayFeedback
        lowPassCutoff = persistentState?.lowPassCutoff ?? AudioGraphDefaults.delayLowPassCutoff
    }
    
    override var avNodes: [AVAudioNode] {[node]}
    
    override func reset() {
        node.reset()
    }
    
    var amount: Float {
        
        get {node.wetDryMix}
        set {node.wetDryMix = newValue}
    }
    
    var time: Double {
        
        get {node.delayTime}
        set {node.delayTime = newValue}
    }
    
    var feedback: Float {
        
        get {node.feedback}
        set {node.feedback = newValue}
    }
    
    var lowPassCutoff: Float {
        
        get {node.lowPassCutoff}
        set {node.lowPassCutoff = newValue}
    }
    
    override func stateChanged() {
        
        super.stateChanged()
        node.bypass = !isActive
    }
    
    override func savePreset(_ presetName: String) {
        presets.addPreset(DelayPreset(presetName, .active, amount, time, feedback, lowPassCutoff, false))
    }
    
    override func applyPreset(_ presetName: String) {
        
        if let preset = presets.preset(named: presetName) {
            applyPreset(preset)
        }
    }
    
    func applyPreset(_ preset: DelayPreset) {
        
        time = preset.time
        amount = preset.amount
        feedback = preset.feedback
        lowPassCutoff = preset.lowPassCutoff
    }
    
    var settingsAsPreset: DelayPreset {
        DelayPreset("delaySettings", state, amount, time, feedback, lowPassCutoff, false)
    }
    
    var persistentState: DelayUnitPersistentState {

        DelayUnitPersistentState(state: state,
                                 userPresets: presets.userDefinedPresets.map {DelayPresetPersistentState(preset: $0)},
                                 amount: amount,
                                 time: time,
                                 feedback: feedback,
                                 lowPassCutoff: lowPassCutoff)
    }
}
