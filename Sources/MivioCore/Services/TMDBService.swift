import Foundation

public struct TmdbSearchResult: Codable, Sendable {
    public let id: Int
    public let title: String?
    public let name: String? // For TV shows
    public let overview: String?
    public let posterPath: String?
    public let backdropPath: String?
    public let voteAverage: Double?
    public let releaseDate: String?
    public let firstAirDate: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case name
        case overview
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case voteAverage = "vote_average"
        case releaseDate = "release_date"
        case firstAirDate = "first_air_date"
    }
}

public struct TmdbSearchResponse: Codable, Sendable {
    public let results: [TmdbSearchResult]
}

public struct TmdbCastMember: Codable, Sendable {
    public let name: String
}

public struct TmdbCreditsResponse: Codable, Sendable {
    public let cast: [TmdbCastMember]
}

public final class TMDBService: Sendable {
    private let apiKey: String
    private let session: URLSession
    
    public init(apiKey: String, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
    }
    
    /// Fetches TMDB metadata for parsed media item information.
    /// - Parameter parsedInfo: Struct parsed from filename.
    /// - Returns: A SwiftData `Metadata` instance populated with TMDB descriptions, posters, and cast.
    public func fetchMetadata(for parsedInfo: ParsedMediaInfo) async throws -> Metadata {
        let query = parsedInfo.title
        let type = parsedInfo.type
        
        let path = type == .movie ? "search/movie" : "search/tv"
        var components = URLComponents(string: "https://api.themoviedb.org/3/\(path)")!
        
        var queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "query", value: query)
        ]
        
        if let year = parsedInfo.year {
            let yearKey = type == .movie ? "year" : "first_air_date_year"
            queryItems.append(URLQueryItem(name: yearKey, value: String(year)))
        }
        
        components.queryItems = queryItems
        
        guard let url = components.url else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await session.data(from: url)
        let searchResponse = try JSONDecoder().decode(TmdbSearchResponse.self, from: data)
        
        guard let firstResult = searchResponse.results.first else {
            throw NSError(domain: "TMDBService", code: 404, userInfo: [NSLocalizedDescriptionKey: "No TMDB results found for query: \(query)"])
        }
        
        // Fetch credits (cast list)
        let creditsPath = type == .movie ? "movie/\(firstResult.id)/credits" : "tv/\(firstResult.id)/credits"
        var creditsComponents = URLComponents(string: "https://api.themoviedb.org/3/\(creditsPath)")!
        creditsComponents.queryItems = [URLQueryItem(name: "api_key", value: apiKey)]
        
        var castList: [String] = []
        if let creditsUrl = creditsComponents.url {
            do {
                let (creditsData, _) = try await session.data(from: creditsUrl)
                let creditsResponse = try JSONDecoder().decode(TmdbCreditsResponse.self, from: creditsData)
                castList = Array(creditsResponse.cast.prefix(5).map { $0.name })
            } catch {
                // Credits are optional, don't let credit errors block metadata
            }
        }
        
        let posterUrl = firstResult.posterPath.map { "https://image.tmdb.org/t/p/w500\($0)" }
        let backdropUrl = firstResult.backdropPath.map { "https://image.tmdb.org/t/p/w1280\($0)" }
        
        let title = type == .movie ? (firstResult.title ?? query) : (firstResult.name ?? query)
        var releaseYear = parsedInfo.year
        if releaseYear == nil {
            if let dateStr = firstResult.releaseDate, let prefixStr = dateStr.split(separator: "-").first {
                releaseYear = Int(prefixStr)
            } else if let dateStr = firstResult.firstAirDate, let prefixStr = dateStr.split(separator: "-").first {
                releaseYear = Int(prefixStr)
            }
        }
        
        return Metadata(
            tmdbId: firstResult.id,
            title: title,
            year: releaseYear,
            posterUrlString: posterUrl,
            backdropUrlString: backdropUrl,
            synopsis: firstResult.overview ?? "",
            rating: firstResult.voteAverage ?? 0.0,
            cast: castList
        )
    }
}
