/*
    Concrete implementation of PlayerProtocol
 */

import Cocoa
import AVFoundation

class Player: PlayerProtocol, AsyncMessageSubscriber {
    
    // The underlying audio graph used to perform playback
    private let graph: PlayerGraphProtocol
    private let playerNode: AVAudioPlayerNode
    
    // Helper used for actual scheduling and playback
    private let scheduler: PlaybackSchedulerProtocol
    
    var state: PlaybackState = .noTrack
    
    init(_ graph: PlayerGraphProtocol, _ scheduler: PlaybackSchedulerProtocol) {
        
        self.graph = graph
        self.playerNode = graph.playerNode
        self.scheduler = scheduler
        
        AsyncMessenger.subscribe([.audioOutputChanged], subscriber: self, dispatchQueue: DispatchQueue.main)
    }
    
    // Prepares the player to play a given track
    private func initPlayer(_ track: Track) {
        
        if let fileFormat = track.playbackInfo?.audioFile?.processingFormat {

            // Disconnect player and reconnect with the file's processing format
            graph.reconnectPlayerNodeWithFormat(fileFormat)
        }
    }
    
    func play(_ track: Track, _ startPosition: Double, _ endPosition: Double? = nil) {
        
        let session = PlaybackSession.start(track)
        
        initPlayer(track)
        
        if let end = endPosition {
            
            // Loop is defined
            PlaybackSession.defineLoop(startPosition, end)
            scheduler.playLoop(session, true)
            
        } else {
            
            scheduler.playTrack(session, startPosition)
        }
        
        state = .playing
    }
    
    func defineLoop(_ loopStartPosition: Double, _ loopEndPosition: Double) {
        
        if let currentSession = PlaybackSession.startNewSessionForPlayingTrack() {

            PlaybackSession.defineLoop(loopStartPosition, loopEndPosition)
            scheduler.playLoop(currentSession, seekPosition, state == .playing)
        }
    }
    
    func pause() {
        
        scheduler.pause()
        graph.clearSoundTails()
        
        state = .paused
    }
    
    func resume() {
        
        scheduler.resume()
        state = .playing
    }
    
    func stop() {
        
        _ = PlaybackSession.endCurrent()
        
        scheduler.stop()
        playerNode.reset()
        graph.clearSoundTails()
        
        state = .noTrack
    }
    
    func wait() {
        state = .waiting
    }
    
    func transcoding() {
        state = .transcoding
    }
    
    /*
        Attempts to seek to a given track position, checking the validity of the desired seek time. Returns an object encapsulating the result of the seek operation.
     
        - Parameter attemptedSeekTime: The desired seek time. May be invalid, i.e. < 0 or > track duration, or outside the bounds of a defined segment loop. If so, it will be adjusted accordingly.
     
        - Parameter canSeekOutsideLoop: If set to true, the seek may result in a segment loop being removed, if one was defined prior to the seek. Determines whether or not attemptedSeekTime can be outside the bounds of a segment loop.
     
        NOTE - If a seek reaches the end of a track, and the player is playing, track playback completion will be signaled.
     */
    private func doSeekToTime(_ track: Track, _ attemptedSeekTime: Double, _ canSeekOutsideLoop: Bool) -> PlayerSeekResult {
        
        if PlaybackSession.hasCurrentSession() {
            
            var actualSeekTime: Double = attemptedSeekTime
            var playbackCompleted: Bool
            var loopRemoved: Bool = false
            
            if let loop = self.playbackLoop, !loop.containsPosition(attemptedSeekTime) {
                
                if canSeekOutsideLoop {
                    
                    PlaybackSession.removeLoop()
                    loopRemoved = true
                    
                } else {
                    
                    // Correct the seek time
                    if attemptedSeekTime < loop.startTime {
                        actualSeekTime = loop.startTime
                        
                    } else if let loopEndTime = loop.endTime, attemptedSeekTime >= loopEndTime {
                        actualSeekTime = loop.startTime
                    }
                }
            }
            
            playbackCompleted = actualSeekTime >= track.duration && state == .playing
            actualSeekTime = max(0, min(actualSeekTime, track.duration))
            
            // Create a new identical session (for the track that is playing), and perform a seek within it
            if !playbackCompleted, let newSession = PlaybackSession.startNewSessionForPlayingTrack() {
                scheduler.seekToTime(newSession, actualSeekTime, state == .playing)
            }
            
            return PlayerSeekResult(actualSeekPosition: actualSeekTime, loopRemoved: loopRemoved, trackPlaybackCompleted: playbackCompleted)
        }
        
        // Impossible
        return PlayerSeekResult(actualSeekPosition: 0, loopRemoved: false, trackPlaybackCompleted: false)
    }
    
    // Attempts to perform a seek to a given seek position, respecting the bounds of a defined segment loop. See doSeekToTime() for more details.
    func attemptSeekToTime(_ track: Track, _ time: Double) -> PlayerSeekResult {
        return doSeekToTime(track, time, false)
    }
    
    // Forces a seek to a given seek position, not respecting the bounds of a defined segment loop. i.e. a previously defined segment loop
    // may be removed as a result of this forced seek. See doSeekToTime() for more details.
    func forceSeekToTime(_ track: Track, _ time: Double) -> PlayerSeekResult {
        return doSeekToTime(track, time, true)
    }
    
    var seekPosition: Double {
        return state.isNotPlayingOrPaused ? 0 : scheduler.seekPosition
    }
    
    var playingTrackStartTime: TimeInterval? {return PlaybackSession.currentSession?.timestamp}
    
    func toggleLoop() -> PlaybackLoop? {
        
        // Capture the current seek position
        let currentSeekPos = seekPosition

        // Make sure that there is a track currently playing.
        if PlaybackSession.hasCurrentSession() {
            
            if PlaybackSession.hasLoop() {
                
                // If loop is complete, remove it, otherwise mark its end time.
                PlaybackSession.hasCompleteLoop() ? removeLoop() : endLoop(currentSeekPos)
                
            } else {
                
                // No loop currently defined, mark its start time.
                beginLoop(currentSeekPos)
            }
        }
        
        return playbackLoop
    }
    
    private func beginLoop(_ seekPos: Double) {
        
        // Loop is currently undefined, mark its start time. No changes in playback ... playback continues as before.
        PlaybackSession.beginLoop(seekPos)
    }
    
    private func endLoop(_ seekPos: Double) {
        
        // Loop has a start time, but no end time ... mark its end time
        PlaybackSession.endLoop(seekPos)
        
        // When the loop's end time is defined, playback jumps to the loop's start time, and a new playback session is started.
        if let newSession = PlaybackSession.startNewSessionForPlayingTrack() {
            scheduler.playLoop(newSession, state == .playing)
        }
    }
    
    private func removeLoop() {
        
        // Loop has an end time (i.e. is complete) ... remove loop
        PlaybackSession.removeLoop()
        
        // When a loop is removed, playback continues from the current position and a new playback session is started.
        if let newSession = PlaybackSession.startNewSessionForPlayingTrack(), let loopEndTime = playbackLoop?.endTime {
            scheduler.endLoop(newSession, loopEndTime)
        }
    }
    
    var playbackLoop: PlaybackLoop? {
        return PlaybackSession.currentLoop
    }
    
    // MARK: Message handling
    
    var subscriberId: String {
        return "Player"
    }
    
    func consumeAsyncMessage(_ message: AsyncMessage) {
        
        // Handler for when the audio output changes (e.g. headphones plugged in/out).
        if message is AudioOutputChangedMessage {
            
            audioOutputDeviceChanged()
            return
        }
    }
    
    // When the audio output device changes, restart the audio engine and continue playback as before.
    private func audioOutputDeviceChanged() {
        
        // First, check if a track is playing.
        if let curSession = PlaybackSession.startNewSessionForPlayingTrack() {
            
            // Mark the current seek position
            let curSeekPos = seekPosition
            
            graph.restartAudioEngine()
            
            // Resume playback from the same seek position
            scheduler.seekToTime(curSession, curSeekPos, state == .playing)
            
        } else {
            
            // No track is playing, simply restart the audio engine.
            graph.restartAudioEngine()
        }
    }
    
    func tearDown() {
        stop()
    }
}

// Enumeration of all possible playback states of the player
enum PlaybackState {
    
    case playing
    case paused
    case noTrack
    case waiting
    case transcoding
    
    var isPlayingOrPaused: Bool {
        return self == .playing || self == .paused
    }
    
    var isNotPlayingOrPaused: Bool {
        return !isPlayingOrPaused
    }
}
