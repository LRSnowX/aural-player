/*
    A collection of useful utilities for file system operations
 */
import Foundation

class FileSystemUtils {
    
    private static let fileManager: FileManager = FileManager.default
    
    // Checks if a file exists
    static func fileExists(_ file: URL) -> Bool {
        return fileManager.fileExists(atPath: file.path)
    }
    
    // Checks if a file exists
    static func fileExists(_ path: String) -> Bool {
        return fileManager.fileExists(atPath: path)
    }
    
    // Renames a file
    static func renameFile(_ src: URL, _ target: URL) {
        do {
            try fileManager.moveItem(at: src, to: target)
        } catch let error as NSError {
            NSLog("Error renaming file '%@' to '%@': %@", src.path, target.path, error.description)
        }
    }
    
    // Deletes a file
    static func deleteFile(_ path: String) {
        do {
            try fileManager.removeItem(atPath: path)
        } catch let error as NSError {
            NSLog("Error deleting file '%@': %@", path, error.description)
        }
    }
    
    // Retrieves the contents of a directory
    static func getContentsOfDirectory(_ dir: URL) -> [URL]? {
        
        do {
            // Retrieve all files/subfolders within this folder
            let files = try fileManager.contentsOfDirectory(at: dir, includingPropertiesForKeys: [], options: FileManager.DirectoryEnumerationOptions())
            
            // Add them
            return files
            
        } catch let error as NSError {
            NSLog("Error retrieving contents of directory '%@': %@", dir.path, error.description)
            return nil
        }
    }
 
    // Determines whether or not a file (must be resolved) is a directory
    static func isDirectory(_ url: URL) -> Bool {
        
        do {
            let attr = try fileManager.attributesOfItem(atPath: url.path)
            return (attr[FileAttributeKey.type] as! FileAttributeType) == FileAttributeType.typeDirectory
            
        } catch let error as NSError {
            NSLog("Error getting type of file at url '%@': %@", url.path, error.description)
            return false
        }
    }
    
    // Computes the size of a file, and returns a convenient representation
    static func sizeOfFile(path: String) -> Size {
        
        var fileSize : UInt64
        
        do {
            let attr = try fileManager.attributesOfItem(atPath: path)
            fileSize = attr[FileAttributeKey.size] as! UInt64
            return Size(sizeBytes: UInt(fileSize))
            
        } catch let error as NSError {
            NSLog("Error getting size of file '%@': %@", path, error.description)
        }
        
        return Size.ZERO
    }
    
    // Computes a relative path of a target, relative to a source
    // For example, if src = /A/B/C/D.m3u, and target = /A/E.mp3, then the relative path = ../../../E.mp3
    static func relativePath(_ src: URL, _ target: URL) -> String {
        
        let sComps = src.deletingLastPathComponent().resolvingSymlinksInPath().pathComponents
        let tComps = target.deletingLastPathComponent().resolvingSymlinksInPath().pathComponents
        
        // Cursor for traversing the path components
        var cur = 0
        
        // Stays true as long as path components at each level match
        var pathMatch: Bool = true
        
        // Find common path
        // Example: if src = /A/B/C/D, and target = /A/E, then common path = /A
        while cur < sComps.count && cur < tComps.count && pathMatch {
            
            if (sComps[cur] != tComps[cur]) {
                pathMatch = false
            } else {
                cur += 1
            }
        }
        
        // Traverse the source path from the end, up to the last common path component, depending on the value of cur
        let upLevels = sComps.count - cur
        var relPath = ""
        
        if (upLevels > 0) {
            for _ in 1...upLevels {
                relPath.append("../")
            }
        }
        
        // Then, traverse down the target path
        if (cur < tComps.count) {
            for i in cur...tComps.count - 1 {
                relPath.append(tComps[i] + "/")
            }
        }
        
        // Finally, append the target file name
        relPath.append(target.lastPathComponent)
        
        return relPath
    }
    
    // Resolves a Finder alias and returns its true file URL
    static func resolveAlias(_ file: URL) -> URL {
        
        var targetPath:String? = nil
        
        do {
            // Get information about the file alias.
            // If the file is not an alias files, an exception is thrown
            // and execution continues in the catch clause.
            
            let data = try URL.bookmarkData(withContentsOf: file)
            
            // NSURLPathKey contains the target path.
            let resourceValues = URL.resourceValues(forKeys: [URLResourceKey.pathKey], fromBookmarkData: data)
            targetPath = (resourceValues?.allValues[URLResourceKey.pathKey] as! String)
            
            return URL(fileURLWithPath: targetPath!)
            
        } catch {
            // We know that the input path exists, but treating it as an alias
            // file failed, so we assume it's not an alias file and return its
            // *own* full path.
            return file
        }
    }
    
    // Resolves the true path of a URL, resolving sym links and Finder aliases, and determines whether the URL points to a directory
    static func resolveTruePath(_ url: URL) -> (resolvedURL: URL, isDirectory: Bool) {
        
        let resolvedFile1 = url.resolvingSymlinksInPath()
        let resolvedFile2 = resolveAlias(resolvedFile1)
        let isDir = isDirectory(resolvedFile2)
        
        return (resolvedFile2, isDir)
    }
    
    static func getLastPathComponents(_ url: URL, _ numComponents: Int) -> String {
        
        let comps = url.deletingLastPathComponent().pathComponents
        
        var cur = comps.count - 1
        var compCount = 0
        var path: String = "/" + url.lastPathComponent
        
        while cur >= 0 && compCount < numComponents {
            path = "/" + comps[cur] + path
            cur -= 1
            compCount += 1
        }
        
        return path
    }
}
