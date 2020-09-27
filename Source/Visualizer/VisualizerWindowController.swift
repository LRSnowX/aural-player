import Cocoa
import AVFoundation

class VisualizerWindowController: NSWindowController, AudioGraphRenderObserverProtocol, NSWindowDelegate {
    
    override var windowNibName: String? {return "Visualizer"}
    
    @IBOutlet weak var containerBox: VisualizerContainer!
    
    @IBOutlet weak var spectrogram: Spectrogram!
    @IBOutlet weak var supernova: Supernova!
    @IBOutlet weak var discoBall: DiscoBall!
    
    @IBOutlet weak var typeMenu: NSMenu!
    @IBOutlet weak var spectrogramMenuItem: NSMenuItem!
    @IBOutlet weak var supernovaMenuItem: NSMenuItem!
    @IBOutlet weak var discoBallMenuItem: NSMenuItem!

    @IBOutlet weak var optionsBox: NSBox!
    
    @IBOutlet weak var startColorPicker: NSColorWell!
    @IBOutlet weak var endColorPicker: NSColorWell!
    
    @IBOutlet weak var lblBands: NSTextField!
    @IBOutlet weak var bandsMenu: NSPopUpButton!
    
    var vizView: VisualizerViewProtocol!
    private let fft = FFT.instance
    private var audioGraph: AudioGraphDelegateProtocol = ObjectGraph.audioGraphDelegate
    
    override func awakeFromNib() {
        
        window?.aspectRatio = NSSize(width: 1, height: 2.0/3.0)
        
        [spectrogram, supernova, discoBall].forEach {$0?.anchorToView(containerBox)}
        
//        FrequencyData.numBands = 27
//        spectrogram.numberOfBands = 27
        
        spectrogramMenuItem.representedObject = VisualizationType.spectrogram
        supernovaMenuItem.representedObject = VisualizationType.supernova
        discoBallMenuItem.representedObject = VisualizationType.discoBall
        
        NotificationCenter.default.addObserver(forName: Notification.Name("showOptions"), object: nil, queue: nil, using: {_ in
            
            if let theVizView = self.vizView, theVizView.type == .spectrogram {
                NSView.showViews(self.lblBands, self.bandsMenu)
                
            } else {
                NSView.hideViews(self.lblBands, self.bandsMenu)
            }
            
            self.optionsBox.show()
        })
        
        NotificationCenter.default.addObserver(forName: Notification.Name("hideOptions"), object: nil, queue: nil, using: {_ in
            self.optionsBox.hide()
        })
    }
    
    override func showWindow(_ sender: Any?) {
        
        super.showWindow(sender)
        
        audioGraph.outputDeviceBufferSize = 2048
        fft.setUp(sampleRate: Float(audioGraph.outputDeviceSampleRate), bufferSize: audioGraph.outputDeviceBufferSize)
     
        audioGraph.registerRenderObserver(self)
        containerBox.startTracking()
        
        changeType(.spectrogram)
    }
    
    func windowWillClose(_ notification: Notification) {
        
        audioGraph.removeRenderObserver(self)
        containerBox.stopTracking()
    }
    
    func rendered(timeStamp: AudioTimeStamp, frameCount: UInt32, audioBuffer: AudioBufferList) {
        
        fft.analyze(audioBuffer)
        
        //        if FrequencyData.numBands != 10 {
        //            NSLog("Bands: \(FrequencyData.bands.map {$0.maxVal})")
        //        }
        
        if let theVizView = vizView {
            
            DispatchQueue.main.async {
                theVizView.update()
            }
        }
    }
    
    func deviceChanged(newDeviceBufferSize: Int, newDeviceSampleRate: Double) {
        
    }
    
    func deviceSampleRateChanged(newSampleRate: Double) {
        
    }
    
    @IBAction func changeTypeAction(_ sender: NSPopUpButton) {
        
        if let vizType = sender.selectedItem?.representedObject as? VisualizationType {
            changeType(vizType)
        }
    }
    
    func changeType(_ type: VisualizationType) {
        
        if let theVizView = vizView, theVizView.type == type {return}
        
        switch type {
            
        case .spectrogram:
            
            vizView = spectrogram
            
            supernova.dismissView()
            discoBall.dismissView()
            
        case .supernova:
            
            vizView = supernova
            
            spectrogram.dismissView()
            discoBall.dismissView()
            
        case .discoBall:
            
            vizView = discoBall
            
            spectrogram.dismissView()
            supernova.dismissView()
        }
        
        vizView.presentView()
    }
    
    @IBAction func changeNumberOfBandsAction(_ sender: NSPopUpButton) {
        
        let numBands = sender.selectedTag()
        
        if numBands > 0 {
            
            FrequencyData.numBands = numBands
            spectrogram.numberOfBands = numBands
        }
    }
    
    @IBAction func setColorsAction(_ sender: NSColorWell) {
        
        vizView.setColors(startColor: self.startColorPicker.color, endColor: self.endColorPicker.color)
        
        [spectrogram, supernova, discoBall].forEach {
            
            if $0 !== (vizView as! NSView) {
                ($0 as? VisualizerViewProtocol)?.setColors(startColor: self.startColorPicker.color, endColor: self.endColorPicker.color)
            }
        }
    }
}

enum VisualizationType {
    
    case spectrogram, supernova, discoBall
}

class VisualizerContainer: NSBox {
    
    override func viewDidEndLiveResize() {
        
        super.viewDidEndLiveResize()
        
        self.removeAllTrackingAreas()
        self.updateTrackingAreas()
        
        NotificationCenter.default.post(name: Notification.Name("hideOptions"), object: nil)
    }
    
    // Signals the view to start tracking mouse movements.
    func startTracking() {
        
        self.removeAllTrackingAreas()
        self.updateTrackingAreas()
    }
    
    // Signals the view to stop tracking mouse movements.
    func stopTracking() {
        self.removeAllTrackingAreas()
    }
    
    override func updateTrackingAreas() {
        
        // Create a tracking area that covers the bounds of the view. It should respond whenever the mouse enters or exits.
        addTrackingArea(NSTrackingArea(rect: self.bounds, options: [NSTrackingArea.Options.activeAlways, NSTrackingArea.Options.mouseEnteredAndExited], owner: self, userInfo: nil))
        
        super.updateTrackingAreas()
    }
    
    override func mouseEntered(with event: NSEvent) {
        NotificationCenter.default.post(name: Notification.Name("showOptions"), object: nil)
    }
    
    override func mouseExited(with event: NSEvent) {
        NotificationCenter.default.post(name: Notification.Name("hideOptions"), object: nil)
    }
}
