//
//  FilterUnitDelegate.swift
//  Aural
//
//  Copyright © 2021 Kartik Venugopal. All rights reserved.
//
//  This software is licensed under the MIT software license.
//  See the file "LICENSE" in the project root directory for license terms.
//
import AVFoundation

///
/// A delegate representing the Filter effects unit.
///
/// Acts as a middleman between the Effects UI and the Filter effects unit,
/// providing a simplified interface / facade for the UI layer to control the Filter effects unit.
///
/// - SeeAlso: `FilterUnit`
/// - SeeAlso: `FilterUnitDelegateProtocol`
///
class FilterUnitDelegate: EffectsUnitDelegate<FilterUnit>, FilterUnitDelegateProtocol {

    var presets: FilterPresets {unit.presets}
    
    var bands: [FilterBand] {
        
        get {unit.bands}
        set {unit.bands = newValue}
    }
    
    func addBand(ofType bandType: FilterBandType) -> (band: FilterBand, index: Int) {
        
        let newBand: FilterBand = .ofType(bandType)
        return (newBand, unit.addBand(newBand))
    }
    
    subscript(_ index: Int) -> FilterBand {
        
        get {unit[index]}
        set(newBand) {unit[index] = newBand}
    }
    
    func removeBands(atIndices indices: IndexSet) {
        unit.removeBands(at: indices)
    }
}
