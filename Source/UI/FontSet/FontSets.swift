import Cocoa

class FontSets {
    
    // Default color scheme (uses colors from the default system-defined preset)
    static let defaultFontSet: FontSet = FontSet("_default_", FontSetPreset.programmer)
    
    // The current system color scheme. It is initialized with the default scheme.
    static var systemFontSet: FontSet = defaultFontSet
}
