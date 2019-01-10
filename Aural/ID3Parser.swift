import Cocoa
import AVFoundation

class ID3Parser: AVAssetParser {
    
    private let keys_duration: [String] = [V22Spec.key_duration, V24Spec.key_duration]
    
    private let keys_title: [String] = [V1Spec.key_title, V22Spec.key_title, V24Spec.key_title]
    private let keys_artist: [String] = [V1Spec.key_artist, V22Spec.key_artist, V24Spec.key_artist]
    private let keys_album: [String] = [V1Spec.key_album, V22Spec.key_album, V24Spec.key_album]
    private let keys_genre: [String] = [V1Spec.key_genre, V22Spec.key_genre, V24Spec.key_genre]
    
    private let keys_discNumber: [String] = [V22Spec.key_discNumber, V24Spec.key_discNumber]
    private let keys_trackNumber: [String] = [V1Spec.key_trackNumber, V22Spec.key_trackNumber, V24Spec.key_trackNumber]
    
    private let keys_lyrics: [String] = [V22Spec.key_lyrics, V22Spec.key_syncLyrics, V24Spec.key_lyrics, V24Spec.key_syncLyrics]
    private let keys_art: [String] = [V22Spec.key_art, V24Spec.key_art]
    private let ids_art: [AVMetadataIdentifier] = [V22Spec.id_art, V24Spec.id_art]
    
    private let keys_GEOB: [String] = [V22Spec.key_GEO, V24Spec.key_GEOB]
    private let keys_language: [String] = [V22Spec.key_language, V24Spec.key_language]
    private let keys_playCounter: [String] = [V22Spec.key_playCounter, V24Spec.key_playCounter]
    
    private let essentialFieldKeys: Set<String> = {
        
        var keys: Set<String> = Set<String>()
        keys = keys.union(V1Spec.essentialFieldKeys)
        keys = keys.union(V22Spec.essentialFieldKeys)
        keys = keys.union(V24Spec.essentialFieldKeys)
        
        return keys
    }()
    
    private let genericFields: [String: String] = {
        
        var map: [String: String] = [:]
        V22Spec.genericFields.forEach({(k,v) in map[k] = v})
        V24Spec.genericFields.forEach({(k,v) in map[k] = v})
        
        return map
    }()
    
    private let id_art: AVMetadataIdentifier = AVMetadataItem.identifier(forKey: AVMetadataKey.id3MetadataKeyAttachedPicture.rawValue, keySpace: AVMetadataKeySpace.id3)!
    
    private let replaceableKeyFields: Set<String> = {
        
        var keys: Set<String> = Set<String>()
        keys = keys.union(V22Spec.replaceableKeyFields)
        keys = keys.union(V24Spec.replaceableKeyFields)
        
        return keys
    }()
    
    private let infoKeys_TXXX: [String: String] = ["albumartist": "Album Artist", "compatible_brands": "Compatible Brands", "gn_extdata": "Gracenote Data"]
    
    private func readableKey(_ key: String) -> String {
        return genericFields[key] ?? key.capitalizingFirstLetter()
    }
    
    func mapTrack(_ track: Track, _ mapForTrack: AVAssetMetadata) {
        
        let items = track.audioAsset!.metadata
        
        for item in items {
            
            if item.keySpace == AVMetadataKeySpace.id3, let key = item.keyAsString {
                
                let mapKey = String(format: "%@/%@", AVMetadataKeySpace.id3.rawValue, key)
                
                if essentialFieldKeys.contains(mapKey) {
                    mapForTrack.map[mapKey] = item
                } else {
                    // Generic field
                    mapForTrack.genericMap[mapKey] = item
                }
            }
        }
    }
    
    func getDuration(_ mapForTrack: AVAssetMetadata) -> Double? {
        
        for key in keys_duration {
            
            if let item = mapForTrack.map[key], let durationStr = item.stringValue, let durationMsecs = Double(durationStr) {
                return durationMsecs / 1000
            }
        }
        
        return nil
    }
    
    func getTitle(_ mapForTrack: AVAssetMetadata) -> String? {
        
        for key in keys_title {

            if let titleItem = mapForTrack.map[key] {
                return titleItem.stringValue
            }
        }
        
        return nil
    }
    
    func getArtist(_ mapForTrack: AVAssetMetadata) -> String? {
        
        for key in keys_artist {

            if let artistItem = mapForTrack.map[key] {
                return artistItem.stringValue
            }
        }
        
        return nil
    }
    
    func getAlbum(_ mapForTrack: AVAssetMetadata) -> String? {
        
        for key in keys_album {

            if let albumItem = mapForTrack.map[key] {
                return albumItem.stringValue
            }
        }
        
        return nil
    }
    
    func getGenre(_ mapForTrack: AVAssetMetadata) -> String? {
        
        for key in keys_genre {

            if let genreItem = mapForTrack.map[key] {

                if let str = genreItem.stringValue {

                    return parseGenreNumericString(str)

                } else if let data = genreItem.dataValue {

                    // Parse as hex string
                    let code = Int(data.hexEncodedString(), radix: 16)!
                    return GenreMap.forId(code)
                }
            }
        }
        
        return nil
    }
    
    private func parseGenreNumericString(_ string: String) -> String {
        
        let decimalChars = CharacterSet.decimalDigits
        let alphaChars = CharacterSet.lowercaseLetters.union(CharacterSet.uppercaseLetters)
        
        // If no alphabetic characters are present, and numeric characters are present, treat this as a numerical genre code
        if string.rangeOfCharacter(from: alphaChars) == nil, string.rangeOfCharacter(from: decimalChars) != nil {
            
            // Need to parse the number
            let numberStr = string.trimmingCharacters(in: decimalChars.inverted)
            if let genreCode = Int(numberStr) {
                
                // Look up genreId in ID3 table
                return GenreMap.forId(genreCode) ?? string
            }
        }
        
        return string
    }
    
    func getDiscNumber(_ mapForTrack: AVAssetMetadata) -> (number: Int?, total: Int?)? {
        
        for key in keys_discNumber {
            
            if let item = mapForTrack.map[key] {
                return parseDiscOrTrackNumber(item)
            }
        }
        
        return nil
    }
    
    func getTrackNumber(_ mapForTrack: AVAssetMetadata) -> (number: Int?, total: Int?)? {
        
        for key in keys_trackNumber {
            
            if let item = mapForTrack.map[key] {
                return parseDiscOrTrackNumber(item)
            }
        }
        
        return nil
    }
    
    private func parseDiscOrTrackNumber(_ item: AVMetadataItem) -> (number: Int?, total: Int?)? {
        
        if let number = item.numberValue {
            return (number.intValue, nil)
        }
        
        if let stringValue = item.stringValue?.trim() {
            
            // Parse string (e.g. "2 / 13")
            
            if let num = Int(stringValue) {
                return (num, nil)
            }
            
            let tokens = stringValue.split(separator: "/")
            
            if !tokens.isEmpty {
                
                let s1 = tokens[0].trim()
                var s2: String?
                
                let n1: Int? = Int(s1)
                var n2: Int?
                
                if tokens.count > 1 {
                    s2 = tokens[1].trim()
                    n2 = Int(s2!)
                }
                
                return (n1, n2)
            }
            
        } else if let dataValue = item.dataValue {
            
            // Parse data
            let hexString = dataValue.hexEncodedString()
            
            if hexString.count >= 8 {
                
                let s1: String = hexString.substring(range: 4..<8)
                let n1: Int? = Int(s1, radix: 16)
                
                var s2: String?
                var n2: Int?
                
                if hexString.count >= 12 {
                    s2 = hexString.substring(range: 8..<12)
                    n2 = Int(s2!, radix: 16)
                }
                
                return (n1, n2)
                
            } else if hexString.count >= 4 {
                
                // Only one number
                
                let s1: String = String(hexString.prefix(4))
                let n1: Int? = Int(s1, radix: 16)
                return (n1, nil)
            }
        }
        
        return nil
    }
    
    func getArt(_ mapForTrack: AVAssetMetadata) -> NSImage? {
        
        for key in keys_art {
        
            if let item = mapForTrack.map[key], let imgData = item.dataValue {
                return NSImage(data: imgData)
            }
        }
        
        return nil
    }
    
    func getArt(_ asset: AVURLAsset) -> NSImage? {
        
        for id in ids_art {
            
            if let item = AVMetadataItem.metadataItems(from: asset.metadata, filteredByIdentifier: id).first, let imgData = item.dataValue {
                return NSImage(data: imgData)
            }
        }
        
        return nil
    }
    
    func getLyrics(_ mapForTrack: AVAssetMetadata) -> String? {
        
        for key in keys_lyrics {

            if let lyricsItem = mapForTrack.map[key] {
                return lyricsItem.stringValue
            }
        }
        
        return nil
    }
    
    func getGenericMetadata(_ mapForTrack: AVAssetMetadata) -> [String: MetadataEntry] {
        
        var metadata: [String: MetadataEntry] = [:]
        
        for item in mapForTrack.genericMap.values.filter({item -> Bool in item.keySpace == .id3}) {

            if let key = item.keyAsString, let value = item.valueAsString {

                var entryKey = key
                var entryValue = value

                // Special fields
                if replaceableKeyFields.contains(key), let attrs = item.extraAttributes, !attrs.isEmpty {

                    // TXXX or COMM or WXXX
                    if let infoKey = mapReplaceableKeyField(attrs), !StringUtils.isStringEmpty(infoKey) {
                        entryKey = infoKey
                    }

                } else if keys_GEOB.contains(key), let attrs = item.extraAttributes, !attrs.isEmpty {

                    // GEOB
                    let kv = mapGEOB(attrs)
                    if let infoKey = kv.key {
                        entryKey = infoKey
                    }

                    if let objVal = kv.value {
                        entryValue = objVal
                    }

                } else if keys_playCounter.contains(key) {

                    // PCNT
                    entryValue = item.valueAsNumericalString

                } else if keys_language.contains(key), let langName = LanguageMap.forCode(value.trim()) {

                    // TLAN
                    entryValue = langName
                }

                entryKey = StringUtils.cleanUpString(entryKey)
                entryValue = StringUtils.cleanUpString(entryValue)

                metadata[entryKey] = MetadataEntry(.id3, readableKey(entryKey), entryValue)
            }
        }
        
        return metadata
    }
    
    private func mapGEOB(_ attrs: [AVMetadataExtraAttributeKey : Any]) -> (key: String?, value: String?) {
        
        var info: String?
        var value: String = ""
        
        for (k, v) in attrs {
            
            let key = k.rawValue
            let aValue = String(describing: v)
            
            if key == "info" {
                info = aValue
            } else if !StringUtils.isStringEmpty(aValue) {
                value += String(format: "%@ = %@, ", key, aValue)
            }
        }
        
        if value.count > 2 {
            value = value.substring(range: 0..<(value.count - 2))
        }
        
        return (info?.capitalizingFirstLetter(), value.isEmpty ? nil : value)
    }
    
    private func mapReplaceableKeyField(_ attrs: [AVMetadataExtraAttributeKey : Any]) -> String? {
        
        for (k, v) in attrs {
            
            let key = k.rawValue
            let aValue = String(describing: v)
            
            if key == "info" {
                
                if let rKey = infoKeys_TXXX[aValue.lowercased()] {
                    return rKey
                }
                
                return aValue.capitalizingFirstLetter()
            }
        }
        
        return nil
    }
}
