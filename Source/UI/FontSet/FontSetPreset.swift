import Cocoa

/*
    Enumeration of all system-defined font sets.
 */
enum FontSetPreset: String, CaseIterable {
    
    // A dark scheme with a black background (the default scheme) and lighter foreground elements.
    case standard
    
    // A light scheme with an off-white background and dark foreground elements.
    case programmer
//
//    // A dark scheme with a black background and aqua coloring of active sliders.
//    case novelist
//
//    // A semi-dark scheme with a gray background and lighter foreground elements.
    case gothic
    
    // The preset to be used as the default system scheme (eg. when a user loads the app for the very first time)
    // or when some color values in a scheme are missing.
    static var defaultSet: FontSetPreset {
        return standard
    }
    
    // Maps a display name to a preset.
    static func presetByName(_ name: String) -> FontSetPreset? {
        
        switch name {
            
        case FontSetPreset.standard.name:    return .standard
            
        case FontSetPreset.programmer.name:    return .programmer
            
        case FontSetPreset.gothic.name:    return .gothic
            
        default:    return nil
            
        }
    }
    
    // Returns a user-friendly display name for this preset.
    var name: String {
        
        switch self {
            
        case .standard:  return "Standard"
            
        case .programmer:  return "Programmer"
            
//        case .novelist:    return "Black & aqua"
            
        case .gothic:    return "Gothic"
            
        }
    }
    
//    var menuFont_normal: NSFont
//    var menuFont_larger: NSFont
//    var menuFont_largest: NSFont
//
//    var stringInputPopoverFont_normal: NSFont
//    var stringInputPopoverFont_larger: NSFont
//    var stringInputPopoverFont_largest: NSFont
//
//    var stringInputPopoverErrorFont_normal: NSFont
//    var stringInputPopoverErrorFont_larger: NSFont
//    var stringInputPopoverErrorFont_largest: NSFont
    
//    var progressArcFont: NSFont
    
    // Font used by the popup menus
//    var popupMenuFont: NSFont
    
    var menuFont_normal: NSFont {
        
        switch self {
            
        case .standard:  return Fonts.Standard.mainFont_11
            
        case .programmer:  return Fonts.Programmer.mainFont_11
            
//        case .novelist:  return Colors.Constants.white50Percent
            
        case .gothic:    return Fonts.Gothic.mainFont_13
            
        }
    }
    
    var infoBoxTitleFont_normal: NSFont {
        
        switch self {
            
        case .standard:  return Fonts.Standard.mainFont_16
            
        case .programmer:  return Fonts.Programmer.mainFont_14
            
    //        case .novelist:  return Colors.Constants.white50Percent
            
        case .gothic:    return Fonts.Gothic.mainFont_14
            
        }
    }
    
    var infoBoxArtistAlbumFont_normal: NSFont {
        
        switch self {
            
        case .standard:  return Fonts.Standard.mainFont_14
            
        case .programmer:  return Fonts.Programmer.mainFont_12
            
    //        case .novelist:  return Colors.Constants.white50Percent
            
        case .gothic:    return Fonts.Gothic.mainFont_12
            
        }
    }
    
    var trackTimesFont_normal: NSFont {
        
        switch self {
                
            case .standard:  return Fonts.Standard.mainFont_12
                
            case .programmer:  return Fonts.Programmer.mainFont_11
                
        //        case .novelist:  return Colors.Constants.white50Percent
                
            case .gothic:    return Fonts.Gothic.mainFont_13
                
        }
    }
    
    var playlistTrackTextFont_normal: NSFont {
        
        switch self {
                
            case .standard:  return Fonts.Standard.mainFont_13
                
            case .programmer:  return Fonts.Programmer.mainFont_12
                
        //        case .novelist:  return Colors.Constants.white50Percent
                
            case .gothic:    return Fonts.Gothic.mainFont_12
                
        }
    }
    
    var playlistTabTextFont_normal: NSFont {
        
        switch self {
                
            case .standard:  return Fonts.Standard.captionFont_14
                
            case .programmer:  return Fonts.Programmer.captionFont_13
                
        //        case .novelist:  return Colors.Constants.white50Percent
                
            case .gothic:    return Fonts.Gothic.captionFont_14
                
        }
    }
    
    var effectsUnitCaptionFont_normal: NSFont {
        
        switch self {
                
            case .standard:  return Fonts.Standard.captionFont_16
                
            case .programmer:  return Fonts.Programmer.captionFont_15
                
        //        case .novelist:  return Colors.Constants.white50Percent
                
            case .gothic:    return Fonts.Gothic.captionFont_16
                
        }
    }
    
    var effectsMasterUnitFunctionFont_normal: NSFont {
        
        switch self {
                
            case .standard:  return Fonts.Standard.captionFont_13
                
            case .programmer:  return Fonts.Programmer.captionFont_11
                
        //        case .novelist:  return Colors.Constants.white50Percent
                
            case .gothic:    return Fonts.Gothic.captionFont_13
                
        }
    }
}
