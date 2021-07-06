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
    let seekPositionDisplayType: ControlBarSeekPositionDisplayType?
}
