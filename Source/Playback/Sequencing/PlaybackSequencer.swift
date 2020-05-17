import Foundation

/*
    Concrete implementation of PlaybackSequencerProtocol. Also implements PlaylistChangeListenerProtocol, to respond to changes in the playlist, and MessageSubscriber to respond to changes in the playlist view.
 */
class PlaybackSequencer: PlaybackSequencerProtocol, PlaylistChangeListenerProtocol, MessageSubscriber, PersistentModelObject {
    
    // The underlying linear sequence of tracks for the current playback scope
    private let sequence: PlaybackSequence
    
    // The current playback scope (See SequenceScope for more details)
    // NOTE - The default sequence scope is "All tracks"
    private let scope: SequenceScope = SequenceScope(.allTracks)
    
    // The current playlist view type selected by the user (this is used to determine the scope)
    private var playlistType: PlaylistType = .tracks
    
    // Used to access the playlist's tracks/groups
    private let playlist: PlaylistAccessorProtocol
    
    // Stores the currently playing track, if there is one
    private var thePlayingTrack: Track?
    
    init(_ playlist: PlaylistAccessorProtocol, _ repeatMode: RepeatMode, _ shuffleMode: ShuffleMode) {
        
        self.sequence = PlaybackSequence(0, repeatMode, shuffleMode)
        self.playlist = playlist
        
        // Subscribe to notifications that the playlist view type has changed
        SyncMessenger.subscribe(messageTypes: [.playlistTypeChangedNotification], subscriber: self)
    }
    
    var sequenceInfo: (scope: SequenceScope, trackIndex: Int, totalTracks: Int) {
        
        // The sequence cursor is the index of the currently playing track within the current playback sequence
        return (scope, (sequence.cursor ?? -1) + 1, sequence.size)
    }
    
    func begin() -> IndexedTrack? {
        
        // Set the scope of the new sequence according to the playlist view type. For ex, if the "Artists" playlist view is selected, the new sequence will consist of all tracks in the "Artists" playlist, and the order of playback will be determined by the ordering within the Artists playlist (in addition to the repeat/shuffle modes).
        
        scope.type = playlistType.toPlaylistScopeType()
        scope.group = nil
        
        // Reset the sequence, with the size of the playlist
        sequence.reset(tracksCount: playlist.size)
        
        // Begin playing the subsequent track (first track determined by the sequence)
        return subsequent()
    }
    
    func end() {
        
        // Reset the sequence cursor (to indicate that no track is playing)
        sequence.resetCursor()
        thePlayingTrack = nil
        
        // Reset the scope and the scope type depending on which playlist view is currently selected
        scope.group = nil
        scope.type = playlistType.toPlaylistScopeType()
    }
    
    func peekSubsequent() -> IndexedTrack? {
        return getIndexedTrackForSequenceIndex(sequence.peekSubsequent())
    }
    
    func subsequent() -> IndexedTrack? {
        
        let subsequent = getIndexedTrackForSequenceIndex(sequence.subsequent())
        thePlayingTrack = subsequent?.track
        return subsequent
    }
    
    func peekNext() -> IndexedTrack? {
        return getIndexedTrackForSequenceIndex(sequence.peekNext())
    }
    
    func next() -> IndexedTrack? {

        // If there is no next track, don't change the playingTrack variable, because the playing track will continue playing
        if let next = getIndexedTrackForSequenceIndex(sequence.next()) {
            
            thePlayingTrack = next.track
            return next
        }
        
        return nil
    }
    
    func peekPrevious() -> IndexedTrack? {
        return getIndexedTrackForSequenceIndex(sequence.peekPrevious())
    }
    
    func previous() -> IndexedTrack? {
        
        // If there is no previous track, don't change the playingTrack variable, because the playing track will continue playing
        if let previous = getIndexedTrackForSequenceIndex(sequence.previous()) {
            
            thePlayingTrack = previous.track
            return previous
        }
        
        return nil
    }
    
    func select(_ index: Int) -> IndexedTrack? {
        
        // "All tracks" playback scope implied. So, reset the scope to allTracks, and reset the sequence size, if that is not the current scope type
        
        if scope.type != .allTracks {

            scope.type = .allTracks
            scope.group = nil
            
            sequence.reset(tracksCount: playlist.size)
        }
        
        return doSelectSequenceIndex(index)
    }
    
    // Helper function to select a track with a specific index within the current playback sequence
    private func doSelectSequenceIndex(_ sequenceIndex: Int) -> IndexedTrack? {
        
        sequence.select(sequenceIndex)
        
        if let track = getIndexedTrackForSequenceIndex(sequenceIndex) {
            
            thePlayingTrack = track.track
            return track
        }
        
        return nil
    }
    
    func select(_ track: Track) -> IndexedTrack? {
        
        if playlistType == .tracks, let index = playlist.indexOfTrack(track) {
            return select(index)
        }
        
        // Get the parent group of the selected track, and set it as the playback scope
        if let scopeType = playlistType.toGroupScopeType(), let groupType = playlistType.toGroupType(),
            let groupInfo = playlist.groupingInfoForTrack(groupType, track) {
            
            scope.type = scopeType
            scope.group = groupInfo.group
            
            // Reset the sequence based on the group's size
            sequence.reset(tracksCount: groupInfo.group.size)
            
            // Select the specified track within its parent group, for playback
            return doSelectSequenceIndex(groupInfo.trackIndex)
        }
        
        return nil
    }
    
    func select(_ group: Group) -> IndexedTrack? {
        
        // Determine the type of the selected track's parent group (which depends on which playlist view type is selected). This will determine the scope type.
        scope.type = group.type.toScopeType()
        
        // Set the scope to the selected group
        scope.group = group
        
        // Reset the sequence based on the group's size
        sequence.reset(tracksCount: group.size)
        sequence.resetCursor()
        
        // Begin playing the subsequent track (first track determined by the sequence)
        return subsequent()
    }
    
    var playingTrack: IndexedTrack? {
        
        // TODO: Race condition here ? During autoplay ?
        
        // Wrap the playing track with its flat playlist index, before returning it
        if let track = thePlayingTrack {
            return wrapTrack(track)
        }
        
        return nil
    }
    
    // Helper function that, given the index of a track within the current plyback sequence,
    // returns the corresponding track and its index within the playlist.
    private func getIndexedTrackForSequenceIndex(_ sequenceIndex: Int?) -> IndexedTrack? {
        
        // Unwrap optional cursor value
        if let index = sequenceIndex {
            
            switch scope.type {
                
            // For a single group, the index is the track index within that group
            case .artist, .album, .genre:
                
                if let group = scope.group {
                    return wrapTrack(group.trackAtIndex(index))
                }
                
            // For the allTracks scope, the index is the absolute index within the flat playlist
            case .allTracks:
                
                return playlist.trackAtIndex(index)
                
            // For the allArtists, allAlbums, and allGenres scopes, the index is an absolute index that needs to be mapped to a group index and track index within that group.
                
            case .allArtists, .allAlbums, .allGenres:
                
                if let groupType = scope.type.toGroupType() {
                    return wrapTrack(getGroupedTrackForAbsoluteIndex(groupType, index))
                }
            }
        }
        
        return nil
    }
    
    /* 
     
        Given an absolute index within a grouping/hierarchical playlist, maps the absolute index to a group index and track index within that group, and returns the corresponding track at that location.
     
        Example: The track with an absolute index of 5, is Track 0 under Group 2, below.
     
        Group 0
            -> Track 0 (absolute index 0)
            -> Track 1 (absolute index 1)
            -> Track 2 (absolute index 2)
     
        Group 1
            -> Track 0 (absolute index 3)
            -> Track 1 (absolute index 4)
     
        Group 2
            -> Track 0 (absolute index 5)
            -> Track 1 (absolute index 6)
    */
    private func getGroupedTrackForAbsoluteIndex(_ groupType: GroupType, _ absoluteIndex: Int) -> Track {
        
        var groupIndex = 0
        var tracksSoFar = 0
        var trackIndexInGroup = 0
        
        // Iterate over groups while the tracks count (tracksSoFar) is less than the target absolute index
        while tracksSoFar < absoluteIndex {
            
            // Add the size of the current group, to tracksSoFar
            tracksSoFar += playlist.groupAtIndex(groupType, groupIndex).size
            
            // Increment the groupIndex to iterate to the next group
            groupIndex += 1
        }
        
        // If you've overshot the target index, go back one group, and use the offset to calculate track index within that previous group
        if tracksSoFar > absoluteIndex {
            
            groupIndex -= 1
            trackIndexInGroup = playlist.groupAtIndex(groupType, groupIndex).size - (tracksSoFar - absoluteIndex)
        }
        
        // Given the groupIndex and trackIndex, retrive the desired track
        let group = playlist.groupAtIndex(groupType, groupIndex)
        let track = group.trackAtIndex(trackIndexInGroup)
        
        return track
    }
   
    /*
        Does the opposite/inverse of what getGroupedTrackForAbsoluteIndex() does. Maps a track within a grouping/hierarchical playlist to its absolute index within that playlist.
     */
    private func getAbsoluteIndexForGroupedTrack(_ groupType: GroupType, _ groupIndex: Int, _ trackIndex: Int) -> Int {
        
        // If we're looking inside the first group, the absolute index is simply the track index
        if groupIndex == 0 {
            return trackIndex
        }
        
        // Iterate over all the groups, noting the size of each group, till the target group is reached
        var absIndexSoFar = 0
        for i in 0..<groupIndex {
            absIndexSoFar += playlist.groupAtIndex(groupType, i).size
        }
        
        // The target group has been reached. Now, simply add the track index to absIndexSoFar, and that is the desired value
        return absIndexSoFar + trackIndex
    }
    
    // Wraps a non-indexed track into an indexed track so that it can be located within the flat playlist.
    private func wrapTrack(_ track: Track) -> IndexedTrack? {
        
        // Flat playlist index
        if let index = playlist.indexOfTrack(track) {
            return IndexedTrack(track, index)
        }
        
        return nil
    }
    
    func setRepeatMode(_ repeatMode: RepeatMode) -> (repeatMode: RepeatMode, shuffleMode: ShuffleMode) {
        return sequence.setRepeatMode(repeatMode)
    }
    
    func setShuffleMode(_ shuffleMode: ShuffleMode) -> (repeatMode: RepeatMode, shuffleMode: ShuffleMode) {
        return sequence.setShuffleMode(shuffleMode)
    }
    
    func toggleRepeatMode() -> (repeatMode: RepeatMode, shuffleMode: ShuffleMode) {
        return sequence.toggleRepeatMode()
    }
    
    func toggleShuffleMode() -> (repeatMode: RepeatMode, shuffleMode: ShuffleMode) {
        return sequence.toggleShuffleMode()
    }
    
    var persistentState: PersistentState {
        
        let state = PlaybackSequenceState()
        
        let modes = sequence.repeatAndShuffleModes
        state.repeatMode = modes.repeatMode
        state.shuffleMode = modes.shuffleMode
        
        return state
    }
    
    // --------------- PlaylistChangeListenerProtocol methods ----------------
    
    func tracksAdded(_ addResults: [TrackAddResult]) {
        
        if !addResults.isEmpty {
            updateSequence()
        }
    }
    
    func tracksRemoved(_ removeResults: TrackRemovalResults, _ playingTrackRemoved: Bool, _ removedPlayingTrack: Track?) {
        
        // If the playing track was removed, playback is stopped, and the current sequence has ended
        if playingTrackRemoved {
            end()
        }
        
        if !removeResults.flatPlaylistResults.isEmpty {
            updateSequence()
        }
    }
    
    func tracksReordered(_ playlistType: PlaylistType) {
        
        // Only update the sequence if the type of the playlist that was reordered matches the playback sequence scope. In other words, if, for example, the Albums playlist was reordered, that does not affect the Artists playlist.
        if scope.type.toPlaylistType() == playlistType {
            updateSequence()
        }
    }
    
    func playlistCleared() {
        
        // The sequence has ended, and needs to be cleared
        sequence.clear()
        end()
    }
    
    // Calculates the new cursor (i.e. index of the playing track within the current playback sequence). This function is called in response to changes in the playlist, to update the cursor which may have changed.
    private func calculateNewCursor() -> Int? {
        
        // We only need to do this if there is a track currently playing
        if let playingTrack = thePlayingTrack {
            
            switch scope.type {
                
            case .allArtists, .allAlbums, .allGenres:
                
                // Recalculate the absolute index of the playing track, given its parent group and track index within that group
                
                if let groupType = scope.type.toGroupType(), let groupInfo = playlist.groupingInfoForTrack(groupType, playingTrack) {
                    return getAbsoluteIndexForGroupedTrack(groupType, groupInfo.groupIndex, groupInfo.trackIndex)
                }
                
            case .artist, .album, .genre:
                
                // The index of the playing track within the group is simply its track index
                if let group = scope.group {
                    return group.indexOfTrack(playingTrack)
                }
                
            case .allTracks:
                
                // The index of the playing track within the flat playlist is simply its absolute index
                return playlist.indexOfTrack(playingTrack)
            }
        }
        
        return nil
    }
    
    // Updates the playback sequence. This function is called in response to changes in the playlist,
    // to update the size of the sequence, and the sequence cursor, both of which may have changed.
    private func updateSequence() {
        
        // Calculate new sequence size (either the size of the group scope, if there is one, or of the entire playlist).
        let sequenceSize: Int = scope.group?.size ?? playlist.size
        
        if sequence.cursor != nil {
            
            // There is a playing track
        
            // Update the cursor
            let newCursor = calculateNewCursor()
            sequence.reset(tracksCount: sequenceSize, firstTrackIndex: newCursor)
        
        } else {
            
            // No playing track
            sequence.reset(tracksCount: sequenceSize)
        }
    }
    
    var repeatAndShuffleModes: (repeatMode: RepeatMode, shuffleMode: ShuffleMode) {
        return sequence.repeatAndShuffleModes
    }
    
    let subscriberId: String = "PlaybackSequencer"
    
    // MARK: Message handling
    
    // When the selected playlist view type changes in the UI (i.e. the selected playlist tab changes), this notification is sent out. Here, we make note of the new playlist type, so that the playback scope may be determined from it.
    private func playlistTypeChanged(_ notification: PlaylistTypeChangedNotification) {
        
        // Updates the instance variable playlistType, with the new playlistType value
        self.playlistType = notification.newPlaylistType
    }
    
    func consumeNotification(_ notification: NotificationMessage) {
        
        switch notification.messageType {
            
        case .playlistTypeChangedNotification:
            
            playlistTypeChanged(notification as! PlaylistTypeChangedNotification)
            
        default: return
            
        }
    }
    
    func processRequest(_ request: RequestMessage) -> ResponseMessage {
        
        // No meaningful response
        return EmptyResponse.instance
    }
}
