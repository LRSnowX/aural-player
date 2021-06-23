import AVFoundation

/*
    Wrapper around AVAudioEngine. Manages the AVAudioEngine audio graph.
 */
class AudioGraph: AudioGraphProtocol, NotificationSubscriber, PersistentModelObject {
    
    private let audioEngine: AudioEngine
    
    let outputNode: AVAudioOutputNode
    let playerNode: AuralPlayerNode
    let nodeForRecorderTap: AVAudioNode
    let auxMixer: AVAudioMixerNode  // Used for conversions of sample rates / channel counts
    
    private let audioUnitsManager: AudioUnitsManager
    private let deviceManager: DeviceManager
    
    // FX units
    var masterUnit: MasterUnit
    var eqUnit: EQUnit
    var pitchUnit: PitchUnit
    var timeUnit: TimeUnit
    var reverbUnit: ReverbUnit
    var delayUnit: DelayUnit
    var filterUnit: FilterUnit
    var audioUnits: [HostedAudioUnit]
    
    var soundProfiles: SoundProfiles
    
    // Sets up the audio engine
    init(_ audioUnitsManager: AudioUnitsManager, _ persistentState: AudioGraphPersistentState?) {
        
        audioEngine = AudioEngine()
        
        let volume = persistentState?.volume ?? AudioGraphDefaults.volume
        let pan = persistentState?.balance ?? AudioGraphDefaults.balance
        
        // If running on 10.12 Sierra or older, use the legacy AVAudioPlayerNode APIs
        if #available(OSX 10.13, *) {
            playerNode = AuralPlayerNode(useLegacyAPI: false, volume: volume, pan: pan)
        } else {
            playerNode = AuralPlayerNode(useLegacyAPI: true, volume: volume, pan: pan)
        }
        
        muted = persistentState?.muted ?? AudioGraphDefaults.muted
        auxMixer = AVAudioMixerNode(volume: muted ? 0 : 1)
        
        outputNode = audioEngine.outputNode
        nodeForRecorderTap = audioEngine.mainMixerNode
        
        deviceManager = DeviceManager(outputAudioUnit: outputNode.audioUnit!)
        
        eqUnit = EQUnit(persistentState: persistentState?.eqUnit)
        pitchUnit = PitchUnit(persistentState: persistentState?.pitchUnit)
        timeUnit = TimeUnit(persistentState: persistentState?.timeUnit)
        reverbUnit = ReverbUnit(persistentState: persistentState?.reverbUnit)
        delayUnit = DelayUnit(persistentState: persistentState?.delayUnit)
        filterUnit = FilterUnit(persistentState: persistentState?.filterUnit)
        
        self.audioUnitsManager = audioUnitsManager
        audioUnits = []
        for auState in persistentState?.audioUnits ?? [] {
            
            if let component = audioUnitsManager.component(ofType: auState.componentType, andSubType: auState.componentSubType) {
                audioUnits.append(HostedAudioUnit(forComponent: component, persistentState: auState))
            }
        }
        
        let nativeSlaveUnits = [eqUnit, pitchUnit, timeUnit, reverbUnit, delayUnit, filterUnit]
        masterUnit = MasterUnit(persistentState: persistentState?.masterUnit, nativeSlaveUnits: nativeSlaveUnits, audioUnits: audioUnits)

        let permanentNodes = [playerNode, auxMixer] + (nativeSlaveUnits.flatMap {$0.avNodes})
        let removableNodes = audioUnits.flatMap {$0.avNodes}
        audioEngine.connectNodes(permanentNodes: permanentNodes, removableNodes: removableNodes)
        
        soundProfiles = SoundProfiles(persistentState?.soundProfiles ?? [])
        
        // Register self as an observer for notifications when the audio output device has changed (e.g. headphones)
        Messenger.subscribe(self, .AVAudioEngineConfigurationChange, self.outputDeviceChanged)
        
        deviceManager.maxFramesPerSlice = visualizationAnalysisBufferSize
        audioEngine.start()
    }
    
    // MARK: Audio engine functions ----------------------------------
    
    func reconnectPlayerNodeWithFormat(_ format: AVAudioFormat) {
        audioEngine.reconnectNodes(playerNode, outputNode: auxMixer, format: format)
    }
    
    func clearSoundTails() {
        
        // Clear sound tails from reverb and delay nodes, if they're active
        if delayUnit.isActive {delayUnit.reset()}
        if reverbUnit.isActive {reverbUnit.reset()}
    }
    
    func restartAudioEngine() {
        audioEngine.restart()
    }
    
    func tearDown() {
        
        // Release the audio engine resources
        audioEngine.stop()
    }
    
    // MARK: Player node properties ----------------------------------
    
    var volume: Float {
        
        get {playerNode.volume}
        set {playerNode.volume = newValue}
    }
    
    var balance: Float {
        
        get {playerNode.pan}
        set {playerNode.pan = newValue}
    }
    
    var muted: Bool {
        didSet {auxMixer.volume = muted ? 0 : 1}
    }
    
    // MARK: Device management ----------------------------------
    
    var availableDevices: AudioDeviceList {deviceManager.allDevices}
    
    var systemDevice: AudioDevice {deviceManager.systemDevice}
    
    var outputDevice: AudioDevice {
        
        get {deviceManager.outputDevice}
        set(newDevice) {deviceManager.outputDevice = newDevice}
    }
    
    var outputDeviceSampleRate: Double {deviceManager.outputDeviceSampleRate}
    
    var outputDeviceBufferSize: Int {
        
        get {deviceManager.outputDeviceBufferSize}
        set {deviceManager.outputDeviceBufferSize = newValue}
    }
    
    func outputDeviceChanged() {
        
        deviceManager.maxFramesPerSlice = visualizationAnalysisBufferSize
        audioEngine.start()
        
        // Send out a notification
        Messenger.publish(.audioGraph_outputDeviceChanged)
    }
    
    // MARK: Audio Units management ----------------------------------
    
    func addAudioUnit(ofType type: OSType, andSubType subType: OSType) -> (audioUnit: HostedAudioUnit, index: Int)? {
        
        if let auComponent = audioUnitsManager.component(ofType: type, andSubType: subType) {
            
            let newUnit: HostedAudioUnit = HostedAudioUnit(forComponent: auComponent)
            audioUnits.append(newUnit)
            masterUnit.addAudioUnit(newUnit)
            
            let context = AudioGraphChangeContext()
            Messenger.publish(PreAudioGraphChangeNotification(context: context))
            audioEngine.insertNode(newUnit.avNodes[0])
            Messenger.publish(AudioGraphChangedNotification(context: context))
            
            return (audioUnit: newUnit, index: audioUnits.lastIndex)
        }
        
        return nil
    }
    
    func removeAudioUnits(at indices: IndexSet) {
        
        let descendingIndices = indices.filter {$0 < audioUnits.count}.sorted(by: Int.descendingIntComparator)
        
        for index in descendingIndices {
            audioUnits.remove(at: index)
        }
        
        masterUnit.removeAudioUnits(descendingIndices)
        
        let context = AudioGraphChangeContext()
        Messenger.publish(PreAudioGraphChangeNotification(context: context))
        audioEngine.removeNodes(descendingIndices)
        Messenger.publish(AudioGraphChangedNotification(context: context))
    }
    
    // MARK: Miscellaneous properties / functions ------------------------
    
    var settingsAsMasterPreset: MasterPreset {masterUnit.settingsAsPreset}

    var persistentState: AudioGraphPersistentState {
        
        let state: AudioGraphPersistentState = AudioGraphPersistentState()
        
        let outputDevice = self.outputDevice
        state.outputDevice = AudioDevicePersistentState(name: outputDevice.name, uid: outputDevice.uid)
        
        // Volume and pan (balance)
        state.volume = playerNode.volume
        state.muted = muted
        state.balance = playerNode.pan
        
        state.masterUnit = masterUnit.persistentState
        state.eqUnit = eqUnit.persistentState
        state.pitchUnit = pitchUnit.persistentState
        state.timeUnit = timeUnit.persistentState
        state.reverbUnit = reverbUnit.persistentState
        state.delayUnit = delayUnit.persistentState
        state.filterUnit = filterUnit.persistentState
        state.audioUnits = audioUnits.map {$0.persistentState}
        
        state.soundProfiles = self.soundProfiles.all().map {SoundProfilePersistentState(file: $0.file, volume: $0.volume, balance: $0.balance, effects: MasterPresetPersistentState(preset: $0.effects))}
        
        return state
    }
}

enum EffectsUnitState: String {
    
    // Master unit on, and effects unit on
    case active
    
    // Effects unit off
    case bypassed
    
    // Master unit off, and effects unit on
    case suppressed
}

struct AudioGraphDefaults {
    
    static let volume: Float = 0.5
    static let balance: Float = 0
    static let muted: Bool = false
    
    static let masterState: EffectsUnitState = .active
    
    static let eqState: EffectsUnitState = .bypassed
    static let eqType: EQType = .tenBand
    static let eqGlobalGain: Float = 0
    static let eqBands: [Float] = Array(repeating: Float(0), count: 10)
    static let eqBandGain: Float = 0
    
    static let pitchState: EffectsUnitState = .bypassed
    static let pitch: Float = 0
    static let pitchOverlap: Float = 8
    
    static let timeState: EffectsUnitState = .bypassed
    static let timeStretchRate: Float = 1
    static let timeShiftPitch: Bool = false
    static let timeOverlap: Float = 8
    
    static let reverbState: EffectsUnitState = .bypassed
    static let reverbSpace: ReverbSpaces = .mediumHall
    static let reverbAmount: Float = 50
    
    static let delayState: EffectsUnitState = .bypassed
    static let delayAmount: Float = 100
    static let delayTime: Double = 1
    static let delayFeedback: Float = 50
    static let delayLowPassCutoff: Float = 15000

    static let filterState: EffectsUnitState = .bypassed
    static let filterBandType: FilterBandType = .bandStop
    static let filterBandMinFreq: Float = AppConstants.Sound.audibleRangeMin
    static let filterBandMaxFreq: Float = AppConstants.Sound.subBass_max
    
    static let auState: EffectsUnitState = .active
}
