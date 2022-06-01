//
//  LibraryWindowController.swift
//  Aural
//
//  Copyright © 2021 Kartik Venugopal. All rights reserved.
//
//  This software is licensed under the MIT software license.
//  See the file "LICENSE" in the project root directory for license terms.
//  

import Cocoa

class LibraryWindowController: NSWindowController {
    
    override var windowNibName: String? {"LibraryWindow"}
    
    @IBOutlet weak var rootContainer: NSBox!
    @IBOutlet weak var controlsBox: NSBox!

    @IBOutlet weak var btnClose: TintedImageButton!
    @IBOutlet weak var lblCaption: NSTextField!
    
    @IBOutlet weak var splitView: NSSplitView!
    
    // The tab group that switches between the 4 playlist views
    @IBOutlet weak var tabGroup: NSTabView!
    
    // Spinner that shows progress when tracks are being added to any of the playlists.
    @IBOutlet weak var progressSpinner: NSProgressIndicator!
    
    private lazy var sidebarController: LibrarySidebarViewController = LibrarySidebarViewController()
    
    private lazy var libraryTracksController: LibraryTracksViewController = LibraryTracksViewController()
    private lazy var libraryArtistsController: LibraryArtistsViewController = LibraryArtistsViewController()
    private lazy var libraryAlbumsController: LibraryAlbumsViewController = LibraryAlbumsViewController()
    private lazy var libraryGenresController: LibraryGenresViewController = LibraryGenresViewController()
    private lazy var libraryDecadesController: LibraryDecadesViewController = LibraryDecadesViewController()
    
    private lazy var tuneBrowserViewController: TuneBrowserViewController = TuneBrowserViewController()
    
    private lazy var playlistsViewController: PlaylistsViewController = PlaylistsViewController()
    
    private lazy var messenger: Messenger = Messenger(for: self)
    
    override func windowDidLoad() {
        
        super.windowDidLoad()
        
        let libraryTracksView: NSView = libraryTracksController.view
        tabGroup.tabViewItem(at: 0).view?.addSubview(libraryTracksView)
        libraryTracksView.anchorToSuperview()
        
        let libraryArtistsView: NSView = libraryArtistsController.view
        tabGroup.tabViewItem(at: 1).view?.addSubview(libraryArtistsView)
        libraryArtistsView.anchorToSuperview()
        
        let libraryAlbumsView: NSView = libraryAlbumsController.view
        tabGroup.tabViewItem(at: 2).view?.addSubview(libraryAlbumsView)
        libraryAlbumsView.anchorToSuperview()

        let libraryGenresView: NSView = libraryGenresController.view
        tabGroup.tabViewItem(at: 3).view?.addSubview(libraryGenresView)
        libraryGenresView.anchorToSuperview()

        let libraryDecadesView: NSView = libraryDecadesController.view
        tabGroup.tabViewItem(at: 4).view?.addSubview(libraryDecadesView)
        libraryDecadesView.anchorToSuperview()
        
        let tuneBrowserView: NSView = tuneBrowserViewController.view
        tabGroup.tabViewItem(at: 5).view?.addSubview(tuneBrowserView)
        tuneBrowserView.anchorToSuperview()
        
        let playlistsView: NSView = playlistsViewController.view
        tabGroup.tabViewItem(at: 6).view?.addSubview(playlistsView)
        playlistsView.anchorToSuperview()
        
        let sidebarView: NSView = sidebarController.view
        splitView.arrangedSubviews[0].addSubview(sidebarView)
        sidebarView.anchorToSuperview()
        
        messenger.subscribe(to: .library_showBrowserTabForItem, handler: showBrowserTab(forItem:))
        messenger.subscribe(to: .library_showBrowserTabForItem, handler: showBrowserTab(forItem:))

        colorSchemesManager.registerObserver(rootContainer, forProperty: \.backgroundColor)
        colorSchemesManager.registerObserver(btnClose, forProperty: \.buttonColor)
        
        fontSchemesManager.registerObserver(lblCaption, forProperty: \.captionFont)
        colorSchemesManager.registerObserver(lblCaption, forProperty: \.captionTextColor)
        
        // TODO: Temporary, remove this !!!
        tabGroup.selectTabViewItem(at: 1)
    }
    
    @IBAction func closeAction(_ sender: Any) {
        windowLayoutsManager.toggleWindow(withId: .library)
    }
    
    private func showBrowserTab(forItem item: LibrarySidebarItem) {
        
        let tab = item.browserTab

        if tab == .playlists,
           let playlist = playlistsManager.userDefinedObject(named: item.displayName) {
            
            playlistsViewController.playlist = playlist
        }
        
        tabGroup.selectTabViewItem(at: tab.rawValue)
    }
    
    private func showBrowserTab(forCategory category: LibrarySidebarCategory) {

        let tab = category.browserTab
        tabGroup.selectTabViewItem(at: tab.rawValue)
//
//        if tab == .playlists {
//
//        }
    }
}
