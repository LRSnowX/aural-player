import Cocoa

class FFMpegReader: FileReaderProtocol {
    
    static let instance: FFMpegReader = FFMpegReader()
    
    private var allParsers: [FFMpegMetadataParser] = []
    
    private let genericMetadata_ignoreKeys: [String] = ["title", "artist", "duration", "disc", "track", "album", "genre"]
    
    let commonFFMpegParser = CommonFFMpegMetadataParser()
    let id3Parser = ID3FFmpegParser()
    let wmParser = WMParser()
    let vorbisParser = VorbisCommentParser()
    let apeParser = ApeV2Parser()
    let defaultParser = DefaultFFMpegMetadataParser()
    
    private var wmFileParsers: [FFMpegMetadataParser] = []
    private var vorbisFileParsers: [FFMpegMetadataParser] = []
    private var apeFileParsers: [FFMpegMetadataParser] = []
    
    private var parsersByExt: [String: [FFMpegMetadataParser]] = [:]
    
    init() {
        
        allParsers = [commonFFMpegParser, id3Parser, vorbisParser, apeParser, wmParser, defaultParser]
        wmFileParsers = [commonFFMpegParser, wmParser, id3Parser, vorbisParser, apeParser, defaultParser]
        vorbisFileParsers = [commonFFMpegParser, vorbisParser, apeParser, id3Parser, wmParser, defaultParser]
        apeFileParsers = [commonFFMpegParser, apeParser, vorbisParser, id3Parser, wmParser, defaultParser]
        
        parsersByExt =
        [
            "wma": wmFileParsers,
            "flac": vorbisFileParsers,
            "dsf": vorbisFileParsers,
            "ogg": vorbisFileParsers,
            "opus": vorbisFileParsers,
            "ape": apeFileParsers,
            "mpc": apeFileParsers
        ]
    }
    
    private func cleanUp(_ string: String?) -> String? {
        
        if let theTrimmedString = string?.trim() {
            return theTrimmedString.isEmpty ? nil : theTrimmedString
        }
        
        return nil
    }
    
    func getPrimaryMetadata(for file: URL) throws -> PrimaryMetadata {
        
        let fctx = try FFmpegFileContext(for: file)
        
        guard let audioStream = fctx.bestAudioStream else {
            throw NoAudioStreamError()
        }
        
        var metadata = PrimaryMetadata()
        
//            metadata.audioFormat = audioStream.codecLongName
        
//        track.fileType = fctx.formatLongName.capitalizingFirstLetter()
            
//            let meta = FFmpegMetadataReaderContext(for: fctx)
//            let allParsers = parsersByExt[meta.fileType] ?? self.allParsers
//            allParsers.forEach {$0.mapTrack(meta)}
//
//            let relevantParsers = allParsers.filter {$0.hasMetadataForTrack(meta)}
//
//            track.title = cleanUp(relevantParsers.firstNonNilMappedValue {$0.getTitle(meta)})
//            track.artist = cleanUp(relevantParsers.firstNonNilMappedValue {$0.getArtist(meta)})
//            track.albumArtist = cleanUp(relevantParsers.firstNonNilMappedValue {$0.getAlbumArtist(meta)})
//            track.album = cleanUp(relevantParsers.firstNonNilMappedValue {$0.getAlbum(meta)})
//            track.genre = cleanUp(relevantParsers.firstNonNilMappedValue {$0.getGenre(meta)})
//            track.year = relevantParsers.firstNonNilMappedValue {$0.getYear(meta)}
//            track.bpm = relevantParsers.firstNonNilMappedValue {$0.getBPM(meta)}
//            track.composer = cleanUp(relevantParsers.firstNonNilMappedValue {$0.getComposer(meta)})
//            track.conductor = cleanUp(relevantParsers.firstNonNilMappedValue {$0.getConductor(meta)})
//            track.performer = cleanUp(relevantParsers.firstNonNilMappedValue {$0.getPerformer(meta)})
//            track.lyricist = cleanUp(relevantParsers.firstNonNilMappedValue {$0.getLyricist(meta)})
//
//            track.isDRMProtected = relevantParsers.firstNonNilMappedValue {$0.isDRMProtected(meta)} ?? false
//
//            var trackNumberAndTotal = relevantParsers.firstNonNilMappedValue {$0.getTrackNumber(meta)}
//            if let trackNum = trackNumberAndTotal?.number, trackNumberAndTotal?.total == nil,
//                let totalTracks = relevantParsers.firstNonNilMappedValue({$0.getTotalTracks(meta)}) {
//
//                trackNumberAndTotal = (trackNum, totalTracks)
//            }
//
//            track.trackNumber = trackNumberAndTotal?.number
//            track.totalTracks = trackNumberAndTotal?.total
//
//            var discNumberAndTotal = relevantParsers.firstNonNilMappedValue {$0.getDiscNumber(meta)}
//            if let discNum = discNumberAndTotal?.number, discNumberAndTotal?.total == nil,
//                let totalDiscs = relevantParsers.firstNonNilMappedValue({$0.getTotalDiscs(meta)}) {
//
//                discNumberAndTotal = (discNum, totalDiscs)
//            }
//
//            track.discNumber = discNumberAndTotal?.number
//            track.totalDiscs = discNumberAndTotal?.total
//
//            track.duration = meta.fileCtx.duration
//
//            if let imageStream = meta.imageStream,
//                let imageData = imageStream.attachedPic.data,
//                let image = NSImage(data: imageData) {
//
//                track.art = image
//            }
//
//            if track.duration == 0 || meta.fileCtx.isRawAudioFile {
//
//                if let durationFromMetadata = relevantParsers.firstNonNilMappedValue({$0.getDuration(meta)}), durationFromMetadata > 0 {
//
//                    track.duration = durationFromMetadata
//
//                } else {
//
//                    // Use brute force to compute duration
//                    DispatchQueue.global(qos: .userInitiated).async {
//
//                        if let duration = meta.fileCtx.bruteForceDuration {
//
//                            track.duration = duration
//
//                            var notif = Notification(name: Notification.Name("trackUpdated"))
//                            notif.userInfo = ["track": track]
//
//                            NotificationCenter.default.post(notif)
//                        }
//                    }
//                }
//            }
            
            return metadata
    }
    
    func getSecondaryMetadata(for file: URL) -> SecondaryMetadata {
        return SecondaryMetadata()
    }
    
    func loadPlaybackMetadata(for track: Track) {
        
        
    }
    
    func loadSecondaryMetadata(for track: Track) {
        
        
    }
}
