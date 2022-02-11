//
//  FloatingPointExtensions.swift
//  Aural
//
//  Copyright © 2021 Kartik Venugopal. All rights reserved.
//
//  This software is licensed under the MIT software license.
//  See the file "LICENSE" in the project root directory for license terms.
//
import CoreGraphics

extension FloatingPoint {
    
    func clamped(to range: ClosedRange<Self>) -> Self {
        
        if range.contains(self) {return self}
        
        if self < range.lowerBound {
            return range.lowerBound
        }
        
        if self > range.upperBound {
            return range.upperBound
        }
        
        return self
    }
}

extension Double {
    
    var roundedInt: Int {lround(self)}
    
    var roundedUInt: UInt {UInt(lround(self))}
    
    var roundedUInt64: UInt64 {UInt64(lround(self))}
    
    var floorInt: Int {Int(floor(self))}
}

extension Float {
    
    var roundedInt: Int {lroundf(self)}
    
    var roundedUInt: UInt {UInt(lroundf(self))}
    
    var roundedUInt64: UInt64 {UInt64(lroundf(self))}
    
    var floorInt: Int {Int(floorf(self))}
}

extension CGFloat {
    var roundedInt: Int {lroundf(Float(self))}
}
