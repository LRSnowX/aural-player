import Cocoa

class FavoritesMenuController: NSObject, NSMenuDelegate {
    
    // Menu that displays tracks marked "favorites". Clicking on any of these items will result in the track being  played.
    @IBOutlet weak var favoritesMenu: NSMenu!
    
    @IBOutlet weak var addRemoveFavoritesMenuItem: ToggleMenuItem!
    @IBOutlet weak var manageFavoritesMenuItem: NSMenuItem!    

    // Delegate that performs CRUD on the favorites model
    private let favorites: FavoritesDelegateProtocol = ObjectGraph.favoritesDelegate
    
    private lazy var playbackInfo: PlaybackInfoDelegateProtocol = ObjectGraph.playbackInfoDelegate
    
    private lazy var editorWindowController: EditorWindowController = WindowFactory.editorWindowController
    
    fileprivate lazy var artLoadingQueue: OperationQueue = {
        
        let queue = OperationQueue()
        queue.underlyingQueue = DispatchQueue.global(qos: .userInteractive)
        queue.maxConcurrentOperationCount = max(SystemUtils.numberOfActiveCores / 2, 2)
        
        return queue
    }()
    
    // One-time setup, when the menu loads
    override func awakeFromNib() {
        addRemoveFavoritesMenuItem.off()
    }
    
    // Before the menu opens, re-create the menu items from the model
    func menuNeedsUpdate(_ menu: NSMenu) {
        
        // These menu item actions are only available when a track is currently playing/paused
        addRemoveFavoritesMenuItem.enableIf(playbackInfo.state.playingOrPaused())
        
        // Menu has 3 static items
        manageFavoritesMenuItem.enableIf(favorites.countFavorites() > 0)
    }

    func menuWillOpen(_ menu: NSMenu) {
        
        if let playingTrackFile = playbackInfo.playingTrack?.track.file {
            addRemoveFavoritesMenuItem.onIf(favorites.favoriteWithFileExists(playingTrackFile))
        } else {
            addRemoveFavoritesMenuItem.off()
        }
        
        // Remove existing (possibly stale) items, starting after the static items
        while favoritesMenu.items.count > 3 {
            favoritesMenu.removeItem(at: 3)
        }
        
        // Recreate the menu
        favorites.getAllFavorites().forEach({favoritesMenu.addItem(createFavoritesMenuItem($0))})
    }
    
    func menuDidClose(_ menu: NSMenu) {
        artLoadingQueue.cancelAllOperations()
    }
    
    // Factory method to create a single Favorites menu item, given a model object (FavoritesItem)
    private func createFavoritesMenuItem(_ item: Favorite) -> NSMenuItem {
        
        // The action for the menu item will depend on whether it is a playable item
        let action = #selector(self.playSelectedItemAction(_:))
        
        let menuItem = FavoritesMenuItem(title: "  " + item.name, action: action, keyEquivalent: "")
        menuItem.target = self
        
        menuItem.image = Images.imgPlayedTrack
        menuItem.image?.size = Images.historyMenuItemImageSize
        
        artLoadingQueue.addOperation {
            
            if let img = MetadataUtils.artForFile(item.file), let imgCopy = img.image.copy() as? NSImage {
                
                imgCopy.size = Images.historyMenuItemImageSize
                
                DispatchQueue.main.async {
                    menuItem.image = imgCopy
                }
            }
        }
        
        menuItem.favorite = item
        
        return menuItem
    }
    
    // Adds/removes the currently playing track, if there is one, to/from the "Favorites" list
    @IBAction func favoritesAction(_ sender: Any) {
        
        // Check if there is a track playing (this function cannot be invoked otherwise)
        if let playingTrack = (playbackInfo.playingTrack?.track) {
            
            // Publish an action message to add/remove the item to/from Favorites
            if favorites.favoriteWithFileExists(playingTrack.file) {
                favorites.deleteFavoriteWithFile(playingTrack.file)
            } else {
                _ = favorites.addFavorite(playingTrack)
            }
        }
    }
    
    // When a "Favorites" menu item is clicked, the item is played
    @IBAction fileprivate func playSelectedItemAction(_ sender: FavoritesMenuItem) {
        
        let fav = sender.favorite!
        
        do {
            
            try favorites.playFavorite(fav)
            
        } catch let error {
            
            if let fnfError = error as? FileNotFoundError {
                
                // This needs to be done async. Otherwise, other open dialogs could hang.
                DispatchQueue.main.async {
                    
                    // Position and display an alert with error info
                    _ = UIUtils.showAlert(DialogsAndAlerts.trackNotPlayedAlertWithError(fnfError, "Remove favorite"))
                    self.favorites.deleteFavoriteWithFile(fav.file)
                }
            }
        }
    }
    
    // Opens the editor to manage favorites
    @IBAction func manageFavoritesAction(_ sender: Any) {
        editorWindowController.showFavoritesEditor()
    }
    
    // MARK: Message handling
    
    var subscriberId: String {
        return self.className
    }
}

class FavoritesMenuItem: NSMenuItem {
    
    var favorite: Favorite!
}
