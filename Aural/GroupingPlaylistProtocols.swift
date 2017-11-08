import Foundation

/*
    Contract for all read-only operations on the grouping/hierarchical (Artists/Albums/Genres) playlists
 */
protocol GroupingPlaylistAccessorProtocol {
    
    // Returns the group at the given index within this playlist. Assumes a valid index.
    func groupAtIndex(_ index: Int) -> Group
    
    // Returns the total number of groups within this playlist.
    func numberOfGroups() -> Int
    
    // Returns the type of this playlist
    func playlistType() -> PlaylistType
    
    // Returns the type of each group within this playlist.
    func typeOfGroups() -> GroupType
 
    // Given a track, returns all grouping information, such as the parent group and the index of the track within that group.
    func groupingInfoForTrack(_ track: Track) -> GroupedTrack
    
    // Returns the index of a group within this playlist.
    func indexOfGroup(_ group: Group) -> Int
    
    // Returns the display name for a track within this playlist.
    func displayNameForTrack(_ track: Track) -> String
    
    // Searches the playlist, given certain query parameters, and returns all matching results
    func search(_ searchQuery: SearchQuery) -> SearchResults
}

/*
    Contract for all write/mutating operations on the grouping/hierarchical (Artists/Albums/Genres) playlists
 */
protocol GroupingPlaylistMutatorProtocol: CommonPlaylistMutatorProtocol {
    
    // Adds a single track to the playlist, and returns its location within the playlist.
    func addTrack(_ track: Track) -> GroupedTrackAddResult
    
    /*
        Given a set of tracks and groups, removes them from the playlist. Removal of all tracks within a group will result in the removal of the group. Removal of a group will result in the removal of all its child tracks.
     
        Returns location information about the removal of the tracks from the playlist.
     */
    func removeTracksAndGroups(_ tracks: [Track], _ groups: [Group]) -> [ItemRemovalResult]
    
    /*
        Moves either the specified tracks, or the specified groups (groups take precedence), up one index in this playlist, if they can be moved (they are not already at the top).
     
        Returns mappings of source indexes to destination indexes. For all the tracks/groups (for tracks/groups that didn't move, the new index will match the old index).
     
        NOTE:
     
            - If both tracks and groups are specified, only the groups will be moved.
     
            - Even if some tracks/groups cannot move, those that can will be moved. i.e. This is not an all or nothing operation.
     */
    func moveTracksAndGroupsUp(_ tracks: [Track], _ groups: [Group]) -> ItemMoveResults
    
    /*
        Moves either the specified tracks, or the specified groups (groups take precedence), down one index in this playlist, if they can be moved (they are not already at the bottom).
     
        Returns mappings of source indexes to destination indexes. For all the tracks/groups (for tracks/groups that didn't move, the new index will match the old index).
     
        NOTE:
     
            - If both tracks and groups are specified, only the groups will be moved.
     
            - Even if some tracks/groups cannot move, those that can will be moved. i.e. This is not an all or nothing operation.
     */
    func moveTracksAndGroupsDown(_ tracks: [Track], _ groups: [Group]) -> ItemMoveResults
    
    /*
        Performs a drag and drop reordering operation on this playlist. Source items (tracks or groups) are dropped, under a given parent (either the root, if groups are being moved, or a specific group, if tracks are being moved), at a destination drop index.
     
        Returns mappings of source locations to destination locations.
     
        NOTE - If both tracks and groups are specified, only the groups will be moved.
     */
    func dropTracksAndGroups(_ tracks: [Track], _ groups: [Group], _ dropParent: Group?, _ dropIndex: Int) -> ItemMoveResults
    
    // Sorts the playlist according to the specified sort parameters
    func sort(_ sort: Sort)
}

protocol GroupingPlaylistCRUDProtocol: GroupingPlaylistAccessorProtocol, GroupingPlaylistMutatorProtocol {}
