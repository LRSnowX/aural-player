//
//  MusicBrainzCachePersistentState.swift
//  Aural
//
//  Copyright © 2021 Kartik Venugopal. All rights reserved.
//
//  This software is licensed under the MIT software license.
//  See the file "LICENSE" in the project root directory for license terms.
//
import Foundation

struct MusicBrainzCachePersistentState: Codable {

    let releases: [MusicBrainzCacheEntryPersistentState]?
    let recordings: [MusicBrainzCacheEntryPersistentState]?
}

struct MusicBrainzCacheEntryPersistentState: Codable {
    
    let artist: String?
    let title: String?
    let file: URL?
}

extension MusicBrainzCache: PersistentModelObject {
    
    var persistentState: MusicBrainzCachePersistentState {
        
        var releases: [MusicBrainzCacheEntryPersistentState] = []
        var recordings: [MusicBrainzCacheEntryPersistentState] = []
        
        for (artist, title, file) in self.onDiskReleasesCache.entries {
             releases.append(MusicBrainzCacheEntryPersistentState(artist: artist, title: title, file: file))
        }
        
        for (artist, title, file) in self.onDiskRecordingsCache.entries {
            recordings.append(MusicBrainzCacheEntryPersistentState(artist: artist, title: title, file: file))
        }
        
        return MusicBrainzCachePersistentState(releases: releases, recordings: recordings)
    }
}
