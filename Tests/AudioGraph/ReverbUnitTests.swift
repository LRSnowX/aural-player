//
//  ReverbUnitTests.swift
//  Tests
//
//  Copyright © 2021 Kartik Venugopal. All rights reserved.
//
//  This software is licensed under the MIT software license.
//  See the file "LICENSE" in the project root directory for license terms.
//  
import XCTest

class ReverbUnitTests: AudioGraphTestCase {
    
    func testInit() {
        
        for unitState in EffectsUnitState.allCases {
            
            for space in ReverbSpaces.allCases {
                
                for _ in 1...1000 {
                    
                    let persistentState = ReverbUnitPersistentState(state: unitState,
                                                                    userPresets: randomReverbPresets(unitState: .active),
                                                                    space: space,
                                                                    amount: randomReverbAmount())
                    
                    doTestInit(persistentState: persistentState)
                }
            }
        }
    }
    
    private func doTestInit(persistentState: ReverbUnitPersistentState) {
        
        let reverbUnit = ReverbUnit(persistentState: persistentState)
        validate(reverbUnit, persistentState: persistentState)
    }
}

// MARK: Equality comparison for model objects -----------------------------

extension ReverbPreset: Equatable, Hashable {
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
    
    static func == (lhs: ReverbPreset, rhs: ReverbPreset) -> Bool {
        
        lhs.state == rhs.state && lhs.name == rhs.name &&
            Float.approxEquals(lhs.amount, rhs.amount, accuracy: 0.001) &&
            lhs.space == rhs.space
    }
}
