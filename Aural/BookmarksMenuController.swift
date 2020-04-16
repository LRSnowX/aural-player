import Cocoa

/*
    Manages and provides actions for the Bookmarks menu that displays bookmarks that can be opened by the player.
 */
class BookmarksMenuController: NSObject, NSMenuDelegate {
    
    private var bookmarks: BookmarksDelegateProtocol = ObjectGraph.bookmarksDelegate
    
    // Delegate used to perform playback
    private let player: PlaybackDelegateProtocol = ObjectGraph.playbackDelegate
    
    @IBOutlet weak var bookmarkTrackPositionMenuItem: NSMenuItem!
    @IBOutlet weak var bookmarkTrackSegmentLoopMenuItem: NSMenuItem!
    @IBOutlet weak var manageBookmarksMenuItem: NSMenuItem!
    
    private lazy var editorWindowController: EditorWindowController = WindowFactory.editorWindowController
    
    fileprivate lazy var artLoadingQueue: OperationQueue = {
        
        let queue = OperationQueue()
        queue.underlyingQueue = DispatchQueue.global(qos: .userInteractive)
        queue.maxConcurrentOperationCount = max(SystemUtils.numberOfActiveCores / 2, 2)
        
        return queue
    }()
    
    // Before the menu opens, re-create the menu items from the model
    func menuNeedsUpdate(_ menu: NSMenu) {
        
        // Can't add a bookmark if no track is playing or if the popover is currently being shown
        let playingOrPaused = player.state.playingOrPaused()
        
        bookmarkTrackPositionMenuItem.enableIf(playingOrPaused && !WindowState.showingPopover)
        
        let loop = player.playbackLoop
        let hasCompleteLoop = loop != nil && loop!.isComplete()
        bookmarkTrackSegmentLoopMenuItem.enableIf(playingOrPaused && hasCompleteLoop)
        
        manageBookmarksMenuItem.enableIf(bookmarks.count > 0)
    }
    
    func menuWillOpen(_ menu: NSMenu) {
        
        // Remove existing (possibly stale) items, starting after the static items
        while menu.items.count > 4 {
            menu.removeItem(at: 4)
        }
        
        // Recreate the bookmarks menu
        bookmarks.allBookmarks.forEach({menu.addItem(createBookmarkMenuItem($0))})
    }
    
    func menuDidClose(_ menu: NSMenu) {
        artLoadingQueue.cancelAllOperations()
    }
    
    // Factory method to create a single history menu item, given a model object (HistoryItem)
    private func createBookmarkMenuItem(_ bookmark: Bookmark) -> NSMenuItem {
        
        // The action for the menu item will depend on whether it is a playable item
        let action = #selector(self.playSelectedItemAction(_:))
        
        let menuItem = BookmarksMenuItem(title: "  " + bookmark.name, action: action, keyEquivalent: "")
        menuItem.target = self
        
        menuItem.image = Images.imgPlayedTrack
        menuItem.image?.size = Images.historyMenuItemImageSize
        
        artLoadingQueue.addOperation {
            
            if let img = MetadataUtils.artForFile(bookmark.file), let imgCopy = img.image.copy() as? NSImage {
                
                imgCopy.size = Images.historyMenuItemImageSize
                
                DispatchQueue.main.async {
                    menuItem.image = imgCopy
                }
            }
        }
        
        menuItem.bookmark = bookmark
        
        return menuItem
    }
    
    // When a bookmark menu item is clicked, the item is played
    @IBAction func bookmarkTrackPositionAction(_ sender: Any) {
        SyncMessenger.publishActionMessage(BookmarkActionMessage(.bookmarkPosition))
    }
    
    // When a bookmark menu item is clicked, the item is played
    @IBAction func bookmarkTrackSegmentLoopAction(_ sender: Any) {
        SyncMessenger.publishActionMessage(BookmarkActionMessage(.bookmarkLoop))
    }
    
    // When a bookmark menu item is clicked, the item is played
    @IBAction fileprivate func playSelectedItemAction(_ sender: BookmarksMenuItem) {
        
        do {
            
            try bookmarks.playBookmark(sender.bookmark!)
            
        } catch let error {
            
            if let fnfError = error as? FileNotFoundError {
                
                // This needs to be done async. Otherwise, other open dialogs could hang.
                DispatchQueue.main.async {
                    
                    // Position and display an alert with error info
                    _ = UIUtils.showAlert(DialogsAndAlerts.trackNotPlayedAlertWithError(fnfError, "Remove bookmark"))
                    self.bookmarks.deleteBookmarkWithName(sender.bookmark.name)
                }
            }
        }
        
        // TODO: Offer more options like "Point to the new location of the file". See RecorderViewController for reference.
    }
    
    @IBAction func manageBookmarksAction(_ sender: Any) {
        editorWindowController.showBookmarksEditor()
    }
}

// Helper class that stores a Bookmark for convenience (when playing it)
class BookmarksMenuItem: NSMenuItem {
    
    var bookmark: Bookmark!
}
