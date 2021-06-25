//
//  VariableRateNode.swift
//  Aural
//
//  Copyright © 2021 Kartik Venugopal. All rights reserved.
//
//  This software is licensed under the MIT software license.
//  See the file "LICENSE" in the project root directory for license terms.
//
import Foundation
import AVFoundation

///
/// Custom audio graph node that encapsulates all logic for variable playback rate.
///
/// The node offers 2 variable rate modes:
///
/// - Variable rate without pitch shift (i.e. playback rate is altered, without change in pitch)
/// - Variable rate with pitch shift (i.e. both playback rate and pitch are altered simultaneously and in sync)
///
class VariableRateNode {
 
    let timePitchNode: AVAudioUnitTimePitch
    let variNode: AVAudioUnitVarispeed
    
    private static let octavesToCents: Float = 1200
    
    init() {
        
        timePitchNode = AVAudioUnitTimePitch()
        variNode = AVAudioUnitVarispeed()
        
        bypass = AudioGraphDefaults.timeState != .active
        rate = AudioGraphDefaults.timeStretchRate
        shiftPitch = AudioGraphDefaults.timeShiftPitch
        overlap = AudioGraphDefaults.timeOverlap
    }
    
    var bypass: Bool {
        
        didSet {
            
            if self.bypass {
                [timePitchNode, variNode].forEach({$0.bypass = true})
            } else {
                timePitchNode.bypass = self.shiftPitch
                variNode.bypass = !self.shiftPitch
            }
        }
    }
    
    var rate: Float {
        
        didSet {
            
            timePitchNode.rate = self.rate
            variNode.rate = self.rate
        }
    }
    
    var shiftPitch: Bool {
        
        didSet {
            
            if !self.bypass {
                
                timePitchNode.bypass = self.shiftPitch
                variNode.bypass = !self.shiftPitch
            }
        }
    }
    
    var pitch: Float {
        return self.shiftPitch ? Self.octavesToCents * log2(self.rate) : 0
    }
    
    var overlap: Float {
        didSet {timePitchNode.overlap = self.overlap}
    }
}
