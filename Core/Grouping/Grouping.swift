//
//  Grouping.swift
//  Aural
//
//  Copyright © 2021 Kartik Venugopal. All rights reserved.
//
//  This software is licensed under the MIT software license.
//  See the file "LICENSE" in the project root directory for license terms.
//  

import Foundation
import OrderedCollections

typealias GroupingFunction = (Track) -> String

extension Dictionary {
    
    mutating func append<T>(_ element: T, forKey key: Key) where Value == [T] {
        self[key, default: []].append(element)
    }
}

class Grouping: Hashable {
    
    static func == (lhs: Grouping, rhs: Grouping) -> Bool {
        lhs.name == rhs.name && lhs.depth == rhs.depth
    }
    
    func hash(into hasher: inout Hasher) {
        
        hasher.combine(name)
        hasher.combine(depth)
    }
    
    var name: String
    let depth: Int
    let keyFunction: GroupingFunction
    let subGrouping: Grouping?
    
    // TODO: Make these 2 an OrderedDictionary !!!
    var groups: OrderedSet<Group> = OrderedSet()
    fileprivate var groupsByName: [String: Group] = [:]
    
    var numberOfGroups: Int {groups.count}
    
    var duration: Double {
        groups.reduce(0.0, {(totalSoFar: Double, group: Group) -> Double in totalSoFar + group.duration})
    }
    
    var sortOrder: TrackComparator {
        trackNameAscendingComparator
    }
    
    fileprivate init(name: String, depth: Int, keyFunction: @escaping GroupingFunction, subGrouping: Grouping? = nil) {
        
        self.name = name
        self.depth = depth
        self.keyFunction = keyFunction
        self.subGrouping = subGrouping
    }
    
    func addTracks(_ newTracks: [Track]) {
        
        groupTracks(newTracks, accordingTo: self)

        if let subGrouping = self.subGrouping {
            subGroup(groups, accordingTo: subGrouping)
        }
    }
    
    fileprivate func doCreateGroup(named groupName: String) -> Group {
        Group(name: groupName, depth: self.depth)
    }
    
    fileprivate func createGroup(named groupName: String) -> Group {
        
        let group = doCreateGroup(named: groupName)
        
        groups.append(group)
        groupsByName[groupName] = group
        groups.sort(by: {g1, g2 in g1.name < g2.name})
        
        return group
    }
    
    fileprivate func findOrCreateGroup(named groupName: String) -> Group {
        groupsByName[groupName] ?? createGroup(named: groupName)
    }
    
    // Tracks removed from linear list, parent groups unknown.
    func removeTracks(_ tracksToRemove: [Track]) {
        
        let categorizedTracks: [String: [Track]] = categorizeTracksByGroupName(tracksToRemove)
        
        for (groupName, groupTracks) in categorizedTracks {
            groupsByName[groupName]?.removeTracks(groupTracks)
        }
    }
    
    // Tracks removed from hierarchical list, parent groups known.
    func remove(tracks: [GroupedTrack], andGroups groups: [Group]) {
        // TODO
    }
    
    @inlinable
    @inline(__always)
    func categorizeTracksByGroupName(_ tracks: [Track], keyFunction: GroupingFunction? = nil) -> [String: [Track]] {
        
        var tracksByGroupName: [String: [Track]] = [:]
        
        for track in tracks {
            tracksByGroupName[(keyFunction ?? self.keyFunction)(track), default: []].append(track)
        }
        
        return tracksByGroupName
    }
    
    func applyTo(trackList: TrackList) -> [Group] {
        []
    }

    fileprivate func groupTracks(_ tracks: [Track], accordingTo grouping: Grouping) {
        
        // Sort tracks only if they will not be further sub-grouped.
        let needToSortTracks: Bool = grouping.subGrouping == nil
        
        for (groupName, tracks) in categorizeTracksByGroupName(tracks, keyFunction: grouping.keyFunction) {
            
            let group = grouping.findOrCreateGroup(named: groupName)
            group.addTracks(tracks)
            
            if needToSortTracks {
                group.sortTracks(by: grouping.sortOrder)
            }
        }
    }

    // Recursive sub-grouping function.
    fileprivate func subGroup(_ groups: OrderedSet<Group>, accordingTo grouping: Grouping) {

        for group in groups {
            groupTracks(Array(group.tracks), accordingTo: grouping)
        }

        // Recursive call
        if let subGrouping = grouping.subGrouping {
            subGroup(grouping.groups, accordingTo: subGrouping)
        }
    }
}

class AlbumsGrouping: Grouping {
    
    override var sortOrder: TrackComparator {
        trackDiscAndTrackNumberAscendingComparator
    }
    
    init(depth: Int = 0) {
        super.init(name: "Albums", depth: depth) {track in track.album ?? "<Unknown>"}
    }
    
    override fileprivate func doCreateGroup(named groupName: String) -> Group {
        AlbumGroup(name: groupName, depth: self.depth)
    }
}

class ArtistsGrouping: Grouping {
    
    typealias GroupType = Group
    
    // TODO: Parse out collaborators: eg. "Grimes (feat. Magical Clouds)", so that all tracks
    // end up in the same group.
    
    override var sortOrder: TrackComparator {
        trackAlbumDiscAndTrackNumberAscendingComparator
    }
    
    init(depth: Int = 0, subGroupByAlbum: Bool = true) {
        super.init(name: "Artists", depth: depth, keyFunction: {track in track.artist ?? "<Unknown>"}, subGrouping: subGroupByAlbum ? AlbumsGrouping(depth: 1) : nil)
    }
}

class GenresGrouping: Grouping {
    
    init(subGroupByArtist: Bool = true, subGroupByAlbum: Bool = true) {
        
        let keyFunction: GroupingFunction = {track in track.genre ?? "<Unknown>"}
        
        switch (subGroupByArtist, subGroupByAlbum) {
            
        case (true, true):
            
            super.init(name: "Genres", depth: 0, keyFunction: keyFunction, subGrouping: ArtistsGrouping(depth: 1))
            
        case (true, false):
            
            super.init(name: "Genres", depth: 0, keyFunction: keyFunction, subGrouping: ArtistsGrouping(depth: 1, subGroupByAlbum: false))
            
        case (false, true):
        
            super.init(name: "Genres", depth: 0, keyFunction: keyFunction, subGrouping: AlbumsGrouping(depth: 1))
            
        case (false, false):
        
            super.init(name: "Genres", depth: 0, keyFunction: keyFunction)
        }
    }
}

class DecadesGrouping: Grouping {
    
    init(depth: Int = 0) {
        
        super.init(name: "Decades", depth: depth) {track in
            
            guard let year = track.year else {return "<Unknown>"}
            
            let decade = year - (year % 10)
            return "\(decade)'s"
        }
    }
}
