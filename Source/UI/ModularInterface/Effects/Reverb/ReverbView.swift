import Cocoa

class ReverbView: NSView {
    
    @IBOutlet weak var reverbSpaceMenu: NSPopUpButton!
    @IBOutlet weak var reverbAmountSlider: TickedCircularSlider!
    @IBOutlet weak var lblReverbAmountValue: NSTextField!
    
    var spaceString: String {
        return reverbSpaceMenu.titleOfSelectedItem!
    }
    
    var amount: Float {
        return reverbAmountSlider.floatValue
    }
    
    func initialize(_ stateFunction: (() -> EffectsUnitState)?) {
        
        reverbAmountSlider.stateFunction = stateFunction
        reverbAmountSlider.updateState()
    }
    
    func setState(_ space: String , _ amount: Float, _ amountString: String) {
        
        setSpace(space)
        setAmount(amount, amountString)
    }
    
    func setUnitState(_ state: EffectsUnitState) {
        reverbAmountSlider.unitState = state
    }
    
    func setSpace(_ space: String) {
        reverbSpaceMenu.selectItem(withTitle: space)
    }
    
    func setAmount(_ amount: Float, _ amountString: String) {
        
        reverbAmountSlider.setValue(amount)
        lblReverbAmountValue.stringValue = amountString
    }
    
    func stateChanged() {
        reverbAmountSlider.updateState()
    }
    
    func applyPreset(_ preset: ReverbPreset) {
        
        setUnitState(preset.state)
        setSpace(preset.space.description)
        setAmount(preset.amount, ValueFormatter.formatReverbAmount(preset.amount))
    }
    
    func changeTextSize() {
        
        reverbSpaceMenu.redraw()
        reverbSpaceMenu.font = Fonts.Effects.unitFunctionFont
    }
    
    func redrawSliders() {
        reverbAmountSlider.redraw()
    }
    
    func redrawMenu() {
        reverbSpaceMenu.redraw()
    }
}
