//
//  PreferencesSliderCell.swift
//  Aural
//
//  Copyright © 2021 Kartik Venugopal. All rights reserved.
//
//  This software is licensed under the MIT software license.
//  See the file "LICENSE" in the project root directory for license terms.
//
import Cocoa

// Cell for sliders on the Preferences panel
class PreferencesSliderCell: HorizontalSliderCell {
    
    override var barRadius: CGFloat {1.5}
    override var barInsetY: CGFloat {0.5}
    
    override var backgroundGradient: NSGradient {Colors.Effects.defaultSliderBackgroundGradient}
    override var foregroundGradient: NSGradient {Colors.Effects.defaultSliderBackgroundGradient}
    
    override var knobColor: NSColor {.white80Percent}
}
