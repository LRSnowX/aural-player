import Cocoa

/*
    Handles trackpad/MagicMouse gestures performed over the main window, for convenient access to essential player functions
 */
class GestureHandler {
    
    // Retrieves current playing track info
    private let playbackInfo: PlaybackInfoDelegateProtocol = ObjectGraph.getPlaybackInfoDelegate()
    
    private let preferences: ControlsPreferences = ObjectGraph.getPreferencesDelegate().getPreferences().controlsPreferences
    
    // Handles a single event
    func handle(_ event: NSEvent) {
        
        // If a modal dialog is open, don't do anything
        // Also, ignore any gestures that weren't triggered over the main window (they trigger other functions if performed over the playlist window)
        if (NSApp.modalWindow != nil || event.window != WindowState.window) {
            return
        }
        
        // Delegate to an appropriate handler function based on event type
        switch event.type {
            
        case .swipe: handleSwipe(event)
            
        case .scrollWheel: handleScroll(event)
            
        default: return
            
        }
    }
    
    // Handles a single swipe event
    private func handleSwipe(_ event: NSEvent) {
        
        if let swipeDirection = UIUtils.determineSwipeDirection(event) {
            
            if swipeDirection.isHorizontal() {
                handleTrackChange(swipeDirection)
            }
        }
    }
    
    private func handleTrackChange(_ swipeDirection: GestureDirection) {
        
        if preferences.allowTrackChange {
            
            // Publish the action message
            SyncMessenger.publishActionMessage(PlaybackActionMessage(swipeDirection == .left ? .previousTrack : .nextTrack))
        }
    }
    
    // Handles a single scroll event
    private func handleScroll(_ event: NSEvent) {
        
        // Calculate the direction and magnitude of the scroll (nil if there is no direction information)
        if let scrollVector = UIUtils.determineScrollVector(event) {
            
            // Vertical scroll = volume control, horizontal scroll = seeking
            scrollVector.direction.isVertical() ? handleVolumeControl(event, scrollVector.direction) : handleSeek(event, scrollVector.direction)
        }
    }
    
    private func handleVolumeControl(_ event: NSEvent, _ scrollDirection: GestureDirection) {
        
        if preferences.allowVolumeControl && ScrollSession.validateEvent(event, scrollDirection) {
        
            // Scroll up = increase volume, scroll down = decrease volume
            SyncMessenger.publishActionMessage(AudioGraphActionMessage(scrollDirection == .up ? .increaseVolume : .decreaseVolume, .continuous))
        }
    }
    
    private func handleSeek(_ event: NSEvent, _ scrollDirection: GestureDirection) {
        
        if preferences.allowSeeking {
            
            // If no track is playing, seeking cannot be performed
            if (playbackInfo.getPlaybackState() == .noTrack) {
                return
            }
            
            // Seeking forward (do not allow residual scroll)
            if (scrollDirection == .right && isResidualScroll(event)) {
                return
            }
            
            if ScrollSession.validateEvent(event, scrollDirection) {
        
                // Scroll left = seek backward, scroll right = seek forward
                SyncMessenger.publishActionMessage(PlaybackActionMessage(scrollDirection == .left ? .seekBackward : .seekForward, .continuous))
            }
        }
    }
    
    /*
        "Residual scrolling" occurs when seeking forward to the end of a playing track (scrolling right), resulting in the next track playing while the scroll is still occurring. Inertia (i.e. the momentum phase of the scroll) can cause scrolling, and hence seeking, to continue after the new track has begun playing. This is undesirable behavior. The scrolling should stop when the new track begins playing.
     
        To prevent residual scrolling, we need to take into account the following variables:
        - the time when the scroll session began
        - the time when the new track began playing
        - the time interval between this event and the last event
     
        Returns a value indicating whether or not this event constitutes residual scroll.
     */
    private func isResidualScroll(_ event: NSEvent) -> Bool {
    
        // If the scroll session began before the currently playing track began playing, then it is now invalid and all its future events should be ignored.
        let playingTrackStartTime = playbackInfo.getPlayingTrackStartTime()!
        let scrollSessionStartTime = ScrollSession.getSessionStartTime()
        let scrollSessionInvalid = scrollSessionStartTime != nil && scrollSessionStartTime! < playingTrackStartTime
        
        // If the time interval between this event and the last one in the scroll session is within the maximum allowed gap between events, it is a part of the previous scroll session
        let lastEventTime = ScrollSession.getLastEventTime() ?? 0
        let thisEventPartOfOldSession = (event.timestamp - lastEventTime) < UIConstants.scrollSessionMaxTimeGapSeconds
        
        // If the session is invalid and this event is part of that invalid session, that indicates residual scroll, and the event should not be processed
        if (scrollSessionInvalid && thisEventPartOfOldSession) {
            
            // Mark the timestamp of this event (for future events), but do not process it
            ScrollSession.updateLastEventTime(event)
            return true
        }
        
        // Not residual scroll
        return false
    }
}

/*
    A helper class that keeps track of a "scroll session" that consists of a set of scroll events performed in rapid succession. The constraint is that, during any single scroll session, scrolling may only be performed in a single direction (left/right/up/down) ... any events with a different scroll direction will be ignored.
 
    This is useful in eliminating human error caused by inexact (diagonal) scrolling, i.e. most people cannot scroll exactly in one direction. They scroll mostly in one direction, but often also a little bit in a perpendicular direction. 
 
    For example, when scrolling left, the user may scroll a little bit up as well. The result of such a scroll should be a scroll up without scrolling left.
 */
fileprivate class ScrollSession {
    
    // State variables that keep track of the current session
    
    // Time when the current scroll session began (nil initially)
    // TimeInterval represents systemUpTime. See ProcessInfo.processInfo.systemUpTime.
    private static var sessionStartTime: TimeInterval?
    
    // Time when last event was triggered (nil if no session currently active)
    // TimeInterval represents systemUpTime. See ProcessInfo.processInfo.systemUpTime.
    private static var lastEventTime: TimeInterval?
    
    // Map of counts of events in different scroll directions. Used to determine the intended scroll direction for a session.
    private static var events: [GestureDirection: Int] = [.up: 0, .down: 0, .left: 0, .right: 0]
    
    // Accessor for the sessionStartTime field
    static func getSessionStartTime() -> TimeInterval? {
        return sessionStartTime
    }
    
    // Accessor for the lastEventTime field
    static func getLastEventTime() -> TimeInterval? {
        return lastEventTime
    }
    
    // Updates the lastEventTime field with the timestamp of a new event. This function is called when it is determined that the event is not to be processed, and the lastEventTime needs to be updated merely for comparison with future invalid events.
    static func updateLastEventTime(_ event: NSEvent) {
        lastEventTime = event.timestamp
    }
   
    // Validates a single scroll event with the given direction, within the context of the current scroll session. Returns true if the event is valid, and false otherwise.
    static func validateEvent(_ event: NSEvent, _ eventDir: GestureDirection) -> Bool {
        
        // Check if this event belongs to the current scroll session (based on time since last event)
        if timeSinceLastEvent(event) < UIConstants.scrollSessionMaxTimeGapSeconds {
            
            // There is an ongoing (current) scroll session. Check if the direction for this event matches the intended scroll direction.
            
            if eventDir != getIntendedDirection() {
                // This event is invalid because its direction differs from the intended direction for this session
                return false
            }

        } else {
            
            // This is a new scroll session, because the max. time gap between sessions has been exceeded
            reset()
        }
        
        // Mark the time for this event
        lastEventTime = event.timestamp
        
        // Increment the count for events with this direction
        events[eventDir] = events[eventDir]! + 1
        
        // Event is valid
        return true
    }
    
    /*
        Determines the intended scroll direction for this session. This is calculated by determining which direction most of the scrolling thus far has been performed in. Example - If the session has 10 scroll Up events and 2 scroll Left events, the intended scroll direction is Up.
     */
    private static func getIntendedDirection() -> GestureDirection {
        
        var maxEvents = 0
        var intendedDir: GestureDirection?
        
        for (direction, count) in events {
            
            if (count > maxEvents) {
                maxEvents = count
                intendedDir = direction
            }
        }
        
        // Value will always be set, ok to force unwrap
        return intendedDir!
    }
    
    // Resets the scroll session to mark a new session
    private static func reset() {
        
        sessionStartTime = ProcessInfo.processInfo.systemUptime
        lastEventTime = nil
        events = [.up: 0, .down: 0, .left: 0, .right: 0]
    }
    
    // Calculates the time since the last event in the current session, in seconds. If there is no current session (i.e. lastEventTime is nil), a large value is returned, so as to indicate that the max time gap between sessions has been exceeded and that a new session should be started.
    private static func timeSinceLastEvent(_ event: NSEvent) -> TimeInterval {
        return lastEventTime == nil ? 10 : (event.timestamp - lastEventTime!)
    }
}

// Enumerates all possible directions of a trackpad/MagicMouse swipe/scroll gesture
enum GestureDirection: String {
    
    case left
    case right
    case down
    case up
    
    func isHorizontal() -> Bool {
        return self == .left || self == .right
    }
    
    func isVertical() -> Bool {
        return self == .up || self == .down
    }
}
