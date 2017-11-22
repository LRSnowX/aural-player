import Cocoa

/*
    Manages and provides actions for the History menu that displays historical information about the usage of the app.
 */
class HistoryMenuController: NSObject, NSMenuDelegate, ActionMessageSubscriber {

    // The sub-menus that categorize and display historical information
    
    // Sub-menu that displays recently added files/folders. Clicking on any of these items will result in the item being added to the playlist if not already present.
    @IBOutlet weak var recentlyAddedMenu: NSMenu!
    
    // Sub-menu that displays recently played tracks. Clicking on any of these items will result in the track being played.
    @IBOutlet weak var recentlyPlayedMenu: NSMenu!
    
    // Sub-menu that displays tracks marked "favorites". Clicking on any of these items will result in the track being  played.
    @IBOutlet weak var favoritesMenu: NSMenu!
    
    // Delegate that performs CRUD on the history model
    private let history: HistoryDelegateProtocol = ObjectGraph.getHistoryDelegate()
    
    // One-time setup, when the menu loads
    override func awakeFromNib() {
        
        // Subscribe to message notifications
        SyncMessenger.subscribe(actionTypes: [.addFavorite, .removeFavorite], subscriber: self)
    }
    
    // Before the menu opens, re-create the menu items from the model
    func menuNeedsUpdate(_ menu: NSMenu) {
        
        // Clear the menus
        recentlyAddedMenu.removeAllItems()
        recentlyPlayedMenu.removeAllItems()
        favoritesMenu.removeAllItems()
        
        // Retrieve the model and re-create all sub-menu items
        createChronologicalMenu(history.allRecentlyAddedItems(), recentlyAddedMenu)
        createChronologicalMenu(history.allRecentlyPlayedItems(), recentlyPlayedMenu)
        history.allFavorites().forEach({favoritesMenu.addItem(createHistoryMenuItem($0))})
    }
    
    // Populates the given menu with items corresponding to the given historical item info, grouped by timestamp into categories like "Past 24 hours", "Past 7 days", etc.
    private func createChronologicalMenu(_ items: [HistoryItem], _ menu: NSMenu) {
        
        // Keeps track of which time categories have already been created
        var timeCategories = Set<TimeElapsed>()
        
        items.forEach({
            
            let menuItem = createHistoryMenuItem($0)
            
            // Figure out how old this item is
            let timeElapsed = DateUtils.timeElapsedSinceDate($0.time)
            
            // If this category doesn't already exist, create it
            if !timeCategories.contains(timeElapsed) {
                
                timeCategories.insert(timeElapsed)
                
                // Add a descriptor menu item that describes the time category, between 2 separators
                menu.addItem(NSMenuItem.separator())
                menu.addItem(createDescriptor(timeElapsed))
                menu.addItem(NSMenuItem.separator())
            }
            
            // Add the history menu item to the menu
            menu.addItem(menuItem)
        })
    }
    
    // Creates a menu item that describes a time category like "Past hour". The item will have no action.
    private func createDescriptor(_ timeElapsed: TimeElapsed) -> NSMenuItem {
        return NSMenuItem(title: timeElapsed.rawValue, action: nil, keyEquivalent: "")
    }
    
    // Factory method to create a single history menu item, given a model object (HistoryItem)
    private func createHistoryMenuItem(_ item: HistoryItem) -> NSMenuItem {
        
        // The action for the menu item will depend on whether it is a playable item
        let action = item is PlayableHistoryItem ? #selector(self.playSelectedItemAction(_:)) : #selector(self.addSelectedItemAction(_:))
        
        let menuItem = HistoryMenuItem(title: "  " + item.displayName, action: action, keyEquivalent: "")
        menuItem.target = self
        
        menuItem.image = item.art
        menuItem.image?.size = Images.historyMenuItemImageSize
        
        menuItem.historyItem = item
        
        return menuItem
    }
    
    // When a "Recently added" menu item is clicked, the item is added to the playlist
    @IBAction fileprivate func addSelectedItemAction(_ sender: HistoryMenuItem) {
        history.addItem(sender.historyItem.file)
    }
    
    // When a "Recently played" or "Favorites" menu item is clicked, the item is played
    @IBAction fileprivate func playSelectedItemAction(_ sender: HistoryMenuItem) {
        history.playItem(sender.historyItem.file, PlaylistViewState.current)
    }
    
    // Adds a track to the "Favorites" list
    private func addFavorite(_ message: FavoritesActionMessage) {
        history.addFavorite(message.track)
    }
    
    // Removes a track from the "Favorites" list
    private func removeFavorite(_ message: FavoritesActionMessage) {
        history.removeFavorite(message.track)
    }
    
    // MARK: Message handling
    
    func consumeMessage(_ message: ActionMessage) {
        
        let message = message as! FavoritesActionMessage
        
        switch message.actionType {
            
        case .addFavorite:
            
            addFavorite(message)
            
        case .removeFavorite:
            
            removeFavorite(message)
            
        default: return
            
        }
    }
}

// A menu item that stores an associated history item (used when executing the menu item action)
fileprivate class HistoryMenuItem: NSMenuItem {
    
    var historyItem: HistoryItem!
}
