import Cocoa

class RecorderToggleButton: OnOffImageButton {
    
    override func off() {
        
        self.image = offStateImage
        self.toolTip = offStateTooltip
        _isOn = false
    }
    
    // Sets the button state to be "On"
    override func on() {
        
        self.image = onStateImage
        self.toolTip = onStateTooltip
        _isOn = true
    }
    
    override func reTint() {
        // Do nothing
    }
}

/*
    An image button that can be toggled On/Off and displays different images depending on its state
 */
@IBDesignable
class OnOffImageButton: NSButton, Tintable {
    
    // The image displayed when the button is in an "Off" state
    @IBInspectable var offStateImage: NSImage? {
        
        didSet {
            
            if !_isOn {
                reTint()
            }
        }
    }
    
    // The image displayed when the button is in an "On" state
    @IBInspectable var onStateImage: NSImage? {
        
        didSet {
            
            if _isOn {
                reTint()
            }
        }
    }
    
    // The button's tooltip when the button is in an "Off" state
    @IBInspectable var offStateTooltip: String?
    
    // The button's tooltip when the button is in an "On" state
    @IBInspectable var onStateTooltip: String?
    
    var offStateTintFunction: () -> NSColor = {return Colors.toggleButtonOffStateColor} {
        
        didSet {
            
            if !_isOn {
                reTint()
            }
        }
    }
    
    var onStateTintFunction: () -> NSColor = {return Colors.functionButtonColor} {
        
        didSet {
            
            if _isOn {
                reTint()
            }
        }
    }
    
    fileprivate var _isOn: Bool = false
    
    // Sets the button state to be "Off"
    override func off() {
        
        self.image = offStateImage?.applyingTint(offStateTintFunction())
        self.toolTip = offStateTooltip
        _isOn = false
    }
    
    // Sets the button state to be "On"
    override func on() {
        
        self.image = onStateImage?.applyingTint(onStateTintFunction())
        self.toolTip = onStateTooltip
        _isOn = true
    }
    
    // Convenience function to set the button to "On" if the specified condition is true, and "Off" if not.
    override func onIf(_ condition: Bool) {
        condition ? on() : off()
    }
    
    // Toggles the On/Off state
    override func toggle() {
        _isOn ? off() : on()
    }
    
    // Returns true if the button is in the On state, false otherwise.
    override var isOn: Bool {
        return _isOn
    }
    
    func reTint() {
        
        if _isOn {
            self.image = onStateImage?.applyingTint(onStateTintFunction())
        } else {
            self.image = offStateImage?.applyingTint(offStateTintFunction())
        }
    }
}

/*
    A special case On/Off image button used as a bypass switch for Effects units, with preset images
 */
class EffectsUnitBypassButton: OnOffImageButton {
    
    override var offStateImage: NSImage? {
        
        get {
            return Images.imgSwitchOff
        }
        
        // Image should never change, so don't allow a setter
        set {}
    }
    
    override var onStateImage: NSImage? {
        
        get {
            return Images.imgSwitchOn
        }
        
        // Image should never change, so don't allow a setter
        set {}
    }
    
    override var offStateTooltip: String? {
        
        get {
            return "Activate this effects unit"
        }
        
        // Tool tip should never change, so don't allow a setter
        set {}
    }
    
    // The button's tooltip when the button is in an "On" state
    override var onStateTooltip: String? {
        
        get {
            return "Deactivate this effects unit"
        }
        
        // Tool tip should never change, so don't allow a setter
        set {}
    }
    
    override func awakeFromNib() {
        
        // Override the tint functions from OnOffImageButton
        offStateTintFunction = {return Colors.Effects.bypassedUnitStateColor}
        onStateTintFunction = {return Colors.Effects.activeUnitStateColor}
    }
    
    // Bypass is the inverse of "On". If bypass is true, state is "Off".
    func setBypassState(_ bypass: Bool) {
        bypass ? off() : on()
    }
}

/*
 A special case On/Off image button used as a bypass switch for Effects units, with preset images
 */
class EffectsUnitTriStateBypassButton: EffectsUnitBypassButton {
    
    var stateFunction: (() -> EffectsUnitState)?
    
    var unitState: EffectsUnitState {
        return stateFunction?() ?? .bypassed
    }
    
    var mixedStateImage: NSImage? {
        
        get {
            return Images.imgSwitchMixed
        }
        
        // Image should never change, so don't allow a setter
        set {}
    }
    
    var mixedStateTooltip: String? {
        
        get {
            return offStateTooltip
        }
        
        // Tool tip should never change, so don't allow a setter
        set {}
    }
    
    var mixedStateTintFunction: () -> NSColor = {return Colors.Effects.suppressedUnitStateColor} {
        
        didSet {
            
            if unitState == .suppressed {
                reTint()
            }
        }
    }
    
    func updateState() {
        
        switch unitState {
            
        case .bypassed: off()
            
        case .active: on()
            
        case .suppressed: mixed()
            
        }
    }
    
    func setUnitState(_ state: EffectsUnitState) {
        
        switch state {
            
        case .bypassed: off()
            
        case .active: on()
            
        case .suppressed: mixed()
            
        }
    }
    
    func mixed() {
        
        self.toolTip = mixedStateTooltip
        self.image = mixedStateImage?.applyingTint(mixedStateTintFunction())
    }
    
    override func reTint() {
        updateState()
    }
}

@IBDesignable
class EffectsUnitTabButton: OnOffImageButton {
    
    var stateFunction: (() -> EffectsUnitState)?
    
    @IBInspectable var mixedStateImage: NSImage?
    @IBInspectable var mixedStateTooltip: String?
    
    var mixedStateTintFunction: () -> NSColor = {return Colors.Effects.suppressedUnitStateColor} {
        
        didSet {
            reTint()
        }
    }
    
    override func awakeFromNib() {
        
        // Override the tint functions from OnOffImageButton
        offStateTintFunction = {return Colors.Effects.bypassedUnitStateColor}
        onStateTintFunction = {return Colors.Effects.activeUnitStateColor}
    }
    
    override func off() {
        
        super.off()
        
        if let cell = self.cell as? EffectsUnitTabButtonCell {
            cell.unitState = .bypassed
            redraw()
        }
    }
    
    override func on() {
        
        super.on()
        
        if let cell = self.cell as? EffectsUnitTabButtonCell {
            cell.unitState = .active
            redraw()
        }
    }
    
    func mixed() {
        
        self.image = mixedStateImage?.applyingTint(mixedStateTintFunction())
        self.toolTip = mixedStateTooltip
        
        if let cell = self.cell as? EffectsUnitTabButtonCell {
            cell.unitState = .suppressed
            redraw()
        }
    }
    
    override func reTint() {
        
        switch unitState {
            
        case .bypassed: self.image = offStateImage?.applyingTint(offStateTintFunction())
            
        case .active: self.image = onStateImage?.applyingTint(onStateTintFunction())
            
        case .suppressed: self.image = mixedStateImage?.applyingTint(mixedStateTintFunction())
            
        }
        
        // Need to redraw because we are using a custom button cell which needs to render the updated image itself
        redraw()
    }
    
    func updateState() {
        
        let newState = stateFunction!()
        
        switch newState {
            
        case .bypassed: off()
            
        case .active: on()
            
        case .suppressed: mixed()
            
        }
    }
    
    var unitState: EffectsUnitState {
        return stateFunction?() ?? .bypassed
    }
}

class EffectsUnitTriStateBypassPreviewButton: EffectsUnitTriStateBypassButton {
    
    override func awakeFromNib() {
        
        offStateTintFunction = {return Colors.Effects.defaultBypassedUnitColor}
        onStateTintFunction = {return Colors.Effects.defaultActiveUnitColor}
        mixedStateTintFunction = {return Colors.Effects.defaultSuppressedUnitColor}
    }
}
