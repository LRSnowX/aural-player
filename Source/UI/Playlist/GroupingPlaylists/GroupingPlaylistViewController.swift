import Cocoa

/*
    Base view controller for the hierarchical/grouping ("Artists", "Albums", and "Genres") playlist views
 */
class GroupingPlaylistViewController: NSViewController, MessageSubscriber, ActionMessageSubscriber {
    
    @IBOutlet weak var scrollView: NSScrollView!
    @IBOutlet weak var clipView: NSClipView!
    @IBOutlet weak var playlistView: AuralPlaylistOutlineView!
    @IBOutlet weak var playlistViewDelegate: GroupingPlaylistViewDelegate!
    
    private lazy var contextMenu: NSMenu! = WindowFactory.playlistContextMenu
    
    // Delegate that relays CRUD actions to the playlist
    private let playlist: PlaylistDelegateProtocol = ObjectGraph.playlistDelegate
    
    // Delegate that retrieves current playback info
    private let playbackInfo: PlaybackInfoDelegateProtocol = ObjectGraph.playbackInfoDelegate
    
    private let history: HistoryDelegateProtocol = ObjectGraph.historyDelegate
    
    private let preferences: PlaylistPreferences = ObjectGraph.preferencesDelegate.preferences.playlistPreferences
    
    // A serial operation queue to help perform playlist update tasks serially, without overwhelming the main thread
    private let playlistUpdateQueue = OperationQueue()
    
    // Intended to be overriden by subclasses
    
    // Indicates the type of each parent group in this playlist view
    internal var groupType: GroupType {return .artist}
    
    // Indicates the type of playlist this view displays
    internal var playlistType: PlaylistType {return .artists}
    
    override func viewDidLoad() {
        
        // Enable drag n drop
        playlistView.registerForDraggedTypes(convertToNSPasteboardPasteboardTypeArray([String(kUTTypeFileURL), "public.data"]))
        playlistView.menu = contextMenu
        
        // Register for key press and gesture events
        PlaylistInputEventHandler.registerViewForPlaylistType(self.playlistType, playlistView)
        
        initSubscriptions()
        
        // Set up the serial operation queue for playlist view updates
        playlistUpdateQueue.maxConcurrentOperationCount = 1
        playlistUpdateQueue.underlyingQueue = DispatchQueue.main
        playlistUpdateQueue.qualityOfService = .userInitiated
        
        doApplyColorScheme(ColorSchemes.systemScheme, false)
    }
    
    private func initSubscriptions() {
        
        Messenger.subscribeAsync(self, .trackAdded, self.trackAdded(_:), queue: .main)
        Messenger.subscribeAsync(self, .tracksRemoved, self.tracksRemoved(_:), queue: .main)
        
        Messenger.subscribeAsync(self, .trackTransition, self.trackTransitioned(_:), queue: .main)
        Messenger.subscribeAsync(self, .trackNotPlayed, self.trackNotPlayed(_:), queue: .main)
        
        // Don't bother responding if only album art was updated
        Messenger.subscribeAsync(self, .trackInfoUpdated, self.trackInfoUpdated(_:),
                                 filter: {msg in msg.updatedFields.contains(.duration) || msg.updatedFields.contains(.displayInfo)},
                                 queue: .main)
        
        Messenger.subscribe(self, .gapUpdated, self.gapUpdated(_:))
        
        // MARK: Command handling -------------------------------------------------------------------------------------------------
        
        Messenger.subscribe(self, .playlist_selectSearchResult, self.selectSearchResult(_:),
                            filter: {cmd in cmd.viewSelector.includes(self.playlistType)})
        
        let viewSelectionFilter: (PlaylistViewSelector) -> Bool = {selector in selector.includes(self.playlistType)}
        
        Messenger.subscribe(self, .playlist_refresh, {(PlaylistViewSelector) in self.refresh()}, filter: viewSelectionFilter)
        Messenger.subscribe(self, .playlist_removeTracks, {(PlaylistViewSelector) in self.removeTracks()}, filter: viewSelectionFilter)
        
        Messenger.subscribe(self, .playlist_moveTracksUp, {(PlaylistViewSelector) in self.moveTracksUp()}, filter: viewSelectionFilter)
        Messenger.subscribe(self, .playlist_moveTracksDown, {(PlaylistViewSelector) in self.moveTracksDown()}, filter: viewSelectionFilter)
        Messenger.subscribe(self, .playlist_moveTracksToTop, {(PlaylistViewSelector) in self.moveTracksToTop()}, filter: viewSelectionFilter)
        Messenger.subscribe(self, .playlist_moveTracksToBottom, {(PlaylistViewSelector) in self.moveTracksToBottom()}, filter: viewSelectionFilter)
        
        Messenger.subscribe(self, .playlist_clearSelection, {(PlaylistViewSelector) in self.clearSelection()}, filter: viewSelectionFilter)
        Messenger.subscribe(self, .playlist_invertSelection, {(PlaylistViewSelector) in self.invertSelection()}, filter: viewSelectionFilter)
        Messenger.subscribe(self, .playlist_cropSelection, {(PlaylistViewSelector) in self.cropSelection()}, filter: viewSelectionFilter)
        
        Messenger.subscribe(self, .playlist_scrollToTop, {(PlaylistViewSelector) in self.scrollToTop()}, filter: viewSelectionFilter)
        Messenger.subscribe(self, .playlist_scrollToBottom, {(PlaylistViewSelector) in self.scrollToBottom()}, filter: viewSelectionFilter)
        Messenger.subscribe(self, .playlist_pageUp, {(PlaylistViewSelector) in self.pageUp()}, filter: viewSelectionFilter)
        Messenger.subscribe(self, .playlist_pageDown, {(PlaylistViewSelector) in self.pageDown()}, filter: viewSelectionFilter)
        
        Messenger.subscribe(self, .playlist_expandSelectedGroups, {(PlaylistViewSelector) in self.expandSelectedGroups()}, filter: viewSelectionFilter)
        Messenger.subscribe(self, .playlist_collapseSelectedItems, {(PlaylistViewSelector) in self.collapseSelectedItems()}, filter: viewSelectionFilter)
        Messenger.subscribe(self, .playlist_expandAllGroups, {(PlaylistViewSelector) in self.expandAllGroups()}, filter: viewSelectionFilter)
        Messenger.subscribe(self, .playlist_collapseAllGroups, {(PlaylistViewSelector) in self.collapseAllGroups()}, filter: viewSelectionFilter)
        
        Messenger.subscribe(self, .playlist_showPlayingTrack, {(PlaylistViewSelector) in self.showPlayingTrack()}, filter: viewSelectionFilter)
        Messenger.subscribe(self, .playlist_showTrackInFinder, {(PlaylistViewSelector) in self.showTrackInFinder()}, filter: viewSelectionFilter)
        
        Messenger.subscribe(self, .playlist_playSelectedItem, {(PlaylistViewSelector) in self.playSelectedItem()}, filter: viewSelectionFilter)
        
        Messenger.subscribe(self, .playlist_playSelectedItemWithDelay,
                            {(notif: DelayedPlaybackCommandNotification) in self.playSelectedItemWithDelay(notif.delay)},
                            filter: {(notif: DelayedPlaybackCommandNotification) in notif.viewSelector.includes(self.playlistType)})
        
        Messenger.subscribe(self, .playlist_insertGaps,
                            {(notif: InsertPlaybackGapsCommandNotification) in self.insertGaps(notif.gapBeforeTrack, notif.gapAfterTrack)},
                            filter: {(notif: InsertPlaybackGapsCommandNotification) in notif.viewSelector.includes(self.playlistType)})
        
        Messenger.subscribe(self, .playlist_removeGaps, {(PlaylistViewSelector) in self.removeGaps()}, filter: viewSelectionFilter)
        
        Messenger.subscribe(self, .changePlaylistTextSize, self.changeTextSize(_:))
        Messenger.subscribe(self, .colorScheme_applyColorScheme, self.applyColorScheme(_:))
        
        SyncMessenger.subscribe(actionTypes: [.changeBackgroundColor, .changePlaylistTrackNameTextColor, .changePlaylistTrackNameSelectedTextColor, .changePlaylistGroupNameTextColor, .changePlaylistGroupNameSelectedTextColor, .changePlaylistIndexDurationTextColor, .changePlaylistIndexDurationSelectedTextColor, .changePlaylistSelectionBoxColor, .changePlaylistPlayingTrackIconColor, .changePlaylistGroupIconColor, .changePlaylistGroupDisclosureTriangleColor], subscriber: self)
    }
    
    override func viewDidAppear() {
        
        // When this view appears, the playlist type (tab) has changed. Update state and notify observers.
        
        PlaylistViewState.current = self.playlistType
        PlaylistViewState.currentView = playlistView

        Messenger.publish(PlaylistTypeChangedNotification(newPlaylistType: self.playlistType))
    }
    
    // Plays the track/group selected within the playlist, if there is one. If multiple items are selected, the first one will be chosen.
    @IBAction func playSelectedItemAction(_ sender: AnyObject) {
        playSelectedItemWithDelay(nil)
    }
    
    func playSelectedItem() {
        playSelectedItemWithDelay(nil)
    }
    
    func playSelectedItemWithDelay(_ delay: Double?) {
        
        if let firstSelectedRow = playlistView.selectedRowIndexes.min() {
            
            let item = playlistView.item(atRow: firstSelectedRow)
            
            if let track = item as? Track {
                Messenger.publish(TrackPlaybackCommandNotification(track: track, delay: delay))
                
            } else if let group = item as? Group {
                Messenger.publish(TrackPlaybackCommandNotification(group: group, delay: delay))
            }
        }
    }
    
    private func clearPlaylist() {
        
        playlist.clear()
        Messenger.publish(.playlist_refresh, payload: PlaylistViewSelector.allViews)
    }
    
    // Helper function that gathers all selected playlist items as tracks and groups
    private func collectTracksAndGroups() -> (tracks: [Track], groups: [Group]) {
        return doCollectTracksAndGroups(playlistView.selectedRowIndexes)
    }
    
    private func doCollectTracksAndGroups(_ indexes: IndexSet) -> (tracks: [Track], groups: [Group]) {
        
        var tracks = [Track]()
        var groups = [Group]()
        
        indexes.forEach({
            
            let item = playlistView.item(atRow: $0)
            item is Track ? tracks.append(item as! Track) : groups.append(item as! Group)
        })
        
        return (tracks, groups)
    }
    
    private func removeTracks() {
        
        let tracksAndGroups = collectTracksAndGroups()
        let tracks = tracksAndGroups.tracks
        let groups = tracksAndGroups.groups
        
        if (groups.isEmpty && tracks.isEmpty) {
            
            // Nothing selected, nothing to do
            return
        }
        
        _ = playlist.removeTracksAndGroups(tracks, groups, groupType)
    }
    
    private func selectTrack(_ track: Track?) {
        
        if playlistView.numberOfRows > 0, let _track = track, let group = playlist.groupingInfoForTrack(self.groupType, _track)?.group {
                
            // Need to expand the parent group to make the child track visible
            playlistView.expandItem(group)
            
            let trackRowIndex = playlistView.row(forItem: _track)
            
            playlistView.selectRowIndexes(IndexSet(integer: trackRowIndex), byExtendingSelection: false)
            playlistView.scrollRowToVisible(trackRowIndex)
        }
    }
    
    // Selects (and shows) a certain track within the playlist view
    private func selectTrack(_ track: GroupedTrack?) {
        
        if playlistView.numberOfRows > 0, let _track = track?.track, let parentGroup = track?.group {
                
            // Need to expand the parent group to make the child track visible
            playlistView.expandItem(parentGroup)
            
            let trackRowIndex = playlistView.row(forItem: _track)

            playlistView.selectRowIndexes(IndexSet(integer: trackRowIndex), byExtendingSelection: false)
            playlistView.scrollRowToVisible(trackRowIndex)
        }
    }
    
    func refresh() {
        
        DispatchQueue.main.async {
            self.playlistView.reloadData()
        }
    }
    
    // Refreshes the playlist view by rearranging the items that were moved
    private func removeAndInsertItems(_ results: ItemMoveResults) {
 
        for result in results.results {
            
            if let trackMovedResult = result as? TrackMoveResult {
                
                playlistView.removeItems(at: IndexSet([trackMovedResult.oldTrackIndex]), inParent: trackMovedResult.parentGroup, withAnimation: trackMovedResult.movedUp ? .slideUp : .slideDown)
                
                playlistView.insertItems(at: IndexSet([trackMovedResult.newTrackIndex]), inParent: trackMovedResult.parentGroup, withAnimation: trackMovedResult.movedUp ? .slideDown : .slideUp)
                
            } else if let groupMovedResult = result as? GroupMoveResult {
                
                playlistView.removeItems(at: IndexSet([groupMovedResult.oldGroupIndex]), inParent: nil, withAnimation: groupMovedResult.movedUp ? .slideUp : .slideDown)
                
                playlistView.insertItems(at: IndexSet([groupMovedResult.newGroupIndex]), inParent: nil, withAnimation: groupMovedResult.movedUp ? .slideDown : .slideUp)
            }
        }
    }
    
    
    
    // Refreshes the playlist view by rearranging the items that were moved
    private func moveItems(_ results: ItemMoveResults) {
        
        for result in results.results {
            
            if let trackMovedResult = result as? TrackMoveResult {
                
                playlistView.moveItem(at: trackMovedResult.oldTrackIndex, inParent: trackMovedResult.parentGroup, to: trackMovedResult.newTrackIndex, inParent: trackMovedResult.parentGroup)
                
            } else if let groupMovedResult = result as? GroupMoveResult {
                
                playlistView.moveItem(at: groupMovedResult.oldGroupIndex, inParent: nil, to: groupMovedResult.newGroupIndex, inParent: nil)
            }
        }
    }
    
    // Selects all the specified items within the playlist view
    private func selectAllItems(_ items: [PlaylistItem]) {
        
        // Determine the row indexes for the items
        let selIndexes: [Int] = items.map { playlistView.row(forItem: $0) }
        
        // Select the item indexes
        playlistView.selectRowIndexes(IndexSet(selIndexes), byExtendingSelection: false)
    }
    
    private func moveTracksUp() {
        doMoveItems(playlist.moveTracksAndGroupsUp(_:_:_:), self.moveItems(_:))
    }
    
    private func moveTracksDown() {
        doMoveItems(playlist.moveTracksAndGroupsDown(_:_:_:), self.moveItems(_:))
    }
    
    private func moveTracksToTop() {
        doMoveItems(playlist.moveTracksAndGroupsToTop(_:_:_:), self.removeAndInsertItems(_:))
    }
    
    private func moveTracksToBottom() {
        doMoveItems(playlist.moveTracksAndGroupsToBottom(_:_:_:), self.removeAndInsertItems(_:))
    }
    
    private func doMoveItems(_ moveAction: @escaping ([Track], [Group], GroupType) -> ItemMoveResults,
                             _ refreshAction: @escaping (ItemMoveResults) -> Void) {
        
        let tracksAndGroups = collectTracksAndGroups()
        let tracks = tracksAndGroups.tracks
        let groups = tracksAndGroups.groups
        
        // Cannot move both tracks and groups
        if tracks.count > 0 && groups.count > 0 {
            return
        }
        
        // Move items within the playlist and refresh the playlist view
        let results = moveAction(tracks, groups, self.groupType)
        refreshAction(results)
        
        // Re-select all the items that were moved
        var allItems: [PlaylistItem] = []
        groups.forEach({allItems.append($0)})
        tracks.forEach({allItems.append($0)})
        selectAllItems(allItems)
        
        // Scroll to make the first selected row visible
        playlistView.scrollRowToVisible(playlistView.selectedRow)
    }
    
    private func invertSelection() {
        playlistView.selectRowIndexes(invertedSelection, byExtendingSelection: false)
    }
    
    // TODO: Simplify this method
    // for row in 0..<numRows if !selRows.contains(row) invSelRows.add(row)
    private var invertedSelection: IndexSet {
        
        let selRows = playlistView.selectedRowIndexes
        
        var curIndex: Int = 0
        var itemsInspected: Int = 0
        
        let playlistSize = playlist.size
        var targetSelRows = IndexSet()

        // Iterate through items, till all items have been inspected
        while itemsInspected < playlistSize {
            
            let item = playlistView.item(atRow: curIndex)
            
            if let group = item as? Group {
             
                let selected: Bool = selRows.contains(curIndex)
                let expanded: Bool = playlistView.isItemExpanded(group)
                
                if selected {
                    
                    // Ignore this group as it is selected
                    if expanded {
                        curIndex += group.size
                    }
                    
                } else {
                    
                    // Group not selected
                    
                    if expanded {
                        
                        // Check for selected children
                        
                        let childIndexes = selRows.filter({$0 > curIndex && $0 <= curIndex + group.size})
                        if childIndexes.isEmpty {
                            
                            // No children selected, add group index
                            targetSelRows.insert(curIndex)
                            
                        } else {
                            
                            // Check each child track
                            for index in 1...group.size {
                                
                                if !selRows.contains(curIndex + index) {
                                    targetSelRows.insert(curIndex + index)
                                }
                            }
                        }
                        
                        curIndex += group.size
                        
                    } else {
                        
                        // Group (and children) not selected, add this group to inverted selection
                        targetSelRows.insert(curIndex)
                    }
                }
                
                curIndex += 1
                itemsInspected += group.size
            }
        }
        
        return targetSelRows
    }
    
    private func clearSelection() {
        playlistView.selectRowIndexes(IndexSet([]), byExtendingSelection: false)
    }
    
    private func cropSelection() {
        
        let tracksToDelete: IndexSet = invertedSelection
        clearSelection()
        
        if (tracksToDelete.count > 0) {
            
            let tracksAndGroups = doCollectTracksAndGroups(tracksToDelete)
            let tracks = tracksAndGroups.tracks
            let groups = tracksAndGroups.groups
            
            if (groups.isEmpty && tracks.isEmpty) {
                
                // Nothing selected, nothing to do
                return
            }
            
            // If all groups are selected, this is the same as clearing the playlist
            if (groups.count == playlist.numberOfGroups(self.groupType)) {
                clearPlaylist()
                return
            }
            
            _ = playlist.removeTracksAndGroups(tracks, groups, groupType)
        }
    }
    
    private func expandSelectedGroups() {
        
        // Need to sort in descending order because expanding a group will change the row indexes of other selected items :)
        let sortedIndexes = playlistView.selectedRowIndexes.sorted(by: {x, y -> Bool in x > y})
        sortedIndexes.forEach({playlistView.expandItem(playlistView.item(atRow: $0))})
    }
    
    private func collapseSelectedItems() {
        
        // Need to sort in descending order because collapsing a group will change the row indexes of other selected items :)
        let sortedIndexes = playlistView.selectedRowIndexes.sorted(by: {x, y -> Bool in x > y})
        
        var groups = Set<Group>()
        sortedIndexes.forEach({
            
            let item = playlistView.item(atRow: $0)
            if let track = item as? Track {
                
                let parent = playlistView.parent(forItem: track)
                groups.insert(parent as! Group)
                
            } else {
                // Group
                groups.insert(item as! Group)
            }
        })
        
        groups.forEach({playlistView.collapseItem($0, collapseChildren: false)})
    }
    
    private func expandAllGroups() {
        playlistView.expandItem(nil, expandChildren: true)
    }
    
    private func collapseAllGroups() {
        playlistView.collapseItem(nil, collapseChildren: true)
    }
    
    // Scrolls the playlist view to the very top
    private func scrollToTop() {
        
        if (playlistView.numberOfRows > 0) {
            playlistView.scrollRowToVisible(0)
        }
    }
    
    // Scrolls the playlist view to the very bottom
    private func scrollToBottom() {
        
        if (playlistView.numberOfRows > 0) {
            playlistView.scrollRowToVisible(playlistView.numberOfRows - 1)
        }
    }
    
    private func pageUp() {
        
        // Determine if the first row currently displayed has been truncated so it is not fully visible
        
        let firstRowShown = playlistView.rows(in: playlistView.visibleRect).lowerBound
        let firstRowShown_height = playlistView.rect(ofRow: firstRowShown).height
        let firstRowShown_minY = playlistView.rect(ofRow: firstRowShown).minY
        
        let visibleRect_minY = playlistView.visibleRect.minY
        
        let truncationAmount =  visibleRect_minY - firstRowShown_minY
        let truncationRatio = truncationAmount / firstRowShown_height
        
        // If the first row currently displayed has been truncated more than 10%, show it again in the next page
        
        let lastRowToShow = truncationRatio > 0.1 ? firstRowShown : firstRowShown - 1
        let lastRowToShow_maxY = playlistView.rect(ofRow: lastRowToShow).maxY
        
        let visibleRect_maxY = playlistView.visibleRect.maxY
        
        // Calculate the scroll amount, as a function of the last row to show next, using the visible rect origin (i.e. the top of the first row in the playlist) as the stopping point
        
        let scrollAmount = min(playlistView.visibleRect.origin.y, visibleRect_maxY - lastRowToShow_maxY)
        
        if scrollAmount > 0 {
            
            let up = playlistView.visibleRect.origin.applying(CGAffineTransform.init(translationX: 0, y: -scrollAmount))
            playlistView.enclosingScrollView!.contentView.scroll(to: up)
        }
    }
    
    private func pageDown() {
        
        // Determine if the last row currently displayed has been truncated so it is not fully visible
        
        let visibleRows = playlistView.rows(in: playlistView.visibleRect)
        
        let lastRowShown = visibleRows.lowerBound + visibleRows.length - 1
        let lastRowShown_maxY = playlistView.rect(ofRow: lastRowShown).maxY
        let lastRowShown_height = playlistView.rect(ofRow: lastRowShown).height
        
        let lastRowInPlaylist = playlistView.numberOfRows - 1
        let lastRowInPlaylist_maxY = playlistView.rect(ofRow: lastRowInPlaylist).maxY
        
        // If the first row currently displayed has been truncated more than 10%, show it again in the next page
        
        let visibleRect_maxY = playlistView.visibleRect.maxY
        
        let truncationAmount = lastRowShown_maxY - visibleRect_maxY
        let truncationRatio = truncationAmount / lastRowShown_height
        
        let firstRowToShow = truncationRatio > 0.1 ? lastRowShown : lastRowShown + 1
        
        let visibleRect_originY = playlistView.visibleRect.origin.y
        let firstRowToShow_originY = playlistView.rect(ofRow: firstRowToShow).origin.y
        
        // Calculate the scroll amount, as a function of the first row to show next, using the visible rect maxY (i.e. the bottom of the last row in the playlist) as the stopping point
        
        let scrollAmount = min(firstRowToShow_originY - visibleRect_originY, lastRowInPlaylist_maxY - playlistView.visibleRect.maxY)
        
        if scrollAmount > 0 {
            
            let down = playlistView.visibleRect.origin.applying(CGAffineTransform.init(translationX: 0, y: scrollAmount))
            playlistView.enclosingScrollView!.contentView.scroll(to: down)
        }
    }
    
    // Selects the currently playing track, within the playlist view
    private func showPlayingTrack() {
        
        if let playingTrack = playbackInfo.currentTrack,
            let groupingInfo = playlist.groupingInfoForTrack(self.groupType, playingTrack) {
            
            selectTrack(groupingInfo)
        }
    }
 
    // Refreshes the playlist view in response to a new track being added to the playlist
    func trackAdded(_ notification: TrackAddedNotification) {
        
        if let grouping = notification.groupingInfo[self.groupType] {
            
            if grouping.groupCreated {
                
                // Insert the new group
                self.playlistView.insertItems(at: IndexSet(integer: grouping.track.groupIndex), inParent: nil, withAnimation: .effectFade)
                
            } else {
                
                // Insert the new track under its parent group, and reload the parent group
                let group = grouping.track.group
                
                self.playlistView.insertItems(at: IndexSet(integer: grouping.track.trackIndex), inParent: group, withAnimation: .effectGap)
                self.playlistView.reloadItem(group)
            }
        }
    }
    
    // Refreshes the playlist view in response to a track being updated with new information (e.g. duration)
    private func trackInfoUpdated(_ notification: TrackInfoUpdatedNotification) {
        
        let track = notification.updatedTrack
        
        if let groupInfo = playlist.groupingInfoForTrack(self.groupType, track) {
            
            // Reload the parent group and the track
            self.playlistView.reloadItem(groupInfo.group, reloadChildren: false)
            self.playlistView.reloadItem(groupInfo.track)
        }
    }
    
    // Refreshes the playlist view in response to tracks/groups being removed from the playlist
    private func tracksRemoved(_ notification: TracksRemovedNotification) {
        
        let removals = notification.results.groupingPlaylistResults[self.groupType]!
        var groupsToReload = [Group]()

        for removal in removals {

            if let tracksRemoval = removal as? GroupedTracksRemovalResult {
                
                // Remove tracks from their parent group
                playlistView.removeItems(at: tracksRemoval.trackIndexesInGroup, inParent: tracksRemoval.parentGroup, withAnimation: .effectFade)

                // Make note of the parent group for later
                groupsToReload.append(tracksRemoval.parentGroup)

            } else {
                
                // Remove group from the root
                let groupRemoval = removal as! GroupRemovalResult
                playlistView.removeItems(at: IndexSet(integer: groupRemoval.groupIndex), inParent: nil, withAnimation: .effectFade)
            }
        }

        // For all groups from which tracks were removed, reload them
        groupsToReload.forEach({playlistView.reloadItem($0)})
    }
    
    func trackTransitioned(_ message: TrackTransitionNotification) {
        
        let oldTrack = message.beginTrack
        
        if let _oldTrack = oldTrack {
            
            // If this is not done async, the row view could get garbled.
            // (because of other potential simultaneous updates - e.g. PlayingTrackInfoUpdated)
            DispatchQueue.main.async {
            
                self.playlistView.reloadItem(_oldTrack)
            
                let row = self.playlistView.row(forItem: _oldTrack)
                self.playlistView.noteHeightOfRows(withIndexesChanged: IndexSet([row]))
            }
        }
        
        let needToShowTrack: Bool = PlaylistViewState.current.toGroupType() == self.groupType && preferences.showNewTrackInPlaylist
        
        if let newTrack = message.endTrack {
            
            // There is a new track, select it if necessary
            
            if newTrack != oldTrack {
                
                // If this is not done async, the row view could get garbled.
                // (because of other potential simultaneous updates - e.g. PlayingTrackInfoUpdated)
                DispatchQueue.main.async {
                
                    self.playlistView.reloadItem(newTrack)
                    
                    let row = self.playlistView.row(forItem: newTrack)
                    self.playlistView.noteHeightOfRows(withIndexesChanged: IndexSet([row]))
                }
            }
            
            if needToShowTrack {
                showPlayingTrack()
            }
            
        } else if needToShowTrack {
 
            // No new track
            clearSelection()
        }
    }
    
    func trackNotPlayed(_ notification: TrackNotPlayedNotification) {
        
        let oldTrack = notification.oldTrack
        
        if let _oldTrack = oldTrack {
            playlistView.reloadItem(_oldTrack)
        }
        
        // TODO: Remove errTrack, simply reference track
        if let track = notification.error.track, let errTrack = playlist.indexOfTrack(track) {
            
            if errTrack.track != oldTrack {
                playlistView.reloadItem(errTrack.track)
            }
            
            // Only need to do this if this playlist view is shown
            if PlaylistViewState.current.toGroupType() == self.groupType {
                selectTrack(playlist.groupingInfoForTrack(self.groupType, errTrack.track))
            }
        }
    }
    
    // Selects an item within the playlist view, to show a single search result
    func selectSearchResult(_ command: SelectSearchResultCommandNotification) {
        selectTrack(command.searchResult.location.groupInfo)
    }
    
    // Show the selected track in Finder
    private func showTrackInFinder() {
        
        // This is a safe typecast, because the context menu will prevent this function from being executed on groups. In other words, the selected item will always be a track.
        if let selTrack = playlistView.item(atRow: playlistView.selectedRow) as? Track {
            FileSystemUtils.showFileInFinder(selTrack.file)
        }
    }
    
    private func insertGaps(_ gapBefore: PlaybackGap?, _ gapAfter: PlaybackGap?) {
        
        if let selTrack = playlistView.item(atRow: playlistView.selectedRow) as? Track {
            
            playlist.setGapsForTrack(selTrack, gapBefore, gapAfter)
            Messenger.publish(PlaybackGapUpdatedNotification(updatedTrack: selTrack))
        }
    }
    
    private func removeGaps() {
        
        if let selTrack = playlistView.item(atRow: playlistView.selectedRow) as? Track {
            
            playlist.removeGapsForTrack(selTrack)
            Messenger.publish(PlaybackGapUpdatedNotification(updatedTrack: selTrack))
        }
    }
    
    func gapUpdated(_ notification: PlaybackGapUpdatedNotification) {
        
        // Find track and refresh it
        let updatedRow = playlistView.row(forItem: notification.updatedTrack)
        
        if updatedRow >= 0 {
            refreshRow(updatedRow)
        }
    }
    
    private func refreshSelectedRow() {
        refreshRow(playlistView.selectedRow)
    }
    
    private func refreshRow(_ row: Int) {
        
        playlistView.reloadData(forRowIndexes: IndexSet([row]), columnIndexes: UIConstants.groupingPlaylistViewColumnIndexes)
        playlistView.noteHeightOfRows(withIndexesChanged: IndexSet([row]))
    }
    
    private func changeTextSize(_ textSize: TextSize) {
        
        let selRows = playlistView.selectedRowIndexes
        playlistView.reloadData()
        playlistView.selectRowIndexes(selRows, byExtendingSelection: false)
    }
    
    private func applyColorScheme(_ scheme: ColorScheme) {
        doApplyColorScheme(scheme)
    }
    
    private func doApplyColorScheme(_ scheme: ColorScheme, _ mustReloadRows: Bool = true) {
        
        changeBackgroundColor(scheme.general.backgroundColor)
        
        if mustReloadRows {
            
            playlistViewDelegate.changeGroupIconColor(scheme.playlist.groupIconColor)
            playlistViewDelegate.changeGapIndicatorColor(scheme.playlist.indexDurationSelectedTextColor)
            playlistView.changeDisclosureIconColor(scheme.playlist.groupDisclosureTriangleColor)
            
            let selRows = playlistView.selectedRowIndexes
            playlistView.reloadData()
            playlistView.selectRowIndexes(selRows, byExtendingSelection: false)
        }
    }
    
    private func changeBackgroundColor(_ color: NSColor) {
        
        scrollView.backgroundColor = color
        scrollView.drawsBackground = color.isOpaque
        
        clipView.backgroundColor = color
        clipView.drawsBackground = color.isOpaque
        
        playlistView.backgroundColor = color.isOpaque ? color : NSColor.clear
    }
    
    private var allRows: IndexSet {
        return IndexSet(integersIn: 0..<playlistView.numberOfRows)
    }
    
    private var allGroups: [Group] {
        return playlist.allGroups(self.groupType)
    }
    
    private func changeTrackNameTextColor(_ color: NSColor) {
        
        playlistViewDelegate.changeGapIndicatorColor(color)
        
        let trackRows = allRows.filteredIndexSet(includeInteger: {playlistView.item(atRow: $0) is Track})
        playlistView.reloadData(forRowIndexes: trackRows, columnIndexes: IndexSet([0]))
    }
    
    private func changeGroupNameTextColor(_ color: NSColor) {
        allGroups.forEach({playlistView.reloadItem($0)})
    }
    
    private func changeDurationTextColor(_ color: NSColor) {
        playlistView.reloadData(forRowIndexes: allRows, columnIndexes: IndexSet([1]))
    }
    
    private func changeTrackNameSelectedTextColor(_ color: NSColor) {
        
        let selTrackRows = playlistView.selectedRowIndexes.filteredIndexSet(includeInteger: {playlistView.item(atRow: $0) is Track})
        playlistView.reloadData(forRowIndexes: selTrackRows, columnIndexes: IndexSet([0]))
    }
    
    private func changeGroupNameSelectedTextColor(_ color: NSColor) {
        
        let selGroupRows = playlistView.selectedRowIndexes.filteredIndexSet(includeInteger: {playlistView.item(atRow: $0) is Group})
        playlistView.reloadData(forRowIndexes: selGroupRows, columnIndexes: IndexSet([0]))
    }
    
    private func changeDurationSelectedTextColor(_ color: NSColor) {
        playlistView.reloadData(forRowIndexes: playlistView.selectedRowIndexes, columnIndexes: IndexSet([1]))
    }
    
    private func changeSelectionBoxColor(_ color: NSColor) {
        
        // Note down the selected rows, clear the selection, and re-select the originally selected rows (to trigger a repaint of the selection boxes)
        let selRows = playlistView.selectedRowIndexes
        
        if !selRows.isEmpty {
            clearSelection()
            playlistView.selectRowIndexes(selRows, byExtendingSelection: false)
        }
    }
    
    private func changePlayingTrackIconColor(_ color: NSColor) {
        
        if let playingTrack = playbackInfo.currentTrack {
            playlistView.reloadItem(playingTrack)
        }
    }
    
    private func changeGroupIconColor(_ color: NSColor) {
        
        playlistViewDelegate.changeGroupIconColor(color)
        allGroups.forEach({playlistView.reloadItem($0)})
    }
    
    private func changeGroupDisclosureTriangleColor(_ color: NSColor) {
        playlistView.changeDisclosureIconColor(color)
    }
    
    // MARK: Message handlers
    
    func consumeMessage(_ message: ActionMessage) {
       
        if let colorChangeMsg = message as? ColorSchemeComponentActionMessage {
            
            switch colorChangeMsg.actionType {
                
            case .changeBackgroundColor:
                
                changeBackgroundColor(colorChangeMsg.color)
                
            case .changePlaylistTrackNameTextColor:
                
                changeTrackNameTextColor(colorChangeMsg.color)
                
            case .changePlaylistGroupNameTextColor:
                
                changeGroupNameTextColor(colorChangeMsg.color)
                
            case .changePlaylistIndexDurationTextColor:
                
                changeDurationTextColor(colorChangeMsg.color)
                
            case .changePlaylistTrackNameSelectedTextColor:
                
                changeTrackNameSelectedTextColor(colorChangeMsg.color)
                
            case .changePlaylistGroupNameSelectedTextColor:
                
                changeGroupNameSelectedTextColor(colorChangeMsg.color)
                
            case .changePlaylistIndexDurationSelectedTextColor:
                
                changeDurationSelectedTextColor(colorChangeMsg.color)
                
            case .changePlaylistPlayingTrackIconColor:
                
                changePlayingTrackIconColor(colorChangeMsg.color)
                
            case .changePlaylistSelectionBoxColor:
                
                changeSelectionBoxColor(colorChangeMsg.color)
                
            case .changePlaylistGroupIconColor:
                
                changeGroupIconColor(colorChangeMsg.color)
                
            case .changePlaylistGroupDisclosureTriangleColor:
                
                changeGroupDisclosureTriangleColor(colorChangeMsg.color)
                
            default: return
                
            }
            
            return
        }
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToNSPasteboardPasteboardTypeArray(_ input: [String]) -> [NSPasteboard.PasteboardType] {
	return input.map { key in NSPasteboard.PasteboardType(key) }
}
