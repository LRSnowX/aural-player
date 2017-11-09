import AVFoundation

/*
    Utility functions related to audio.
 */
class AudioUtils {
    
    // Validates a track to determine if it is playable. If the track is not playable, returns an error object describing the problem.
    static func validateTrack(_ track: Track) -> InvalidTrackError? {
        
        // TODO: What if file has protected content
        // Check sourceAsset.hasProtectedContent()
        // Test against a protected iTunes file
        
        if (track.audioAsset == nil) {
            track.audioAsset = AVURLAsset(url: track.file, options: nil)
        }
        
        let assetTracks = track.audioAsset?.tracks(withMediaType: AVMediaTypeAudio)
        
        // Check if the asset has any audio tracks
        if (assetTracks?.count == 0) {
            return NoAudioTracksError(track.file)
        }
        
        // Find out if track is playable
        let assetTrack = assetTracks?.first
        
        // TODO: What does isPlayable actually mean ?
        if (!(assetTrack?.isPlayable)!) {
            return TrackNotPlayableError(track.file)
        }
        
        // Determine the format to find out if it is supported
        let format = getFormat(assetTrack!)
        if (!AppConstants.supportedAudioFileFormats.contains(format)) {
            return UnsupportedFormatError(track.file, format)
        }
        
        return nil
    }
    
    // Loads info necessary for playback of the given track. Returns whether or not the info was successfully loaded.
    static func loadPlaybackInfo(_ track: Track) -> Bool {
        
        if let audioFile = AudioIO.createAudioFileForReading(track.file) {
        
            let playbackInfo = PlaybackInfo()
            
            playbackInfo.audioFile = audioFile
            playbackInfo.sampleRate = audioFile.processingFormat.sampleRate
            
            if (!track.hasDuration()) {
                let duration = track.audioAsset!.duration.seconds
                track.setDuration(duration)
                
                // TODO: Emit track updated event, so that duration is updated in UI
            }
            
            playbackInfo.frames = Int64(playbackInfo.sampleRate! * track.duration)
            playbackInfo.numChannels = Int(playbackInfo.audioFile!.fileFormat.channelCount)
            
            track.playbackInfo = playbackInfo
            
            return true
        }
        
        return false
    }
    
    // Loads detailed audio-specific info for the given track
    static func loadAudioInfo(_ track: Track) {
        
        let audioInfo = AudioInfo()
        
        let assetTracks = track.audioAsset!.tracks(withMediaType: AVMediaTypeAudio)
        audioInfo.format = getFormat(assetTracks.first!)
        
        let fileSize = FileSystemUtils.sizeOfFile(path: track.file.path)
        audioInfo.bitRate = normalizeBitRate(Double(fileSize.sizeBytes) * 8 / (Double(track.duration) * Double(Size.KB)))
        
        track.audioInfo = audioInfo
    }
    
    // Normalizes a bit rate by rounding it to the nearest multiple of 32. For ex, a bit rate of 251.5 kbps is rounded to 256 kbps.
    private static func normalizeBitRate(_ rate: Double) -> Int {
        return Int(round(rate/32)) * 32
    }
    
    // Computes a readable format string for an audio track
    private static func getFormat(_ assetTrack: AVAssetTrack) -> String {
        
        let description = CMFormatDescriptionGetMediaSubType(assetTrack.formatDescriptions.first as! CMFormatDescription)
        return codeToString(description).trimmingCharacters(in: CharacterSet.init(charactersIn: "."))
    }
    
    // Converts a four character media type code to a readable string
    private static func codeToString(_ code: FourCharCode) -> String {
        
        let numericCode = Int(code)
        
        var codeString: String = String (describing: UnicodeScalar((numericCode >> 24) & 255)!)
        codeString.append(String(describing: UnicodeScalar((numericCode >> 16) & 255)!))
        codeString.append(String(describing: UnicodeScalar((numericCode >> 8) & 255)!))
        codeString.append(String(describing: UnicodeScalar(numericCode & 255)!))
        
        return codeString.trimmingCharacters(in: CharacterSet.whitespaces)
    }
}
