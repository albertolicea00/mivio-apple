import Foundation
import SwiftData

// MARK: - Source Type
public enum SourceType: String, Codable, CaseIterable, Sendable {
    case local = "LOCAL"
    case smb = "SMB"
    case webdav = "WEBDAV"
}

// MARK: - Media Type
public enum MediaType: String, Codable, CaseIterable, Sendable {
    case movie = "MOVIE"
    case episode = "EPISODE"
}

// MARK: - Source Model
@Model
public final class Source {
    @Attribute(.unique) public var id: UUID
    public var typeString: String
    public var path: String
    public var host: String?
    public var username: String?
    public var passwordKey: String? // Key to store credentials securely in Keychain
    public var nickname: String
    
    @Relationship(deleteRule: .cascade, inverse: \MediaItem.source)
    public var mediaItems: [MediaItem]?
    
    public var type: SourceType {
        get { SourceType(rawValue: typeString) ?? .local }
        set { typeString = newValue.rawValue }
    }
    
    public init(id: UUID = UUID(), type: SourceType, path: String, host: String? = nil, username: String? = nil, passwordKey: String? = nil, nickname: String) {
        self.id = id
        self.typeString = type.rawValue
        self.path = path
        self.host = host
        self.username = username
        self.passwordKey = passwordKey
        self.nickname = nickname
        self.mediaItems = []
    }
}

// MARK: - MediaItem Model
@Model
public final class MediaItem {
    @Attribute(.unique) public var id: UUID
    public var path: String
    public var typeString: String
    public var size: Int64
    public var fileName: String
    public var addedAt: Date = Date()

    public var source: Source?

    @Relationship(deleteRule: .cascade, inverse: \Metadata.mediaItem)
    public var metadata: Metadata?

    @Relationship(deleteRule: .cascade, inverse: \WatchProgress.mediaItem)
    public var watchProgress: WatchProgress?

    public var type: MediaType {
        get { MediaType(rawValue: typeString) ?? .movie }
        set { typeString = newValue.rawValue }
    }

    public init(id: UUID = UUID(), path: String, type: MediaType, size: Int64, fileName: String, source: Source? = nil, addedAt: Date = Date()) {
        self.id = id
        self.path = path
        self.typeString = type.rawValue
        self.size = size
        self.fileName = fileName
        self.source = source
        self.addedAt = addedAt
    }
}

// MARK: - Metadata Model
@Model
public final class Metadata {
    public var tmdbId: Int?
    public var title: String
    public var year: Int?
    public var posterUrlString: String?
    public var backdropUrlString: String?
    public var synopsis: String
    public var rating: Double
    public var cast: [String]
    public var genres: [String] = []
    public var originalLanguage: String?

    public var mediaItem: MediaItem?

    /// Heuristic: TMDB doesn't have a dedicated "Anime" genre, so this combines the
    /// "Animation" genre with a Japanese original-language flag.
    public var isAnime: Bool {
        genres.contains("Animation") && originalLanguage == "ja"
    }

    public init(tmdbId: Int? = nil, title: String, year: Int? = nil, posterUrlString: String? = nil, backdropUrlString: String? = nil, synopsis: String = "", rating: Double = 0.0, cast: [String] = [], genres: [String] = [], originalLanguage: String? = nil) {
        self.tmdbId = tmdbId
        self.title = title
        self.year = year
        self.posterUrlString = posterUrlString
        self.backdropUrlString = backdropUrlString
        self.synopsis = synopsis
        self.rating = rating
        self.cast = cast
        self.genres = genres
        self.originalLanguage = originalLanguage
    }
}

// MARK: - WatchProgress Model
@Model
public final class WatchProgress {
    public var positionMs: Int64
    public var durationMs: Int64
    public var isWatched: Bool
    
    public var mediaItem: MediaItem?
    
    public init(positionMs: Int64 = 0, durationMs: Int64 = 0, isWatched: Bool = false) {
        self.positionMs = positionMs
        self.durationMs = durationMs
        self.isWatched = isWatched
    }
}
