import Foundation

// MARK: - Home Section Kind

public enum HomeSectionKind: String, Codable, CaseIterable, Identifiable, Sendable {
    case recentlyAdded
    case movies
    case series
    case anime
    case topRated
    case byGenre
    case byYear

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .recentlyAdded: return "Recently Added"
        case .movies: return "Movies"
        case .series: return "Series"
        case .anime: return "Anime"
        case .topRated: return "Top Rated"
        case .byGenre: return "By Genre"
        case .byYear: return "By Year"
        }
    }

    public var icon: String {
        switch self {
        case .recentlyAdded: return "clock.fill"
        case .movies: return "film"
        case .series: return "tv"
        case .anime: return "sparkles.tv"
        case .topRated: return "star.fill"
        case .byGenre: return "tag.fill"
        case .byYear: return "calendar"
        }
    }
}

// MARK: - Home Section Config

public struct HomeSectionConfig: Codable, Identifiable, Equatable, Sendable {
    public var kind: HomeSectionKind
    public var isEnabled: Bool

    public var id: String { kind.id }

    public init(kind: HomeSectionKind, isEnabled: Bool = true) {
        self.kind = kind
        self.isEnabled = isEnabled
    }
}

// MARK: - Home Sections Store

/// Persists which Home screen sections are shown and in what order.
public final class HomeSectionsStore: ObservableObject {
    public static let shared = HomeSectionsStore()

    public static let defaultOrder: [HomeSectionKind] = [
        .recentlyAdded, .movies, .series, .anime, .topRated, .byGenre, .byYear
    ]

    private static let defaultsKey = "mivio.homeSections.v1"

    @Published public var sections: [HomeSectionConfig] {
        didSet { persist() }
    }

    private init() {
        if let data = UserDefaults.standard.data(forKey: Self.defaultsKey),
           let decoded = try? JSONDecoder().decode([HomeSectionConfig].self, from: data),
           !decoded.isEmpty {
            var merged = decoded
            let existingKinds = Set(decoded.map { $0.kind })
            for kind in Self.defaultOrder where !existingKinds.contains(kind) {
                merged.append(HomeSectionConfig(kind: kind))
            }
            self.sections = merged
        } else {
            self.sections = Self.defaultOrder.map { HomeSectionConfig(kind: $0) }
        }
    }

    public func resetToDefault() {
        sections = Self.defaultOrder.map { HomeSectionConfig(kind: $0) }
    }

    public func move(fromOffsets source: IndexSet, toOffset destination: Int) {
        var reordered = sections
        let moving = source.map { sections[$0] }
        for index in source.sorted(by: >) {
            reordered.remove(at: index)
        }
        let adjustedDestination = destination - source.filter { $0 < destination }.count
        reordered.insert(contentsOf: moving, at: adjustedDestination)
        sections = reordered
    }

    public func setEnabled(_ isEnabled: Bool, for kind: HomeSectionKind) {
        guard let index = sections.firstIndex(where: { $0.kind == kind }) else { return }
        sections[index].isEnabled = isEnabled
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(sections) else { return }
        UserDefaults.standard.set(data, forKey: Self.defaultsKey)
    }
}
