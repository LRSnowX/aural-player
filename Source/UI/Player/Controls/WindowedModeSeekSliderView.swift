//
//  WindowedModeSeekSliderView.swift
//  Aural
//
//  Copyright © 2021 Kartik Venugopal. All rights reserved.
//
//  This software is licensed under the MIT software license.
//  See the file "LICENSE" in the project root directory for license terms.
//  
import Cocoa

class WindowedModeSeekSliderView: SeekSliderView, ColorSchemeable {
    
    // Used to display the bookmark name prompt popover
    @IBOutlet weak var seekPositionMarker: NSView!
    
    private let fontSchemesManager: FontSchemesManager = ObjectGraph.fontSchemesManager
    private let colorSchemesManager: ColorSchemesManager = ObjectGraph.colorSchemesManager
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        applyFontScheme(fontSchemesManager.systemScheme)
        applyColorScheme(colorSchemesManager.systemScheme)
    }
    
    func applyFontScheme(_ fontScheme: FontScheme) {
        
        lblTimeElapsed.font = fontSchemesManager.systemScheme.player.trackTimesFont
        lblTimeRemaining.font = fontSchemesManager.systemScheme.player.trackTimesFont
    }
    
    func applyColorScheme(_ scheme: ColorScheme) {
        
        changeSliderValueTextColor(scheme.player.sliderValueTextColor)
        changeSliderColors()
    }
    
    func changeSliderValueTextColor(_ color: NSColor) {
        
        lblTimeElapsed.textColor = Colors.Player.trackTimesTextColor
        lblTimeRemaining.textColor = Colors.Player.trackTimesTextColor
    }
    
    func changeSliderColors() {
        seekSlider.redraw()
    }
    
    // Positions the "seek position marker" view at the center of the seek slider knob.
    func positionSeekPositionMarkerView() {
        
        // Slider knob position
        let knobRect = seekSliderCell.knobRect(flipped: false)
        seekPositionMarker.setFrameOrigin(NSPoint(x: seekSlider.frame.minX + knobRect.minX, y: seekSlider.frame.minY + knobRect.minY))
    }
}
