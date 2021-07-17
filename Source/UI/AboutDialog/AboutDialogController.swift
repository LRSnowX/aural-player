//
//  AboutDialogController.swift
//  Aural
//
//  Copyright © 2021 Kartik Venugopal. All rights reserved.
//
//  This software is licensed under the MIT software license.
//  See the file "LICENSE" in the project root directory for license terms.
//
import Cocoa

class AboutDialogController: NSWindowController, ModalComponentProtocol {
    
    override var windowNibName: String? {"AboutDialog"}
    
    private lazy var messenger = Messenger(for: self)
    
    @IBOutlet weak var versionLabel: NSTextField! {
        
        didSet {
            versionLabel.stringValue = NSApp.appVersion
        }
    }
    
    override func showWindow(_ sender: Any?) {

        forceLoadingOfWindow()
        messenger.publish(.windowManager_showWindowCenteredOverMainWindow, payload: theWindow)
    }
    
    override func windowDidLoad() {
        objectGraph.windowLayoutState.registerModalComponent(self)
    }
    
    var isModal: Bool {self.window?.isVisible ?? false}
}
