//
//  PitchShiftUnitView.swift
//  Aural
//
//  Copyright © 2021 Kartik Venugopal. All rights reserved.
//
//  This software is licensed under the MIT software license.
//  See the file "LICENSE" in the project root directory for license terms.
//
import Cocoa

class PitchShiftUnitView: NSView {
    
    // ------------------------------------------------------------------------
    
    // MARK: UI fields

    @IBOutlet weak var pitchSlider: EffectsUnitSlider!
    
    @IBOutlet weak var lblOctaves: NSTextField!
    @IBOutlet weak var lblSemitones: NSTextField!
    @IBOutlet weak var lblCents: NSTextField!
    
    @IBOutlet weak var btnIncreaseByOctave: TintedImageButton!
    @IBOutlet weak var btnIncreaseBySemitone: TintedImageButton!
    @IBOutlet weak var btnIncreaseByCent: TintedImageButton!
    
    @IBOutlet weak var btnDecreaseByOctave: TintedImageButton!
    @IBOutlet weak var btnDecreaseBySemitone: TintedImageButton!
    @IBOutlet weak var btnDecreaseByCent: TintedImageButton!
    
    private var functionButtons: [TintedImageButton] = []
    
    // ------------------------------------------------------------------------
    
    // MARK: Properties
    
    var pitch: PitchShift {
        
        get {
            PitchShift(fromCents: pitchSlider.integerValue)
        }
        
        set {
            
            pitchSlider.integerValue = newValue.asCents
            updateLabels(pitch: newValue)
        }
    }
    
    private func updateLabels(pitch: PitchShift) {
        
        lblOctaves.stringValue = "\(pitch.octaves.signedString)"
        lblSemitones.stringValue = "\(pitch.semitones.signedString)"
        lblCents.stringValue = "\(pitch.cents.signedString)"
    }
    
    // ------------------------------------------------------------------------
    
    // MARK: View initialization
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        functionButtons = [btnIncreaseByOctave, btnIncreaseBySemitone, btnIncreaseByCent, btnDecreaseByOctave, btnDecreaseBySemitone, btnDecreaseByCent]
    }
    
    func initialize(stateFunction: @escaping EffectsUnitStateFunction) {
        fxUnitStateObserverRegistry.registerObserver(pitchSlider, forFXUnit: audioGraphDelegate.pitchShiftUnit)
    }
    
    // ------------------------------------------------------------------------
    
    // MARK: View update
    
    func pitchUpdated() -> PitchShift {
        
        let newPitch = self.pitch
        updateLabels(pitch: newPitch)
        return newPitch
    }
    
    func applyPreset(_ preset: PitchShiftPreset) {
        pitch = PitchShift(fromCents: preset.pitch)
    }
    
    // ------------------------------------------------------------------------
    
    // MARK: Theming
    
    func redrawSliders() {
        pitchSlider.redraw()
    }
    
    func applyColorScheme(_ scheme: ColorScheme) {
        
        redrawSliders()
        changeFunctionButtonColor(scheme.buttonColor)
    }
    
    func changeFunctionButtonColor(_ color: NSColor) {
//        functionButtons.forEach {$0.reTint()}
    }
}
