import Cocoa

class Favorite: StringKeyedItem, PlayableItem {
    
    // The file of the track being favorited
    let file: URL
    
    private var _name: String
    
    // Used by the UI (track.conciseDisplayName)
    var name: String {
        
        get {
            
            if let track = self.track {
                return track.conciseDisplayName
            }
            
            return _name
        }
        
        set(newValue) {
            _name = newValue
        }
    }
    
    var key: String {
        
        get {
            return file.path
        }
        
        set {
            // Do nothing
        }
    }
    
    var track: Track?
    
    init(_ track: Track) {
        
        self.track = track
        self.file = track.file
        self._name = track.conciseDisplayName
    }
    
    init(_ file: URL, _ name: String) {
        
        self.file = file
        self._name = name
    }
    
    func validateFile() -> Bool {
        return FileSystemUtils.fileExists(file)
    }
}
