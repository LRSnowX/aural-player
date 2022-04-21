//
//  CompactPlayQueueViewController+ContextMenuController.swift
//  Aural
//
//  Copyright © 2021 Kartik Venugopal. All rights reserved.
//
//  This software is licensed under the MIT software license.
//  See the file "LICENSE" in the project root directory for license terms.
//  

import Cocoa

extension CompactPlayQueueViewController: NSMenuDelegate {
    
    func menuNeedsUpdate(_ menu: NSMenu) {
        
        let oneRowSelected = selectedRowCount == 1
        
        [playNowMenuItem, favoritesMenuItem, infoMenuItem].forEach {
            $0.enableIf(oneRowSelected)
        }
        
        playNextMenuItem.enableIf(oneRowSelected && playQueueDelegate.currentTrack != nil)
        
        // TODO: playlist names menu should have a separate delegate so that the menu
        // is not unnecessarily updated until required.
        
        playlistNamesMenu.items.removeAll()
        
        for playlist in playlistsManager.userDefinedObjects {
            playlistNamesMenu.addItem(withTitle: playlist.name, action: #selector(copyTracksToPlaylistAction(_:)), keyEquivalent: "")
        }
    }
    
    @IBAction func playNextAction(_ sender: NSMenuItem) {
        
        guard let selectedTrackIndex = selectedRows.first,
              let indexOfPlayingTrack = playQueueDelegate.currentTrackIndex else {return}
        
        let destRow = indexOfPlayingTrack + 1
        
        // No need to do anything if the selected track is already the next
        // track in the play queue.
        guard selectedTrackIndex != destRow else {return}
        
        playQueueDelegate.moveTracks(from: IndexSet([selectedTrackIndex]), to: destRow)
        
        let minRow = min(selectedTrackIndex, destRow)
        let maxRow = max(selectedTrackIndex, destRow)
        tableView.reloadRows(minRow...maxRow)
        
        // Re-select the track that was moved.
        tableView.selectRow(destRow)
    }
    
    @IBAction func copyTracksToPlaylistAction(_ sender: NSMenuItem) {
        messenger.publish(CopyTracksToPlaylistCommand(tracks: selectedTracks, destinationPlaylistName: sender.title))
    }
}

//class PlaylistNamesMenuDelegate: NSObject, NSMenuDelegate {
//
//    func menuNeedsUpdate(_ menu: NSMenu) {
//
//
//    }
//}
