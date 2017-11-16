/*
    Handles loading/saving of app user preferences
 */
import Foundation
import Cocoa

class Preferences {
    
    private static let singleton: Preferences = Preferences()
    
    private static let defaults: UserDefaults = UserDefaults.standard
    private static let defaultsDict: [String: Any] = defaults.dictionaryRepresentation()
    
    // Defaults values to use if saved preferences are unavailable
    
    // The (cached) user preferences. Values are held in these variables during app execution, and persisted upon exiting.
    var seekLength_discrete: Int
    var seekLength_continuous: Int
    var volumeDelta_discrete: Float
    var volumeDelta_continuous: Float
    var volumeOnStartup: VolumeStartupOptions
    var startupVolumeValue: Float
    var panDelta: Float
    
    var playlistOnStartup: PlaylistStartupOptions
    var autoplayOnStartup: Bool
    var autoplayAfterAddingTracks: Bool
    var autoplayAfterAddingOption: AutoplayAfterAddingOptions
    
    var viewOnStartup: ViewOnStartup
    var windowLocationOnStartup: WindowLocationOnStartup
    var playlistLocationOnStartup: PlaylistLocationOnStartup
    
    private init() {
        
        let prefs = Preferences.defaultsDict
        
        // Player prefs
        
        seekLength_discrete = prefs["seekLength_discrete"] as? Int ?? PreferencesDefaults.seekLength_discrete
        seekLength_continuous = prefs["seekLength_continuous"] as? Int ?? PreferencesDefaults.seekLength_continuous
        
        volumeDelta_discrete = prefs["volumeDelta_discrete"] as? Float ?? PreferencesDefaults.volumeDelta_discrete
        volumeDelta_continuous = prefs["volumeDelta_continuous"] as? Float ?? PreferencesDefaults.volumeDelta_continuous
        
        if let volumeOnStartupStr = prefs["volumeOnStartup"] as? String {
            volumeOnStartup = VolumeStartupOptions(rawValue: volumeOnStartupStr)!
        } else {
            volumeOnStartup = PreferencesDefaults.volumeOnStartup
        }
        
        startupVolumeValue = prefs["startupVolumeValue"] as? Float ?? PreferencesDefaults.startupVolumeValue
        
        panDelta = prefs["panDelta"] as? Float ?? PreferencesDefaults.panDelta
        
        // Playlist prefs
        
        if let playlistOnStartupStr = prefs["playlistOnStartup"] as? String {
            playlistOnStartup = PlaylistStartupOptions(rawValue: playlistOnStartupStr)!
        } else {
            playlistOnStartup = PreferencesDefaults.playlistOnStartup
        }
        
        autoplayOnStartup = prefs["autoplayOnStartup"] as? Bool ?? PreferencesDefaults.autoplayOnStartup
        
        autoplayAfterAddingTracks = prefs["autoplayAfterAddingTracks"] as? Bool ?? PreferencesDefaults.autoplayAfterAddingTracks
        
        if let autoplayAfterAddingOptionStr = prefs["autoplayAfterAddingTracks.option"] as? String {
            autoplayAfterAddingOption = AutoplayAfterAddingOptions(rawValue: autoplayAfterAddingOptionStr)!
        } else {
            autoplayAfterAddingOption = PreferencesDefaults.autoplayAfterAddingOption
        }
        
        // View prefs
        
        viewOnStartup = PreferencesDefaults.viewOnStartup
        
        if let viewOnStartupOptionStr = prefs["viewOnStartup.option"] as? String {
            viewOnStartup.option = ViewStartupOptions(rawValue: viewOnStartupOptionStr)!
        }
        
        if let viewTypeStr = prefs["viewOnStartup.viewType"] as? String {
            viewOnStartup.viewType = ViewTypes(rawValue: viewTypeStr)!
        }
        
        windowLocationOnStartup = PreferencesDefaults.windowLocationOnStartup
        
        if let windowLocationOnStartupOptionStr = prefs["windowLocationOnStartup.option"] as? String {
            windowLocationOnStartup.option = WindowLocationOptions(rawValue: windowLocationOnStartupOptionStr)!
        }
        
        if let windowLocationStr = prefs["windowLocationOnStartup.location"] as? String {
            windowLocationOnStartup.windowLocation = WindowLocations(rawValue: windowLocationStr)!
        }
        
        playlistLocationOnStartup = PreferencesDefaults.playlistLocationOnStartup
        
        if let playlistLocationOnStartupOptionStr = prefs["playlistLocationOnStartup.option"] as? String {
            playlistLocationOnStartup.option = PlaylistLocationOptions(rawValue: playlistLocationOnStartupOptionStr)!
        }
        
        if let playlistLocationStr = prefs["playlistLocationOnStartup.location"] as? String {
            playlistLocationOnStartup.playlistLocation = PlaylistLocations(rawValue: playlistLocationStr)!
        }
    }
    
    static func instance() -> Preferences {
        return singleton
    }
    
    // Saves the preferences to disk (copies the values from the cache to UserDefaults)
    static func persist(_ prefs: Preferences) {
        
        defaults.set(prefs.seekLength_discrete, forKey: "seekLength_discrete")
        defaults.set(prefs.seekLength_continuous, forKey: "seekLength_continuous")
        
        defaults.set(prefs.volumeDelta_discrete, forKey: "volumeDelta_discrete")
        defaults.set(prefs.volumeDelta_continuous, forKey: "volumeDelta_continuous")
        
        defaults.set(prefs.volumeOnStartup.rawValue, forKey: "volumeOnStartup")
        defaults.set(prefs.startupVolumeValue, forKey: "startupVolumeValue")
        
        defaults.set(prefs.panDelta, forKey: "panDelta")
        
        defaults.set(prefs.autoplayOnStartup, forKey: "autoplayOnStartup")
        defaults.set(prefs.autoplayAfterAddingTracks, forKey: "autoplayAfterAddingTracks")
        defaults.set(prefs.autoplayAfterAddingOption.rawValue, forKey: "autoplayAfterAddingTracks.option")
        
        defaults.set(prefs.playlistOnStartup.rawValue, forKey: "playlistOnStartup")
        
        defaults.set(prefs.viewOnStartup.option.rawValue, forKey: "viewOnStartup.option")
        defaults.set(prefs.viewOnStartup.viewType.rawValue, forKey: "viewOnStartup.viewType")
        
        defaults.set(prefs.windowLocationOnStartup.option.rawValue, forKey: "windowLocationOnStartup.option")
        defaults.set(prefs.windowLocationOnStartup.windowLocation.rawValue, forKey: "windowLocationOnStartup.location")
        
        defaults.set(prefs.playlistLocationOnStartup.option.rawValue, forKey: "playlistLocationOnStartup.option")
        defaults.set(prefs.playlistLocationOnStartup.playlistLocation.rawValue, forKey: "playlistLocationOnStartup.location")
    }
}

/*
    Container for default values for user preferences
 */
class PreferencesDefaults {
    
    // Player prefs
    static let seekLength_discrete: Int = 5
    static let seekLength_continuous: Int = 3
    
    static let volumeDelta_discrete: Float = 0.05
    static let volumeDelta_continuous: Float = 0.025
    
    static let volumeOnStartup: VolumeStartupOptions = .rememberFromLastAppLaunch
    static let startupVolumeValue: Float = 0.5
    
    static let panDelta: Float = 0.1
    
    static let autoplayOnStartup: Bool = false
    static let autoplayAfterAddingTracks: Bool = false
    static let autoplayAfterAddingOption: AutoplayAfterAddingOptions = .ifNotPlaying
    
    // Playlist prefs
    static let playlistOnStartup: PlaylistStartupOptions = .rememberFromLastAppLaunch
    
    // View prefs
    static let viewOnStartup: ViewOnStartup = ViewOnStartup.defaultInstance
    static let windowLocationOnStartup: WindowLocationOnStartup = WindowLocationOnStartup.defaultInstance
    static let playlistLocationOnStartup: PlaylistLocationOnStartup = PlaylistLocationOnStartup.defaultInstance
}
