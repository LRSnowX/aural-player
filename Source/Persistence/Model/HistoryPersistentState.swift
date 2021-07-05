//
//  HistoryPersistentState.swift
//  Aural
//
//  Copyright © 2021 Kartik Venugopal. All rights reserved.
//
//  This software is licensed under the MIT software license.
//  See the file "LICENSE" in the project root directory for license terms.
//
import Foundation

struct HistoryPersistentState: Codable {
    
    let recentlyAdded: [HistoryItemPersistentState]?
    let recentlyPlayed: [HistoryItemPersistentState]?
}

struct HistoryItemPersistentState: Codable {
    
    let file: URLPath?
    let name: String?
    let time: DateString?
    
    init(item: HistoryItem) {
        
        self.file = item.file.path
        self.name = item.displayName
        self.time = item.time.serializableString()
    }
}

extension HistoryDelegate: PersistentModelObject {
    
    var persistentState: HistoryPersistentState {
        
        let recentlyAdded = allRecentlyAddedItems().map {HistoryItemPersistentState(item: $0)}
        let recentlyPlayed = allRecentlyPlayedItems().map {HistoryItemPersistentState(item: $0)}
        
        return HistoryPersistentState(recentlyAdded: recentlyAdded, recentlyPlayed: recentlyPlayed)
    }
}
