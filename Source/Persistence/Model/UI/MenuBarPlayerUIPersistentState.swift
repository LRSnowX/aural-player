//
//  MenuBarPlayerUIPersistentState.swift
//  Aural
//
//  Copyright © 2021 Kartik Venugopal. All rights reserved.
//
//  This software is licensed under the MIT software license.
//  See the file "LICENSE" in the project root directory for license terms.
//
import Foundation

struct MenuBarPlayerUIPersistentState: Codable {
    
    let showAlbumArt: Bool?
    let showArtist: Bool?
    let showAlbum: Bool?
    let showCurrentChapter: Bool?
}
