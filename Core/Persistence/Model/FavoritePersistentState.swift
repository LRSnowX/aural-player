//
//  FavoritePersistentState.swift
//  Aural
//
//  Copyright © 2021 Kartik Venugopal. All rights reserved.
//
//  This software is licensed under the MIT software license.
//  See the file "LICENSE" in the project root directory for license terms.
//
import Foundation

///
/// Persistent state for a single item in the **Favorites** list.
///
/// - SeeAlso: `Favorite`
///
struct FavoritePersistentState: Codable {

    let file: URL?   // URL path
    let name: String?
    
    init(favorite: Favorite) {
        
        self.file = favorite.file
        self.name = favorite.name
    }
}
