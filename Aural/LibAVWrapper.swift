import Cocoa

class LibAVWrapper {
    
    static let avConvBinaryPath: String? = Bundle.main.url(forResource: "avconv", withExtension: "")?.path
    
    static let metadataIgnoreKeys: [String] = ["Stream #0.0", "Stream #0.1", "Stream #0.2", "bitrate"]
    
    static let transcodingFormatsMap: [String: String] = ["flac": "aiff", "wma": "mp3", "ogg": "mp3"]
    
    static func transcode(_ inputFile: URL) -> URL? {
        
        if let binaryPath = avConvBinaryPath {
            
            let inputFileExtension = inputFile.pathExtension.lowercased()
            let outputFileExtension = transcodingFormatsMap[inputFileExtension] ?? "mp3"
            
            let outputFile = URL(fileURLWithPath: inputFile.path + "-transcoded." + outputFileExtension)
            _ = runCommand(cmd: binaryPath, args: "-i", inputFile.path, "-ac" , "2" , outputFile.path)
            
            return outputFile
        }
        
        return nil
    }
    
    static func getMetadata(_ inputFile: URL) -> LibAVInfo {
        
        var map: [String: String] = [:]
        var streams: [LibAVStream] = []
        var duration: Double = 0
        
        if let binaryPath = avConvBinaryPath {
            
            let cmdOutput = runCommand(cmd: binaryPath, args: "-i", inputFile.path)
            
            var foundMetadata: Bool = false
            outerLoop: for line in cmdOutput.error {
                
                let trimmedLine = line.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                
                // Stream
                
                if trimmedLine.hasPrefix("Stream #") {
                    
                    let tokens = trimmedLine.split(separator: ":")
                    
                    if tokens.count >= 3 {
                        
                        let streamTypeStr = tokens[1].trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                        let type: LibAVStreamType = streamTypeStr == "Audio" ? .audio : .video
                        
                        let commaSepTokens = tokens[2].split(separator: ",")
                        
                        if commaSepTokens.count > 0 {
                            let format = commaSepTokens[0].trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                            streams.append(LibAVStream(type, format))
                        }
                    }
                    
                    continue
                    
                } else if trimmedLine.hasPrefix("Duration:") {
                    
                    let commaSepTokens = line.split(separator: ",")
                    
                    let durKV = commaSepTokens[0]
                    let tokens = durKV.split(separator: ":")
                    
                    if tokens.count >= 4 {
                        
                        let hrsS = tokens[1].trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                        let minsS = tokens[2]
                        let secsS = tokens[3]
                        
                        let hrs = Double(hrsS) ?? 0, mins = Double(minsS) ?? 0, secs = Double(secsS) ?? 0
                        duration = hrs * 3600 + mins * 60 + secs
                    }
                    
                    continue
                }
                
                if foundMetadata {
                    
                    // Split KV entry into key/value
                    if let firstColon = trimmedLine.firstIndex(of: ":") {
                        
                        let key = trimmedLine[..<firstColon].trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                        
                        let colonPlus1 = trimmedLine.index(after: firstColon)
                        let value = trimmedLine[colonPlus1...].trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                        
                        // Avoid any subsequent Metadata fields
                        if key == "Metadata" {
                            break outerLoop
                        } else if !metadataIgnoreKeys.contains(String(key)) {
                            map[key.lowercased()] = value
                        }
                    }
                    
                } else if line.contains("Metadata:") {foundMetadata = true}
            }
        }
        
        return LibAVInfo(duration, streams, map)
    }
    
    static func getArtwork(_ inputFile: URL) -> NSImage? {
        
        if let binaryPath = avConvBinaryPath {
            
            let imgPath = inputFile.path + "-albumArt.jpg"
            let cmdOutput = runCommand(cmd: binaryPath, args: "-i", inputFile.path, "-an", "-vcodec", "copy", imgPath)
            if cmdOutput.exitCode == 0 {
                return NSImage(contentsOf: URL(fileURLWithPath: imgPath))
            }
        }
        
        return nil
    }
    
    private static func runCommand(cmd : String, args : String...) -> (output: [String], error: [String], exitCode: Int32) {
        
        var output : [String] = []
        var error : [String] = []
        
        let task = Process()
        task.launchPath = cmd
        task.arguments = args
        
        let outpipe = Pipe()
        task.standardOutput = outpipe
        let errpipe = Pipe()
        task.standardError = errpipe
        
        task.launch()
        
        task.waitUntilExit()
        let status = task.terminationStatus
        
        let outdata = outpipe.fileHandleForReading.readDataToEndOfFile()
        if var string = String(data: outdata, encoding: .utf8) {
            string = string.trimmingCharacters(in: .newlines)
            output = string.components(separatedBy: "\n")
        }
        
        let errdata = errpipe.fileHandleForReading.readDataToEndOfFile()
        if var string = String(data: errdata, encoding: .utf8) {
            string = string.trimmingCharacters(in: .newlines)
            error = string.components(separatedBy: "\n")
        }
        
        return (output, error, status)
    }
    
}
