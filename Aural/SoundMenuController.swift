import Cocoa

/*
    Provides actions for the Sound menu that alter the sound output.
 
    NOTE - No actions are directly handled by this class. Action messages are published to another app component that is responsible for these functions.
 */
class SoundMenuController: NSObject {
    
    // Menu items that hold specific associated values
    
    // Pitch shift menu items (with specific pitch shift values)
    @IBOutlet weak var twoOctavesBelowMenuItem: SoundParameterMenuItem!
    @IBOutlet weak var oneOctaveBelowMenuItem: SoundParameterMenuItem!
    @IBOutlet weak var halfOctaveBelowMenuItem: SoundParameterMenuItem!
    @IBOutlet weak var thirdOctaveBelowMenuItem: SoundParameterMenuItem!
    @IBOutlet weak var sixthOctaveBelowMenuItem: SoundParameterMenuItem!
    
    @IBOutlet weak var sixthOctaveAboveMenuItem: SoundParameterMenuItem!
    @IBOutlet weak var thirdOctaveAboveMenuItem: SoundParameterMenuItem!
    @IBOutlet weak var halfOctaveAboveMenuItem: SoundParameterMenuItem!
    @IBOutlet weak var oneOctaveAboveMenuItem: SoundParameterMenuItem!
    @IBOutlet weak var twoOctavesAboveMenuItem: SoundParameterMenuItem!
    
    // Playback rate (Time) menu items (with specific playback rate values)
    @IBOutlet weak var rate0_25MenuItem: SoundParameterMenuItem!
    @IBOutlet weak var rate0_5MenuItem: SoundParameterMenuItem!
    @IBOutlet weak var rate0_75MenuItem: SoundParameterMenuItem!
    @IBOutlet weak var rate1_25MenuItem: SoundParameterMenuItem!
    @IBOutlet weak var rate1_5MenuItem: SoundParameterMenuItem!
    @IBOutlet weak var rate2MenuItem: SoundParameterMenuItem!
    @IBOutlet weak var rate3MenuItem: SoundParameterMenuItem!
    @IBOutlet weak var rate4MenuItem: SoundParameterMenuItem!
    
    // One-time setup.
    override func awakeFromNib() {
        
        // Associate each of the menu items with a specific pitch shift or playback rate value, so that when the item is clicked later, that value can be readily retrieved and used in performing the action.
        
        // Pitch shift menu items
        twoOctavesBelowMenuItem.paramValue = -2
        oneOctaveBelowMenuItem.paramValue = -1
        halfOctaveBelowMenuItem.paramValue = -0.5
        thirdOctaveBelowMenuItem.paramValue = -1/3
        sixthOctaveBelowMenuItem.paramValue = -1/6
        
        sixthOctaveAboveMenuItem.paramValue = 1/6
        thirdOctaveAboveMenuItem.paramValue = 1/3
        halfOctaveAboveMenuItem.paramValue = 0.5
        oneOctaveAboveMenuItem.paramValue = 1
        twoOctavesAboveMenuItem.paramValue = 2
        
        // Playback rate (Time) menu items
        rate0_25MenuItem.paramValue = 0.25
        rate0_5MenuItem.paramValue = 0.5
        rate0_75MenuItem.paramValue = 0.75
        rate1_25MenuItem.paramValue = 1.25
        rate1_5MenuItem.paramValue = 1.5
        rate2MenuItem.paramValue = 2
        rate3MenuItem.paramValue = 3
        rate4MenuItem.paramValue = 4
    }
    
    // Mutes or unmutes the player
    @IBAction func muteOrUnmuteAction(_ sender: AnyObject) {
        SyncMessenger.publishActionMessage(AudioGraphActionMessage(.muteOrUnmute))
    }
    
    // Decreases the volume by a certain preset decrement
    @IBAction func decreaseVolumeAction(_ sender: Any) {
        SyncMessenger.publishActionMessage(AudioGraphActionMessage(.decreaseVolume))
    }
    
    // Increases the volume by a certain preset increment
    @IBAction func increaseVolumeAction(_ sender: Any) {
        SyncMessenger.publishActionMessage(AudioGraphActionMessage(.increaseVolume))
    }
    
    // Pans the sound towards the left channel, by a certain preset value
    @IBAction func panLeftAction(_ sender: Any) {
        SyncMessenger.publishActionMessage(AudioGraphActionMessage(.panLeft))
    }
    
    // Pans the sound towards the right channel, by a certain preset value
    @IBAction func panRightAction(_ sender: Any) {
        SyncMessenger.publishActionMessage(AudioGraphActionMessage(.panRight))
    }
    
    // Decreases each of the EQ bass bands by a certain preset decrement
    @IBAction func decreaseBassAction(_ sender: Any) {
        SyncMessenger.publishActionMessage(AudioGraphActionMessage(.decreaseBass))
    }
    
    // Provides a "bass boost". Increases each of the EQ bass bands by a certain preset increment.
    @IBAction func increaseBassAction(_ sender: Any) {
        SyncMessenger.publishActionMessage(AudioGraphActionMessage(.increaseBass))
    }
    
    // Decreases each of the EQ mid-frequency bands by a certain preset decrement
    @IBAction func decreaseMidsAction(_ sender: Any) {
        SyncMessenger.publishActionMessage(AudioGraphActionMessage(.decreaseMids))
    }
    
    // Increases each of the EQ mid-frequency bands by a certain preset increment
    @IBAction func increaseMidsAction(_ sender: Any) {
        SyncMessenger.publishActionMessage(AudioGraphActionMessage(.increaseMids))
    }
    
    // Decreases each of the EQ treble bands by a certain preset decrement
    @IBAction func decreaseTrebleAction(_ sender: Any) {
        SyncMessenger.publishActionMessage(AudioGraphActionMessage(.decreaseTreble))
    }
    
    // Decreases each of the EQ treble bands by a certain preset increment
    @IBAction func increaseTrebleAction(_ sender: Any) {
        SyncMessenger.publishActionMessage(AudioGraphActionMessage(.increaseTreble))
    }
    
    // Decreases the pitch by a certain preset decrement
    @IBAction func decreasePitchAction(_ sender: Any) {
        SyncMessenger.publishActionMessage(AudioGraphActionMessage(.decreasePitch))
    }
    
    // Increases the pitch by a certain preset increment
    @IBAction func increasePitchAction(_ sender: Any) {
        SyncMessenger.publishActionMessage(AudioGraphActionMessage(.increasePitch))
    }
    
    // Sets the pitch to a value specified by the menu item clicked
    @IBAction func setPitchAction(_ sender: SoundParameterMenuItem) {
        
        // Menu item's "paramValue" specifies the pitch shift value associated with the menu item (in octaves)
        SyncMessenger.publishActionMessage(AudioGraphActionMessage(.setPitch, sender.paramValue))
    }
    
    // Decreases the playback rate by a certain preset decrement
    @IBAction func decreaseRateAction(_ sender: Any) {
        SyncMessenger.publishActionMessage(AudioGraphActionMessage(.decreaseRate))
    }
    
    // Increases the playback rate by a certain preset increment
    @IBAction func increaseRateAction(_ sender: Any) {
        SyncMessenger.publishActionMessage(AudioGraphActionMessage(.increaseRate))
    }
    
    // Sets the playback rate to a value specified by the menu item clicked
    @IBAction func setRateAction(_ sender: SoundParameterMenuItem) {
        
        // Menu item's "paramValue" specifies the playback rate value associated with the menu item
        SyncMessenger.publishActionMessage(AudioGraphActionMessage(.setRate, sender.paramValue))
    }
}

// An NSMenuItem subclass that contains extra fields to hold information (similar to tags) associated with the menu item
class SoundParameterMenuItem: NSMenuItem {
    
    // A generic numerical parameter value
    var paramValue: Float = 0
}
