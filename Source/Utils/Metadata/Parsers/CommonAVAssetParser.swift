import Cocoa
import AVFoundation

fileprivate let keySpace: String = AVMetadataKeySpace.common.rawValue

fileprivate let key_title = String(format: "%@/%@", keySpace, AVMetadataKey.commonKeyTitle.rawValue)
fileprivate let key_artist = String(format: "%@/%@", keySpace, AVMetadataKey.commonKeyArtist.rawValue)
fileprivate let key_album = String(format: "%@/%@", keySpace, AVMetadataKey.commonKeyAlbumName.rawValue)
fileprivate let key_genre = String(format: "%@/%@", keySpace, AVMetadataKey.commonKeyType.rawValue)
fileprivate let key_art: String = String(format: "%@/%@", keySpace, AVMetadataKey.commonKeyArtwork.rawValue)
fileprivate let id_art: AVMetadataIdentifier = AVMetadataItem.identifier(forKey: AVMetadataKey.commonKeyArtwork.rawValue, keySpace: AVMetadataKeySpace.common)!

fileprivate let key_language: String = AVMetadataKey.commonKeyLanguage.rawValue

fileprivate let essentialFieldKeys: Set<String> = [key_title, key_artist, key_album, key_genre, key_art]

class CommonAVAssetParser: AVAssetParser {
    
    func mapTrack(_ mapForTrack: AVFMetadataMap) {
        
        for item in mapForTrack.asset.metadata {
            
            if item.keySpace == .common, let key = item.commonKeyAsString {
                
                let mapKey = String(format: "%@/%@", keySpace, key)
                
                if essentialFieldKeys.contains(mapKey) {
                    mapForTrack.map[mapKey] = item
                } else {
                    // Generic field
                    mapForTrack.genericItems.append(item)
                }
            }
        }
    }
    
    func getDuration(_ mapForTrack: AVFMetadataMap) -> Double? {
        return nil
    }
    
    func getTitle(_ mapForTrack: AVFMetadataMap) -> String? {
        
        if let titleItem = mapForTrack.map[key_title] {
            return titleItem.stringValue
        }
        
        return nil
    }
    
    func getArtist(_ mapForTrack: AVFMetadataMap) -> String? {
        
        if let artistItem = mapForTrack.map[key_artist] {
            return artistItem.stringValue
        }
        
        return nil
    }
    
    func getAlbum(_ mapForTrack: AVFMetadataMap) -> String? {
        
        if let albumItem = mapForTrack.map[key_album] {
            return albumItem.stringValue
        }
        
        return nil
    }
    
    func getGenre(_ mapForTrack: AVFMetadataMap) -> String? {
        
        if let genreItem = mapForTrack.map[key_genre] {
            return genreItem.stringValue
        }
        
        return nil
    }
    
    func getDiscNumber(_ mapForTrack: AVFMetadataMap) -> (number: Int?, total: Int?)? {
        return nil
    }
    
    func getTrackNumber(_ mapForTrack: AVFMetadataMap) -> (number: Int?, total: Int?)? {
        return nil
    }
    
    func getArt(_ mapForTrack: AVFMetadataMap) -> CoverArt? {
        
        if let item = mapForTrack.map[key_art], let imgData = item.dataValue, let image = NSImage(data: imgData) {
            
            let metadata = ParserUtils.getImageMetadata(imgData as NSData)
            return CoverArt(image, metadata)
        }
        
        return nil
    }
    
    func getArt(_ asset: AVURLAsset) -> CoverArt? {
        
        if let item = AVMetadataItem.metadataItems(from: asset.commonMetadata, filteredByIdentifier: id_art).first, let imgData = item.dataValue, let image = NSImage(data: imgData) {
            
            let metadata = ParserUtils.getImageMetadata(imgData as NSData)
            return CoverArt(image, metadata)
        }
        
        return nil
    }
    
    func getLyrics(_ mapForTrack: AVFMetadataMap) -> String? {
        return nil
    }
    
    func getChapterTitle(_ items: [AVMetadataItem]) -> String? {
        
        return items.first(where: {
            
            $0.keySpace == .common && $0.commonKeyAsString == AVMetadataKey.commonKeyTitle.rawValue
            
        })?.stringValue
    }
    
    func getGenericMetadata(_ mapForTrack: AVFMetadataMap) -> [String: MetadataEntry] {
        
        var metadata: [String: MetadataEntry] = [:]

        for item in mapForTrack.genericItems.filter({item -> Bool in item.keySpace == .common}) {
            
            if let key = item.commonKeyAsString, var value = item.valueAsString {
                
                if key == key_language, let langName = LanguageMap.forCode(value.trim()) {
                    value = langName
                }
                
                metadata[key] = MetadataEntry(.common, StringUtils.splitCamelCaseWord(key, true), value)
            }
        }
        
        return metadata
    }
}
