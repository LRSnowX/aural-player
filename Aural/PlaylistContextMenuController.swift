import Cocoa

/*
    Controller for the contextual menu displayed when a playlist item is right-clicked
 */
class PlaylistContextMenuController: NSObject, NSMenuDelegate {
    
    // Not used within this class, but exposed to playlist view classes
    @IBOutlet weak var contextMenu: NSMenu!
    
    // Track-specific menu items
    
    @IBOutlet weak var playTrackMenuItem: NSMenuItem!
    @IBOutlet weak var favoritesMenuItem: ToggleMenuItem!
    @IBOutlet weak var detailedInfoMenuItem: NSMenuItem!
    
    @IBOutlet weak var removeTrackMenuItem: NSMenuItem!
    @IBOutlet weak var moveTrackUpMenuItem: NSMenuItem!
    @IBOutlet weak var moveTrackDownMenuItem: NSMenuItem!
    
    private var trackMenuItems: [NSMenuItem] = []
    
    // Group-specific menu items
    
    @IBOutlet weak var playGroupMenuItem: NSMenuItem!
    @IBOutlet weak var removeGroupMenuItem: NSMenuItem!
    @IBOutlet weak var moveGroupUpMenuItem: NSMenuItem!
    @IBOutlet weak var moveGroupDownMenuItem: NSMenuItem!
    
    private var groupMenuItems: [NSMenuItem] = []
    
    // Popover view that displays detailed info for the selected track
    private lazy var detailedInfoPopover: PopoverViewDelegate = ViewFactory.getDetailedTrackInfoPopover()
    
    // Popup view that displays a brief notification when a selected track is added/removed to/from the Favorites list
    private lazy var favoritesPopup: FavoritesPopupProtocol = ViewFactory.getFavoritesPopup()
    
    // Delegate that relays CRUD actions to the playlist
    private let playlist: PlaylistDelegateProtocol = ObjectGraph.getPlaylistDelegate()
    
    // Delegate that retrieves current playback info
    private let playbackInfo: PlaybackInfoDelegateProtocol = ObjectGraph.getPlaybackInfoDelegate()
    
    // Delegate that provides access to History information
    private let history: HistoryDelegateProtocol = ObjectGraph.getHistoryDelegate()
    
    // One-time setup
    override func awakeFromNib() {
        
        // Store all track-specific and group-specific menu items in separate arrays for convenient access when setting up the menu prior to display
        
        trackMenuItems = [playTrackMenuItem, favoritesMenuItem, detailedInfoMenuItem, removeTrackMenuItem, moveTrackUpMenuItem, moveTrackDownMenuItem]
        
        groupMenuItems = [playGroupMenuItem, removeGroupMenuItem, moveGroupUpMenuItem, moveGroupDownMenuItem]
        
        // Set up the two possible captions for the favorites menu item
        
        favoritesMenuItem.offStateTitle = Strings.favoritesAddCaption_contextMenu
        favoritesMenuItem.onStateTitle = Strings.favoritesRemoveCaption_contextMenu
    }
    
    // Sets up the menu items that need to be displayed, depending on what type of playlist item was clicked, and the current state of that item
    func menuNeedsUpdate(_ menu: NSMenu) {
        
        let clickedItem = PlaylistViewContext.clickedItem
        
        switch clickedItem.type {
            
        case .index, .track:
            
            // Show all track-specific menu items, hide group-specific ones
            trackMenuItems.forEach({$0.isHidden = false})
            groupMenuItems.forEach({$0.isHidden = true})
            
            // Update the state of the favorites menu item (based on if the clicked track is already in the favorites list or not)
            let track = clickedItem.type == .index ? playlist.trackAtIndex(clickedItem.index!)!.track : clickedItem.track!
            favoritesMenuItem.onIf(history.hasFavorite(track))
            
        case .group:
            
            // Show all group-specific menu items, hide track-specific ones
            trackMenuItems.forEach({$0.isHidden = true})
            groupMenuItems.forEach({$0.isHidden = false})
        }
    }
    
    // Plays the selected playlist item (track or group)
    @IBAction func playSelectedItemAction(_ sender: Any) {
        SyncMessenger.publishActionMessage(PlaylistActionMessage(.playSelectedItem, PlaylistViewState.current))
    }
    
    // Adds/removes the currently playing track, if there is one, to/from the "Favorites" list
    @IBAction func favoritesAction(_ sender: Any) {
        
        let track = getClickedTrack()
        let rowView = getPlaylistSelectedRowView()
        
        if favoritesMenuItem.isOn() {
        
            // Remove from Favorites list and display notification
            
            history.removeFavorite(track)
            favoritesPopup.showRemovedMessage(rowView, NSRectEdge.maxX)
            WindowState.window.makeKeyAndOrderFront(self)
            
        } else {
            
            // Add to Favorites list and display notification
            
            history.addFavorite(track)
            favoritesPopup.showAddedMessage(rowView, NSRectEdge.maxX)
            WindowState.window.makeKeyAndOrderFront(self)
        }
    }
    
    // Shows a popover with detailed information for the currently playing track, if there is one
    @IBAction func moreInfoAction(_ sender: AnyObject) {
        
        let track = getClickedTrack()
        track.loadDetailedInfo()
        
        let rowView = getPlaylistSelectedRowView()
        
        detailedInfoPopover.show(track, rowView, NSRectEdge.maxY)
        WindowState.window.makeKeyAndOrderFront(self)
    }
    
    // Helper to determine the track represented by the clicked item
    private func getClickedTrack() -> Track {
        
        let clickedItem = PlaylistViewContext.clickedItem
        return clickedItem.type == .index ? playlist.trackAtIndex(clickedItem.index!)!.track : clickedItem.track!
    }
    
    // Helper to obtain the view for the selected playlist row (used to position popovers)
    private func getPlaylistSelectedRowView() -> NSView {
        
        let playlistView = PlaylistViewContext.clickedView
        return playlistView.rowView(atRow: playlistView.selectedRow, makeIfNecessary: false)!
    }
 
    // Removes the selected playlist item from the playlist
    @IBAction func removeSelectedItemAction(_ sender: Any) {
        SyncMessenger.publishActionMessage(PlaylistActionMessage(.removeTracks, PlaylistViewState.current))
        sequenceChanged()
    }
    
    // Moves the selected playlist item up one row in the playlist
    @IBAction func moveItemUpAction(_ sender: Any) {
        SyncMessenger.publishActionMessage(PlaylistActionMessage(.moveTracksUp, PlaylistViewState.current))
        sequenceChanged()
    }
    
    // Moves the selected playlist item down one row in the playlist
    @IBAction func moveItemDownAction(_ sender: Any) {
        SyncMessenger.publishActionMessage(PlaylistActionMessage(.moveTracksDown, PlaylistViewState.current))
        sequenceChanged()
    }
    
    // Publishes a notification that the playback sequence may have changed, so that interested UI observers may update their views if necessary
    private func sequenceChanged() {
        if (playbackInfo.getPlayingTrack() != nil) {
            SyncMessenger.publishNotification(SequenceChangedNotification.instance)
        }
    }
}
