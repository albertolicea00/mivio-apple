import Foundation

public struct ParsedMediaInfo: Equatable, Sendable {
    public let title: String
    public let year: Int?
    public let season: Int?
    public let episode: Int?
    public let resolution: String?
    public let codec: String?
    public let type: MediaType
}

public struct MivioGuessItParser {
    
    /// Parses a media file name to extract structural details such as title, year, season, episode, resolution, and codec.
    /// - Parameter fileName: The raw file name including extension.
    /// - Returns: A `ParsedMediaInfo` structure.
    public static func parse(fileName: String) -> ParsedMediaInfo {
        // Strip file extension
        let nameWithoutExtension = (fileName as NSString).deletingPathExtension
        
        var season: Int? = nil
        var episode: Int? = nil
        var detectedType: MediaType = .movie
        
        // 1. Check for Season & Episode (S01E02)
        if let match = try? Regex("s(\\d{1,2})e(\\d{1,2})").ignoresCase().firstMatch(in: nameWithoutExtension) {
            if let sRange = match[1].range, let eRange = match[2].range {
                season = Int(nameWithoutExtension[sRange])
                episode = Int(nameWithoutExtension[eRange])
                detectedType = .episode
            }
        } 
        // 2. Alternative Season & Episode (1x02)
        else if let match = try? Regex("(\\d{1,2})x(\\d{1,2})").ignoresCase().firstMatch(in: nameWithoutExtension) {
            if let sRange = match[1].range, let eRange = match[2].range {
                season = Int(nameWithoutExtension[sRange])
                episode = Int(nameWithoutExtension[eRange])
                detectedType = .episode
            }
        }
        
        // 3. Extract Resolution
        var resolution: String? = nil
        if let match = try? Regex("(2160p|1080p|720p|480p|4k|uhd)").ignoresCase().firstMatch(in: nameWithoutExtension) {
            let matchedStr = nameWithoutExtension[match.range].lowercased()
            if matchedStr == "uhd" || matchedStr == "4k" || matchedStr == "2160p" {
                resolution = "4K"
            } else {
                resolution = matchedStr.uppercased()
            }
        }
        
        // 4. Extract Codec
        var codec: String? = nil
        if let match = try? Regex("(h\\.?264|x264|h\\.?265|x265|hevc|av1|divx|xvid)").ignoresCase().firstMatch(in: nameWithoutExtension) {
            let matchedStr = nameWithoutExtension[match.range].lowercased()
            if matchedStr.contains("264") {
                codec = "H.264"
            } else if matchedStr.contains("265") || matchedStr == "hevc" {
                codec = "H.265"
            } else {
                codec = matchedStr.uppercased()
            }
        }
        
        // 5. Extract Year
        var year: Int? = nil
        if let match = try? Regex("(19\\d{2}|20\\d{2})").firstMatch(in: nameWithoutExtension) {
            if let yRange = match[1].range {
                year = Int(nameWithoutExtension[yRange])
            }
        }
        
        // 6. Deduce Title
        // The title is everything before the earliest marker (season/episode or year or resolution)
        var titleEndIndex = nameWithoutExtension.endIndex
        
        // Find earliest match index among SxxExx, xxXxx, Year, or Resolution
        let markers = [
            "s\\d{1,2}e\\d{1,2}",
            "\\d{1,2}x\\d{1,2}",
            "(19\\d{2}|20\\d{2})",
            "(2160p|1080p|720p|480p|4k|uhd)"
        ]
        
        for marker in markers {
            if let regex = try? Regex(marker).ignoresCase(), let match = try? regex.firstMatch(in: nameWithoutExtension) {
                if match.range.lowerBound < titleEndIndex {
                    titleEndIndex = match.range.lowerBound
                }
            }
        }
        
        var titleRaw = String(nameWithoutExtension[..<titleEndIndex])
        
        // Clean Title: replace dots, underscores, dashes with spaces
        titleRaw = titleRaw.replacingOccurrences(of: ".", with: " ")
        titleRaw = titleRaw.replacingOccurrences(of: "_", with: " ")
        titleRaw = titleRaw.replacingOccurrences(of: "-", with: " ")
        
        // Trim brackets, parentheses, and whitespaces
        let characterSet = CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: "[]()"))
        let cleanedTitle = titleRaw.trimmingCharacters(in: characterSet)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        
        return ParsedMediaInfo(
            title: cleanedTitle.isEmpty ? nameWithoutExtension : cleanedTitle,
            year: year,
            season: season,
            episode: episode,
            resolution: resolution,
            codec: codec,
            type: detectedType
        )
    }
}
