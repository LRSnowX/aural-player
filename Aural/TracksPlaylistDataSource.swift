import Cocoa

/*
    Data source and view delegate for the NSTableView that displays the "Tracks" (flat) playlist view.
 */
class TracksPlaylistDataSource: NSViewController, NSTableViewDataSource, NSTableViewDelegate, MessageSubscriber {
    
    // Delegate that relays accessor operations to the playlist
    private let playlist: PlaylistAccessorDelegateProtocol = ObjectGraph.getPlaylistAccessorDelegate()
    
    // Used to determine the currently playing track
    private let playbackInfo: PlaybackInfoDelegateProtocol = ObjectGraph.getPlaybackInfoDelegate()
    
    // Handles all drag/drop operations
    private let dragDropDelegate: TracksPlaylistDragDropDelegate = TracksPlaylistDragDropDelegate()
    
    // Stores the cell containing the playing track animation, for convenient access when pausing/resuming the animation
    private var animationCell: PlaylistCellView?
    
    override func viewDidLoad() {
        
        // Subscribe to message notifications
        SyncMessenger.subscribe(messageTypes: [.playbackStateChangedNotification, .playlistTypeChangedNotification, .appInForegroundNotification, .appInBackgroundNotification], subscriber: self)
        
        // Store the NSTableView in a variable for convenient subsequent access
        TableViewHolder.instance = self.view as? NSTableView
    }
    
    // MARK: Data Source
    
    // Returns the total number of playlist rows
    func numberOfRows(in tableView: NSTableView) -> Int {
        return playlist.size()
    }
    
    // MARK: View Delegate
    
    // Returns a view for a single row
    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        return FlatPlaylistRowView()
    }
    
    // Enables type selection, allowing the user to conveniently and efficiently find a playlist track by typing its display name, which results in the track, if found, being selected within the playlist
    func tableView(_ tableView: NSTableView, typeSelectStringFor tableColumn: NSTableColumn?, row: Int) -> String? {
        
        // Only the track name column is used for type selection
        if (tableColumn?.identifier != UIConstants.playlistNameColumnID) {
            return nil
        }
        
        return playlist.trackAtIndex(row)?.track.conciseDisplayName
    }
    
    // Returns a view for a single column
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        if let track = playlist.trackAtIndex(row)?.track {
            
            switch tableColumn!.identifier {
                
            case UIConstants.playlistIndexColumnID:
                
                // Track index
                let playingTrackIndex = playbackInfo.getPlayingTrack()?.index
                
                // If this row contains the playing track, display an animation, instead of the track index
                if (playingTrackIndex != nil && playingTrackIndex == row) {
                    
                    animationCell = createPlayingTrackAnimationCell(tableView)
                    return animationCell
                    
                } else {
                    
                    // Otherwise, create a text cell with the track index
                    return createTextCell(tableView, UIConstants.playlistIndexColumnID, String(format: "%d.", row + 1), row)
                }
                
            case UIConstants.playlistNameColumnID:
                
                // Track name
                return createTextCell(tableView, UIConstants.playlistNameColumnID, track.conciseDisplayName, row)
                
            case UIConstants.playlistDurationColumnID:
                
                // Duration
                return createTextCell(tableView, UIConstants.playlistDurationColumnID, StringUtils.formatSecondsToHMS(track.duration), row)
                
            default: return nil
                
            }
        }
        
        return nil
    }
    
    // Creates a cell view containing text
    private func createTextCell(_ tableView: NSTableView, _ id: String, _ text: String, _ row: Int) -> PlaylistCellView? {
        
        if let cell = tableView.make(withIdentifier: id, owner: nil) as? PlaylistCellView {
            
            cell.textField?.stringValue = text
            
            // Hide the image view and show the text view
            cell.imageView?.isHidden = true
            cell.textField?.isHidden = false

            cell.row = row
            
            return cell
        }
        
        return nil
    }
    
    // Creates a cell view containing the animation for the currently playing track
    private func createPlayingTrackAnimationCell(_ tableView: NSTableView) -> PlaylistCellView? {
        
        if let cell = tableView.make(withIdentifier: UIConstants.playlistIndexColumnID, owner: nil) as? PlaylistCellView {
            
            // Configure and show the image view
            let imgView = cell.imageView!
            
            imgView.canDrawSubviewsIntoLayer = true
            imgView.imageScaling = .scaleProportionallyDown
            imgView.animates = shouldAnimate()
            imgView.image = Images.imgPlayingTrack
            imgView.isHidden = false
            
            // Hide the text view
            cell.textField?.isHidden = true
            
            return cell
        }
        
        return nil
    }
    
    // Helper function that determines whether or not the playing track animation should be shown animated or static
    private func shouldAnimate() -> Bool {
    
        // Animation enabled only if 1 - the appropriate playlist view is currently shown, 2 - a track is currently playing (not paused), and 3 - the app window is currently in the foreground
        
        let playing = playbackInfo.getPlaybackState() == .playing
        let showingThisPlaylistView = PlaylistViewState.current == .tracks
        
        return playing && WindowState.inForeground && showingThisPlaylistView
    }
    
    // MARK: Drag n drop
    
    // Drag n drop - writes source information to the pasteboard
    func tableView(_ tableView: NSTableView, writeRowsWith rowIndexes: IndexSet, to pboard: NSPasteboard) -> Bool {
        return dragDropDelegate.tableView(tableView, writeRowsWith: rowIndexes, to: pboard)
    }
    
    // Drag n drop - determines the drag/drop operation
    func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableViewDropOperation) -> NSDragOperation {
        
        return dragDropDelegate.tableView(tableView, validateDrop: info, proposedRow: row, proposedDropOperation: dropOperation)
    }
    
    // Drag n drop - accepts and performs the drop
    func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableViewDropOperation) -> Bool {
        
        return dragDropDelegate.tableView(tableView, acceptDrop: info, row: row, dropOperation: dropOperation)
    }
    
    // MARK: Message handling
    
    // Whenever the playing track is paused/resumed, the animation needs to be paused/resumed.
    private func playbackStateChanged(_ message: PlaybackStateChangedNotification) {
        
        animationCell?.imageView?.animates = shouldAnimate()
        
        if message.newPlaybackState == .noTrack {
            
            // The track is no longer playing
            animationCell = nil
        }
    }
    
    // When the current playlist view changes, the animation state might need to change
    private func playlistTypeChanged(_ notification: PlaylistTypeChangedNotification) {
        animationCell?.imageView?.animates = shouldAnimate()
    }
    
    // When the app moves to the background, the animation should be disabled
    private func appInBackground() {
        animationCell?.imageView?.animates = false
    }
    
    // When the app moves to the foreground, the animation might need to be enabled
    private func appInForeground() {
        animationCell?.imageView?.animates = shouldAnimate()
    }
    
    func consumeNotification(_ notification: NotificationMessage) {
        
        switch notification.messageType {
            
        case .playbackStateChangedNotification:
            
            playbackStateChanged(notification as! PlaybackStateChangedNotification)
            
        case .playlistTypeChangedNotification:
            
            playlistTypeChanged(notification as! PlaylistTypeChangedNotification)
            
        case .appInBackgroundNotification:
            
            appInBackground()
            
        case .appInForegroundNotification:
            
            appInForeground()
            
        default: return
            
        }
    }
    
    func processRequest(_ request: RequestMessage) -> ResponseMessage {
        return EmptyResponse.instance
    }
}

/*
    Custom view for a NSTableView row that displays a single playlist track. Customizes the selection look and feel.
 */
class FlatPlaylistRowView: NSTableRowView {
    
    // Draws a fancy rounded rectangle around the selected track in the playlist view
    override func drawSelection(in dirtyRect: NSRect) {
        
        if self.selectionHighlightStyle != NSTableViewSelectionHighlightStyle.none {
            
            let selectionRect = self.bounds.insetBy(dx: 1, dy: 0)
            
            let selectionPath = NSBezierPath.init(roundedRect: selectionRect, xRadius: 2, yRadius: 2)
            Colors.playlistSelectionBoxColor.setFill()
            selectionPath.fill()
        }
    }
}

/*
    Custom view for a single NSTableView cell. Customizes the look and feel of cells (in selected rows) - font and text color.
 */
class PlaylistCellView: NSTableCellView {
    
    // The table view row that this cell is contained in. Used to determine whether or not this cell is selected.
    var row: Int = -1

    // When the background changes (as a result of selection/deselection) switch to the appropriate colors/fonts
    override var backgroundStyle: NSBackgroundStyle {
        
        didSet {
            
            // Check if this row is selected
            let isSelRow = TableViewHolder.instance!.selectedRowIndexes.contains(row)
            
            if let textField = self.textField {
                
                textField.textColor = isSelRow ? Colors.playlistSelectedTextColor : Colors.playlistTextColor
                textField.font = isSelRow ? Fonts.playlistSelectedTextFont : Fonts.playlistTextFont
            }
        }
    }
}

// Utility class to hold an NSTableView instance for convenient access
fileprivate class TableViewHolder {
    
    static var instance: NSTableView?
}
