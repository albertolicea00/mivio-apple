import Foundation
import SwiftData

// MARK: - Media Scanner Protocol
public protocol MediaScanner: Sendable {
    /// Recursively scans a media source and streams discovered items in real-time.
    /// - Parameter source: The source entity containing path and credential configs.
    /// - Returns: An async stream emitting parsed MediaItems.
    func scan(source: Source) -> AsyncStream<MediaItem>
}

// MARK: - Local Media Scanner
public final class LocalMediaScanner: MediaScanner {
    private let supportedExtensions = ["mkv", "mp4", "avi", "mov", "webm"]
    
    public init() {}
    
    public func scan(source: Source) -> AsyncStream<MediaItem> {
        AsyncStream { continuation in
            let folderUrl = URL(fileURLWithPath: source.path)
            
            Task(priority: .background) {
                let fileManager = FileManager.default
                
                guard let enumerator = fileManager.enumerator(
                    at: folderUrl,
                    includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey],
                    options: [.skipsHiddenFiles]
                ) else {
                    continuation.finish()
                    return
                }
                
                while let fileUrl = enumerator.nextObject() as? URL {
                    if Task.isCancelled { break }
                    
                    guard let resourceValues = try? fileUrl.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey]),
                          resourceValues.isRegularFile == true,
                          self.supportedExtensions.contains(fileUrl.pathExtension.lowercased()) else {
                        continue
                    }
                    
                    let size = Int64(resourceValues.fileSize ?? 0)
                    let fileName = fileUrl.lastPathComponent
                    let parsedInfo = MivioGuessItParser.parse(fileName: fileName)
                    
                    let item = MediaItem(
                        path: fileUrl.path,
                        type: parsedInfo.type,
                        size: size,
                        fileName: fileName,
                        source: source
                    )
                    
                    continuation.yield(item)
                }
                continuation.finish()
            }
        }
    }
}

// MARK: - SMB Media Scanner (Network Interface Skeleton)
public final class SMBMediaScanner: MediaScanner {
    private let supportedExtensions = ["mkv", "mp4", "avi", "mov", "webm"]
    
    public init() {}
    
    public func scan(source: Source) -> AsyncStream<MediaItem> {
        AsyncStream { continuation in
            Task(priority: .background) {
                // In a full implementation, you would authenticate using source.host, source.username,
                // and fetch passwordKey from Keychain to connect using AMSMB2 client.
                // Here, we simulate discovering network items to demonstrate structure.
                
                let simulatedFiles = [
                    "Interstellar.2014.2160p.UHD.x265.mkv",
                    "Ted.Lasso.S01E01.1080p.mp4",
                    "The.Office.S03E01.720p.mkv"
                ]
                
                for (index, fileName) in simulatedFiles.enumerated() {
                    try? await Task.sleep(nanoseconds: 300_000_000) // 300ms network delay
                    if Task.isCancelled { break }
                    
                    let parsedInfo = MivioGuessItParser.parse(fileName: fileName)
                    let simulatedPath = "smb://\(source.host ?? "nas.local")/\(fileName)"
                    
                    let item = MediaItem(
                        path: simulatedPath,
                        type: parsedInfo.type,
                        size: Int64(800 * 1024 * 1024 * (index + 1)),
                        fileName: fileName,
                        source: source
                    )
                    continuation.yield(item)
                }
                continuation.finish()
            }
        }
    }
}

// MARK: - WebDAV Media Scanner (Network Interface Skeleton)
public final class WebDAVMediaScanner: MediaScanner {
    private let supportedExtensions = ["mkv", "mp4", "avi", "mov", "webm"]
    
    public init() {}
    
    public func scan(source: Source) -> AsyncStream<MediaItem> {
        AsyncStream { continuation in
            Task(priority: .background) {
                // In full implementation, make async URLSession PROPFIND requests to crawl WebDAV directories.
                // We simulate discovering remote assets.
                
                let simulatedFiles = [
                    "Dune.Part.Two.2024.1080p.HEVC.mkv",
                    "Severance.S01E01.2160p.mp4"
                ]
                
                for (index, fileName) in simulatedFiles.enumerated() {
                    try? await Task.sleep(nanoseconds: 200_000_000) // 200ms network delay
                    if Task.isCancelled { break }
                    
                    let parsedInfo = MivioGuessItParser.parse(fileName: fileName)
                    let simulatedPath = "https://\(source.host ?? "dav.box.com")/webdav/\(fileName)"
                    
                    let item = MediaItem(
                        path: simulatedPath,
                        type: parsedInfo.type,
                        size: Int64(1200 * 1024 * 1024 * (index + 1)),
                        fileName: fileName,
                        source: source
                    )
                    continuation.yield(item)
                }
                continuation.finish()
            }
        }
    }
}
