/*
    Container for fonts used by the UI
 */

import Cocoa

struct Fonts {
    
    private static let gillSans11Font: NSFont = NSFont(name: "Gill Sans", size: 11)!
    
    private static let gillSans12LightFont: NSFont = NSFont(name: "Gill Sans Light", size: 12)!
    private static let gillSans12Font: NSFont = NSFont(name: "Gill Sans", size: 12)!
    private static let gillSans12SemiBoldFont: NSFont = NSFont(name: "Gill Sans Semibold", size: 12)!
    private static let gillSans12BoldFont: NSFont = NSFont(name: "Gill Sans Bold", size: 12)!
    
    private static let gillSans13Font: NSFont = NSFont(name: "Gill Sans", size: 13)!
    private static let gillSans13LightFont: NSFont = NSFont(name: "Gill Sans Light", size: 13)!
    
    // Fonts used by the playlist view
    static let playlistSelectedTextFont: NSFont = gillSans12Font
    static let playlistTextFont: NSFont = gillSans12LightFont
    
    static let playlistGroupNameSelectedTextFont: NSFont = gillSans12SemiBoldFont
    static let playlistGroupNameTextFont: NSFont = gillSans12Font
    
    static let playlistGroupItemSelectedTextFont: NSFont = gillSans12Font
    static let playlistGroupItemTextFont: NSFont = gillSans12LightFont
    
    // Font used by the effects tab view buttons
    static let tabViewButtonFont: NSFont = gillSans12Font
    static let tabViewButtonBoldFont: NSFont = gillSans12SemiBoldFont
    
    // Font used by modal dialog buttons
    static let modalDialogButtonFont: NSFont = gillSans12Font
    
    // Font used by modal dialog control buttons
    static let modalDialogControlButtonFont: NSFont = gillSans11Font
    
    // Font used by the search modal dialog navigation buttons
    static let modalDialogNavButtonFont: NSFont = gillSans12BoldFont
    
    // Font used by modal dialog check and radio buttons
    static let checkRadioButtonFont: NSFont = NSFont(name: "Gill Sans", size: 11)!
    
    // Fonts used by the track info popover view (key column and view column)
    static let popoverKeyFont: NSFont = gillSans13Font
    static let popoverValueFont: NSFont = gillSans13LightFont
    
    // Font used by the popup menus
    static let popupMenuFont: NSFont = NSFont(name: "Gill Sans", size: 10)!
}
