import Foundation

class AudioFilePreparationAction: NSObject, PlaybackChainAction, AsyncMessageSubscriber {
    
    private let player: PlayerProtocol
    private let sequencer: SequencerProtocol
    private let transcoder: TranscoderProtocol
    
    var nextAction: PlaybackChainAction?
    
    var deferredContext: PlaybackRequestContext?

    init(_ player: PlayerProtocol, _ sequencer: SequencerProtocol, _ transcoder: TranscoderProtocol) {
        
        self.player = player
        self.sequencer = sequencer
        self.transcoder = transcoder

        super.init()
        AsyncMessenger.subscribe([.transcodingFinished, .transcodingCancelled], subscriber: self, dispatchQueue: DispatchQueue.main)
    }
    
    func execute(_ context: PlaybackRequestContext) {
        
        guard let track = context.requestedTrack else {return}
        
//        print("\tPreparing:", track.conciseDisplayName)
        
//        TrackIO.prepareForPlayback(track)
        track.prepareForPlayback()
        
        // Track preparation failed
        if track.lazyLoadingInfo.preparationFailed, let preparationError = track.lazyLoadingInfo.preparationError {
            
//            print("\tERROR Preparing:", track.conciseDisplayName)
            
            // If an error occurs, end the playback sequence
            sequencer.end()
            
            // Send out an async error message instead of throwing
            AsyncMessenger.publishMessage(TrackNotPlayedAsyncMessage(context.currentTrack, preparationError))
            
            // Terminate the chain
            return
        }
        // Track needs to be transcoded (i.e. audio format is not natively supported)
        else if !track.lazyLoadingInfo.preparedForPlayback && track.lazyLoadingInfo.needsTranscoding {
            
//            print("\tNeeds transcoding, will defer playback:", track.conciseDisplayName)
            
            // Defer playback until transcoding finishes
            transcoder.transcodeImmediately(track)
            
            // Notify the player that transcoding has begun.
            player.transcoding()
            
            // Mark this context as having been deferred for later execution (when transcoding completes)
            deferredContext = context
            
            // , and terminate the chain.
            return
        }
        
        nextAction?.execute(context)
    }
    
    func consumeAsyncMessage(_ message: AsyncMessage) {
       
        if let transcodingFinishedMsg = message as? TranscodingFinishedAsyncMessage {
            
            transcodingFinished(transcodingFinishedMsg)
            return
            
        } else if let transcodingCancelledMsg = message as? TranscodingCancelledAsyncMessage {
            
            transcodingCancelled(transcodingCancelledMsg)
            return
        }
    }
    
    private func transcodingFinished(_ msg: TranscodingFinishedAsyncMessage) {
        
        // Make sure there is no delay (i.e. state != waiting) before acting on this message.
        // And match the transcoded track to that from the deferred request context.
        if player.state != .waiting, msg.success, let theDeferredContext = deferredContext,
            PlaybackRequestContext.isCurrent(theDeferredContext), msg.track == theDeferredContext.requestedTrack {

            // Proceed with the playback chain.
            nextAction?.execute(theDeferredContext)
        }
        
        // Reset the deferredContext.
        deferredContext = nil
    }
    
    private func transcodingCancelled(_ msg: TranscodingCancelledAsyncMessage) {

        // Previously requested transcoding was cancelled. Reset the deferred request context.
        if let theDeferredContext = deferredContext, msg.track == theDeferredContext.requestedTrack {
            deferredContext = nil
        }
    }
}
