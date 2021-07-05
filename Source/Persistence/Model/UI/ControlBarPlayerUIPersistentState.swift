//
//  ControlBarPlayerUIPersistentState.swift
//  Aural
//
//  Copyright © 2021 Kartik Venugopal. All rights reserved.
//
//  This software is licensed under the MIT software license.
//  See the file "LICENSE" in the project root directory for license terms.
//  
import Foundation

struct ControlBarPlayerUIPersistentState: Codable {
    
    let windowFrame: NSRectPersistentState?
    let cornerRadius: CGFloat?
    
    let trackInfoScrollingEnabled: Bool?
    
    let showSeekPosition: Bool?
    let seekPositionDisplayType: SeekPositionDisplayType?
}

extension ControlBarPlayerViewState {
    
    static func initialize(_ persistentState: ControlBarPlayerUIPersistentState?) {
        
        windowFrame = persistentState?.windowFrame?.toNSRect()
        cornerRadius = persistentState?.cornerRadius ?? defaultCornerRadius
        
        trackInfoScrollingEnabled = persistentState?.trackInfoScrollingEnabled ?? true
        
        showSeekPosition = persistentState?.showSeekPosition ?? true
        seekPositionDisplayType = persistentState?.seekPositionDisplayType ?? .timeElapsed
    }
    
    static var persistentState: ControlBarPlayerUIPersistentState {
        
        var windowFrame: NSRectPersistentState? = nil
        
        if let frame = self.windowFrame {
            windowFrame = NSRectPersistentState(rect: frame)
        }
        
        return ControlBarPlayerUIPersistentState(windowFrame: windowFrame,
                                                 cornerRadius: cornerRadius,
                                                 trackInfoScrollingEnabled: trackInfoScrollingEnabled,
                                                 showSeekPosition: showSeekPosition,
                                                 seekPositionDisplayType: seekPositionDisplayType)
    }
}
