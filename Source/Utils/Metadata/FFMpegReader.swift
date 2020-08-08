import Cocoa

class FFMpegReader {
    
//    private let allParsers: [FFMpegMetadataParser]
//    
//    private let theReader: FFmpegMetadataReader = FFmpegMetadataReader()
//    
//    // TODO: Is this useful/necessary ?
//    private let wmFileParsers: [FFMpegMetadataParser]
//    private let vorbisCommentFileParsers: [FFMpegMetadataParser]
//    private let apeFileParsers: [FFMpegMetadataParser]
//    
//    private let genericMetadata_ignoreKeys: [String] = ["title", "artist", "duration", "disc", "track", "album", "genre"]
//    
//    private var metadataMap: ConcurrentMap<Track, LibAVMetadata> = ConcurrentMap<Track, LibAVMetadata>("ffmpeg-metadataMap")
//    
//    init(_ commonFFMpegParser: CommonFFMpegMetadataParser, _ id3Parser: ID3Parser, _ vorbisParser: VorbisCommentParser, _ apeParser: ApeV2Parser, _ wmParser: WMParser, _ defaultParser: DefaultFFMpegMetadataParser) {
//        
//        allParsers = [commonFFMpegParser, id3Parser, vorbisParser, apeParser, wmParser, defaultParser]
//        
//        wmFileParsers = [commonFFMpegParser, wmParser, id3Parser, vorbisParser, apeParser, defaultParser]
//        vorbisCommentFileParsers = [commonFFMpegParser, vorbisParser, id3Parser, apeParser, wmParser, defaultParser]
//        apeFileParsers = [commonFFMpegParser, apeParser, id3Parser, vorbisParser, wmParser, defaultParser]
//    }
//    
//    private func ensureTrackAssetLoaded(_ track: Track) {
//        
////        if track.ffmpegTrackInfo == nil, let fileContext = FFmpegFileContext(forFile: track.file) {
////            
////            track.ffmpegTrackInfo = fileContext
////            let allTrackMetadata = theReader.readMetadata(forFile: fileContext)
////            track.ffmpegMetadata = allTrackMetadata
////            
////            let libAVMetadata = LibAVMetadata(allTrackMetadata.metadata)
////            
////            parsersForTrack(track).forEach({$0.mapTrack(libAVMetadata)})
////            metadataMap[track] = libAVMetadata
////        }
//    }
//    
//    private func nilIfEmpty(_ string: String?) -> String? {
//        return StringUtils.isStringEmpty(string) ? nil : string
//    }
//
//    func getPrimaryMetadata(_ track: Track) -> PrimaryMetadata {
//        
//        ensureTrackAssetLoaded(track)
//        
//        let title = nilIfEmpty(getTitle(track))
//        let artist = nilIfEmpty(getArtist(track))
//        let album = nilIfEmpty(getAlbum(track))
//        let genre = nilIfEmpty(getGenre(track))
//        
//        let duration = getDuration(track)
//        
//        return PrimaryMetadata(title, artist, album, genre, duration)
//    }
//    
//    // TODO: Is this useful/necessary ?
//    private func parsersForTrack(_ track: Track) -> [FFMpegMetadataParser] {
//        
//        let ext = track.file.pathExtension
//        
//        switch ext {
//            
//        case "wma":     return wmFileParsers
//            
//        case "flac", "ogg", "opus":     return vorbisCommentFileParsers
//            
//        case "ape":     return apeFileParsers
//            
//        default: return allParsers
//            
//        }
//    }
//    
//    private func getTitle(_ track: Track) -> String? {
//        
//        if let metadata = metadataMap[track] {
//            
//            for parser in parsersForTrack(track) {
//                
//                if let title = parser.getTitle(metadata) {
//                    return title
//                }
//            }
//        }
//        
//        return nil
//    }
//    
//    private func getArtist(_ track: Track) -> String? {
//        
//        if let metadata = metadataMap[track] {
//            
//            for parser in parsersForTrack(track) {
//                
//                if let artist = parser.getArtist(metadata) {
//                    return artist
//                }
//            }
//        }
//        
//        return nil
//    }
//    
//    private func getAlbum(_ track: Track) -> String? {
//        
//        if let metadata = metadataMap[track] {
//            
//            for parser in parsersForTrack(track) {
//                
//                if let album = parser.getAlbum(metadata) {
//                    return album
//                }
//            }
//        }
//        
//        return nil
//    }
//    
//    private func getGenre(_ track: Track) -> String? {
//        
//        if let metadata = metadataMap[track] {
//            
//            for parser in parsersForTrack(track) {
//                
//                if let genre = parser.getGenre(metadata) {
//                    return genre
//                }
//            }
//        }
//        
//        return nil
//    }
//    
//    func getDuration(_ track: Track) -> Double {
//        
//        // TODO: Here is where we may need to build a packet table !!! (if isRawFile, ...)
//        
//        return track.ffmpegMetadata!.audioInfo.duration
//    }
//    
//    func getSecondaryMetadata(_ track: Track) -> SecondaryMetadata {
//        
//        ensureTrackAssetLoaded(track)
//        
//        var discNumberAndTotal = getDiscNumber(track)
//        if let discNum = discNumberAndTotal?.number, discNumberAndTotal?.total == nil, let totalDiscs = getTotalDiscs(track) {
//            discNumberAndTotal = (discNum, totalDiscs)
//        }
//        
//        var trackNumberAndTotal = getTrackNumber(track)
//        if let trackNum = trackNumberAndTotal?.number, trackNumberAndTotal?.total == nil, let totalTracks = getTotalTracks(track) {
//            trackNumberAndTotal = (trackNum, totalTracks)
//        }
//        
//        let lyrics = getLyrics(track)
//        
//        return SecondaryMetadata(discNumberAndTotal?.number, discNumberAndTotal?.total, trackNumberAndTotal?.number, trackNumberAndTotal?.total, lyrics)
//    }
//    
//    func getChapters(_ track: Track) -> [Chapter] {
//        return track.ffmpegMetadata?.chapters.map {Chapter($0.title, $0.startTime, $0.endTime)} ?? []
//    }
//    
//    private func getDiscNumber(_ track: Track) -> (number: Int?, total: Int?)? {
//        
//        if let map = metadataMap[track] {
//            
//            for parser in parsersForTrack(track) {
//                
//                if let discNum = parser.getDiscNumber(map) {
//                    return discNum
//                }
//            }
//        }
//        
//        return nil
//    }
//    
//    private func getTotalDiscs(_ track: Track) -> Int? {
//        
//        if let map = metadataMap[track] {
//            
//            for parser in parsersForTrack(track) {
//                
//                if let totalDiscs = parser.getTotalDiscs(map) {
//                    return totalDiscs
//                }
//            }
//        }
//        
//        return nil
//    }
//    
//    private func getTrackNumber(_ track: Track) -> (number: Int?, total: Int?)? {
//        
//        if let map = metadataMap[track] {
//            
//            for parser in parsersForTrack(track) {
//                
//                if let trackNum = parser.getTrackNumber(map) {
//                    return trackNum
//                }
//            }
//        }
//        
//        return nil
//    }
//    
//    private func getTotalTracks(_ track: Track) -> Int? {
//        
//        if let map = metadataMap[track] {
//            
//            for parser in parsersForTrack(track) {
//                
//                if let totalTracks = parser.getTotalTracks(map) {
//                    return totalTracks
//                }
//            }
//        }
//        
//        return nil
//    }
//    
//    private func getLyrics(_ track: Track) -> String? {
//        
//        if let map = metadataMap[track] {
//            
//            for parser in parsersForTrack(track) {
//                
//                if let lyrics = parser.getLyrics(map) {
//                    return lyrics
//                }
//            }
//        }
//        
//        return nil
//    }
//    
//    func getArt(_ track: Track) -> CoverArt? {
//        
//        ensureTrackAssetLoaded(track)
//        
//        if let avInfo = track.ffmpegMetadata {
//        
//            if let coverArt = avInfo.art {
////                return FFMpegWrapper.getArt(track)
//                return CoverArt(coverArt, nil)
//            }
//        }
//        
//        return nil
//    }
//    
//    func getArt(_ file: URL) -> CoverArt? {
////        return FFMpegWrapper.getArt(file)
//        return nil
//    }
//    
//    func getAllMetadata(_ track: Track) -> [String: MetadataEntry] {
//        
//        var metadata: [String: MetadataEntry] = [:]
//        
//        if let map = metadataMap[track] {
//            
//            for parser in parsersForTrack(track) {
//                
//                let parserMetadata = parser.getGenericMetadata(map)
//                parserMetadata.forEach({(k,v) in metadata[k] = v})
//            }
//        }
//        
//        return metadata
//    }
//    
//    func getDurationForFile(_ file: URL) -> Double {
//        
//        // TODO (not needed yet)
//        return 0
//    }
}
