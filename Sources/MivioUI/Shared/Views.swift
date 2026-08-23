import SwiftUI
import SwiftData
import Kingfisher
import AVKit
import MivioCore

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// MARK: - Premium Color System
public enum MivioTheme {
    #if os(macOS)
    public static let background = Color(nsColor: .windowBackgroundColor)
    public static let cardBackground = Color(nsColor: .controlBackgroundColor)
    #else
    public static let background = Color(uiColor: .systemBackground)
    public static let cardBackground = Color(uiColor: .secondarySystemBackground)
    #endif
    
    
    // Brand Colors (loaded from Assets.xcassets)
    public static let brandPrimary = Color("BrandPrimary", bundle: .module)
    public static let brandSecondary = Color("BrandSecondary", bundle: .module)
    public static let brandTertiary = Color("BrandTertiary", bundle: .module)
    
    public static let accent = brandPrimary
    public static let glassColor = Color.white.opacity(0.08)
}

// MARK: - Media Item Card (Shared)
public struct MediaItemCard: View {
    let item: MediaItem
    @State private var isHovered = false
    
    public init(item: MediaItem) {
        self.item = item
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                // TMDB Poster image cached via Kingfisher
                if let posterPath = item.metadata?.posterUrlString, let url = URL(string: posterPath) {
                    KFImage(url)
                        .placeholder {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(MivioTheme.cardBackground)
                                .overlay(ProgressView().tint(MivioTheme.accent))
                        }
                        .resizable()
                        .aspectRatio(3/4, contentMode: .fill)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    // Fallback placeholder card
                    RoundedRectangle(cornerRadius: 12)
                        .fill(LinearGradient(
                            colors: [MivioTheme.cardBackground, MivioTheme.background],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .aspectRatio(3/4, contentMode: .fit)
                        .overlay(
                            VStack(spacing: 12) {
                                Image(systemName: item.type == .movie ? "film" : "tv")
                                    .font(.system(size: 32))
                                    .foregroundStyle(MivioTheme.accent)
                                Text(item.fileName)
                                    .font(.caption2)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 8)
                                    .foregroundStyle(.secondary)
                            }
                        )
                }
                
                // Overlay Badge for HD/4K resolution
                if let resolution = item.fileName.contains("2160") || item.fileName.contains("4K") ? "4K" : "HD" {
                    Text(resolution)
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(MivioTheme.accent.opacity(0.85))
                        .foregroundStyle(.black)
                        .clipShape(Capsule())
                        .padding(8)
                }
            }
            .shadow(color: .black.opacity(isHovered ? 0.4 : 0.2), radius: isHovered ? 12 : 6, x: 0, y: 6)
            .scaleEffect(isHovered ? 1.04 : 1.0)
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isHovered)
            
            Text(item.metadata?.title ?? item.fileName)
                .font(.system(.subheadline, design: .rounded))
                .fontWeight(.semibold)
                .lineLimit(1)
                .foregroundStyle(.primary)
            
            if let year = item.metadata?.year {
                Text(String(year))
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
        #if os(macOS) || os(iOS)
        .onHover { hovering in
            isHovered = hovering
        }
        #endif
    }
}

// MARK: - Home Section Route

private struct HomeSectionRoute: Hashable {
    let title: String
    let items: [MediaItem]
}

// MARK: - Home Media Row (horizontal scroll)

private struct HomeMediaRow: View {
    let title: String
    let items: [MediaItem]

    private var cardWidth: CGFloat {
        #if os(tvOS)
        return 200
        #else
        return 130
        #endif
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            NavigationLink(value: HomeSectionRoute(title: title, items: items)) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(.system(.title3, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    Spacer()
                    Text("See All")
                        .font(.subheadline)
                        .foregroundStyle(MivioTheme.accent)
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(MivioTheme.accent)
                }
            }
            .buttonStyle(.plain)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 16) {
                    ForEach(items.prefix(20)) { item in
                        NavigationLink(value: item) {
                            MediaItemCard(item: item)
                                .frame(width: cardWidth)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 2)
                .padding(.vertical, 4)
            }
        }
    }
}

// MARK: - Home Section Detail (full grid)

private struct HomeSectionDetailScreen: View {
    let title: String
    let items: [MediaItem]

    private var columns: [GridItem] {
        #if os(tvOS)
        return Array(repeating: GridItem(.fixed(200), spacing: 24), count: 6)
        #elseif os(macOS)
        return Array(repeating: GridItem(.flexible(), spacing: 18), count: 5)
        #else
        return Array(repeating: GridItem(.flexible(), spacing: 12), count: 2)
        #endif
    }

    var body: some View {
        ZStack {
            MivioTheme.background.ignoresSafeArea()
            ScrollView {
                LazyVGrid(columns: columns, spacing: 24) {
                    ForEach(items) { item in
                        NavigationLink(value: item) {
                            MediaItemCard(item: item)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
            }
        }
        .navigationTitle(title)
    }
}

// MARK: - Premium Home Screen
public struct MivioHomeScreen: View {
    @Query private var mediaItems: [MediaItem]
    @ObservedObject private var sectionsStore = HomeSectionsStore.shared

    public init() {}

    private func items(for kind: HomeSectionKind) -> [MediaItem] {
        switch kind {
        case .recentlyAdded:
            return mediaItems.sorted { $0.addedAt > $1.addedAt }
        case .movies:
            return mediaItems.filter { $0.type == .movie }
        case .series:
            return mediaItems.filter { $0.type == .episode }
        case .anime:
            return mediaItems.filter { $0.metadata?.isAnime == true }
        case .topRated:
            return mediaItems
                .filter { ($0.metadata?.rating ?? 0) > 0 }
                .sorted { ($0.metadata?.rating ?? 0) > ($1.metadata?.rating ?? 0) }
        case .byYear:
            return mediaItems
                .filter { $0.metadata?.year != nil }
                .sorted { ($0.metadata?.year ?? 0) > ($1.metadata?.year ?? 0) }
        case .byGenre:
            return []
        }
    }

    /// Genre isn't a single row: fans out into one row per genre found in the library.
    private var genreGroups: [(genre: String, items: [MediaItem])] {
        var grouped: [String: [MediaItem]] = [:]
        for item in mediaItems {
            for genre in item.metadata?.genres ?? [] {
                grouped[genre, default: []].append(item)
            }
        }
        return grouped.keys.sorted().map { genre in (genre: genre, items: grouped[genre] ?? []) }
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                MivioTheme.background
                    .ignoresSafeArea()

                if mediaItems.isEmpty {
                    VStack(spacing: 16) {
                        Spacer(minLength: 80)
                        Image(systemName: "popcorn")
                            .font(.system(size: 60))
                            .foregroundStyle(MivioTheme.accent.opacity(0.7))
                        Text("No Media Discovered")
                            .font(.system(.headline, design: .rounded))
                            .foregroundStyle(.white)
                        Text("Connect local, SMB, or WebDAV folders in Sources to populate your library.")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                        Spacer(minLength: 80)
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 28) {
                            ForEach(sectionsStore.sections.filter(\.isEnabled)) { config in
                                if config.kind == .byGenre {
                                    ForEach(genreGroups, id: \.genre) { group in
                                        HomeMediaRow(title: group.genre, items: group.items)
                                    }
                                } else {
                                    let rowItems = items(for: config.kind)
                                    if !rowItems.isEmpty {
                                        HomeMediaRow(title: config.kind.title, items: rowItems)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 12)
                    }
                }
            }
            .navigationTitle("Mivio")
            .navigationDestination(for: MediaItem.self) { item in
                MivioDetailScreen(item: item)
            }
            .navigationDestination(for: HomeSectionRoute.self) { route in
                HomeSectionDetailScreen(title: route.title, items: route.items)
            }
            .refreshable {
                await LibraryManager.shared.syncLocalDocuments(context: mediaItems.first?.modelContext ?? DatabaseManager.shared.context)
            }
        }
    }
}

// MARK: - Premium Detail Screen
public struct MivioDetailScreen: View {
    let item: MediaItem
    @State private var showingPlayer = false
    
    public init(item: MediaItem) {
        self.item = item
    }
    
    public var body: some View {
        ZStack {
            MivioTheme.background
                .ignoresSafeArea()
            
            // Cached backdrop background with blur
            if let backdrop = item.metadata?.backdropUrlString, let url = URL(string: backdrop) {
                KFImage(url)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 450)
                    .overlay(
                        LinearGradient(
                            colors: [
                                .black.opacity(0.1),
                                MivioTheme.background
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .blur(radius: 4)
                    .ignoresSafeArea()
                    .opacity(0.4)
            }
            
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    Spacer(minLength: 180)
                    
                    HStack(alignment: .top, spacing: 28) {
                        // Poster image
                        if let posterPath = item.metadata?.posterUrlString, let url = URL(string: posterPath) {
                            KFImage(url)
                                .resizable()
                                .aspectRatio(3/4, contentMode: .fit)
                                .frame(width: 180)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .shadow(color: .black.opacity(0.4), radius: 12)
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            // Title & Year
                            Text(item.metadata?.title ?? item.fileName)
                                .font(.system(.largeTitle, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                            
                            HStack(spacing: 12) {
                                if let year = item.metadata?.year {
                                    Text(String(year))
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Text(item.type == .movie ? "Movie" : "Series")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.white.opacity(0.12))
                                    .clipShape(Capsule())
                                    .foregroundStyle(.secondary)
                                
                                if let rating = item.metadata?.rating, rating > 0 {
                                    HStack(spacing: 4) {
                                        Image(systemName: "star.fill")
                                            .font(.caption)
                                            .foregroundStyle(MivioTheme.accent)
                                        Text(String(format: "%.1f", rating))
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundStyle(.primary)
                                    }
                                }
                            }
                            
                            // Play Button (Translucent Glassmorphism)
                            Button {
                                showingPlayer = true
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "play.fill")
                                        .font(.body)
                                    Text("Watch Now")
                                        .fontWeight(.semibold)
                                }
                                .padding(.horizontal, 24)
                                .padding(.vertical, 14)
                                .background(MivioTheme.accent)
                                .foregroundStyle(.black)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .shadow(color: MivioTheme.accent.opacity(0.3), radius: 8, y: 4)
                            }
                            .buttonStyle(.plain)
                            .padding(.top, 12)
                        }
                    }
                    
                    // Movie Overview / Synopsis
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Overview")
                            .font(.system(.title3, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                        
                        Text(item.metadata?.synopsis ?? "No synopsis available for this media item.")
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(.secondary)
                            .lineSpacing(4)
                    }
                    
                    // Cast List
                    if let cast = item.metadata?.cast, !cast.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Featured Cast")
                                .font(.system(.title3, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                            
                            HStack(spacing: 12) {
                                ForEach(cast, id: \.self) { name in
                                    Text(name)
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(MivioTheme.cardBackground)
                                        .foregroundStyle(.primary)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
            }
        }
        .fullScreenCover(isPresented: $showingPlayer) {
            MivioPlayerView(item: item)
        }
    }
}

// MARK: - Main Tab Navigation
public struct MivioMainTabView: View {
    @State private var selectedTab = 2 // Start on Home
    
    public init() {}
    
    public var body: some View {
        TabView(selection: $selectedTab) {
            MivioRemoteView()
                .tabItem {
                    Label("Remote", systemImage: "network")
                }
                .tag(0)
            
            MivioFilesView()
                .tabItem {
                    Label("Files", systemImage: "folder.fill")
                }
                .tag(1)
            
            MivioHomeScreen()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(2)
            
            MivioSearchView()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .tag(3)
            
            MivioSettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(4)
        }
        .tint(MivioTheme.accent) // Apple Music uses an accent color for selected tabs
        // To ensure the TabBar blends well with dark mode:
        .onAppear {
            #if os(iOS)
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(MivioTheme.background)
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
            #endif
        }
    }
}

// MARK: - Files Browser

public struct FileSystemEntry: Identifiable, Hashable {
    public let id: String
    public let url: URL
    public let isDirectory: Bool

    public init(url: URL, isDirectory: Bool) {
        self.id = url.path
        self.url = url
        self.isDirectory = isDirectory
    }
}

public struct MivioFilesView: View {
    @Query private var sources: [MivioCore.Source]

    public init() {}

    private var localSource: MivioCore.Source? {
        sources.first { $0.type == .local }
    }

    public var body: some View {
        NavigationStack {
            Group {
                if let localSource {
                    FolderContentsView(directoryURL: URL(fileURLWithPath: localSource.path))
                } else {
                    ZStack {
                        MivioTheme.background.ignoresSafeArea()
                        VStack(spacing: 16) {
                            Image(systemName: "folder.fill")
                                .font(.system(size: 60))
                                .foregroundStyle(MivioTheme.accent.opacity(0.7))
                            Text("No Files Yet")
                                .font(.title2.bold())
                                .foregroundStyle(.white)
                            Text("Pull to refresh on Home to scan your local documents.")
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                    }
                }
            }
            .navigationTitle("Files")
            .navigationDestination(for: FileSystemEntry.self) { entry in
                MivioFileBrowserView(directoryURL: entry.url)
            }
            .navigationDestination(for: MediaItem.self) { item in
                MivioDetailScreen(item: item)
            }
        }
    }
}

public struct MivioFileBrowserView: View {
    let directoryURL: URL

    public init(directoryURL: URL) {
        self.directoryURL = directoryURL
    }

    public var body: some View {
        FolderContentsView(directoryURL: directoryURL)
            .navigationTitle(directoryURL.lastPathComponent)
    }
}

private struct FolderContentsView: View {
    let directoryURL: URL
    @Query private var mediaItems: [MediaItem]
    @State private var entries: [FileSystemEntry] = []
    @State private var loadFailed = false

    var body: some View {
        ZStack {
            MivioTheme.background.ignoresSafeArea()

            if loadFailed {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                    Text("Unable to browse this folder.")
                        .foregroundStyle(.secondary)
                }
            } else if entries.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "tray")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                    Text("This folder is empty.")
                        .foregroundStyle(.secondary)
                }
            } else {
                List(entries) { entry in
                    if entry.isDirectory {
                        NavigationLink(value: entry) {
                            Label(entry.url.lastPathComponent, systemImage: "folder.fill")
                        }
                    } else if let matchedItem = mediaItems.first(where: { $0.path == entry.url.path }) {
                        NavigationLink(value: matchedItem) {
                            Label(matchedItem.metadata?.title ?? entry.url.lastPathComponent, systemImage: matchedItem.type == .movie ? "film" : "tv")
                        }
                    } else {
                        Label(entry.url.lastPathComponent, systemImage: "film")
                            .foregroundStyle(.secondary)
                    }
                }
                .scrollContentBackground(.hidden)
            }
        }
        .task {
            loadEntries()
        }
    }

    private static let videoExtensions: Set<String> = ["mkv", "mp4", "avi", "mov", "webm"]

    private func loadEntries() {
        let fileManager = FileManager.default
        guard let contents = try? fileManager.contentsOfDirectory(
            at: directoryURL,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            loadFailed = true
            return
        }

        entries = contents
            .map { url -> FileSystemEntry in
                let isDirectory = (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
                return FileSystemEntry(url: url, isDirectory: isDirectory)
            }
            .filter { entry in
                entry.isDirectory || Self.videoExtensions.contains(entry.url.pathExtension.lowercased())
            }
            .sorted { lhs, rhs in
                if lhs.isDirectory != rhs.isDirectory {
                    return lhs.isDirectory
                }
                return lhs.url.lastPathComponent.localizedStandardCompare(rhs.url.lastPathComponent) == .orderedAscending
            }
    }
}

public struct MivioSearchView: View {
    @State private var searchText = ""
    @Query private var mediaItems: [MediaItem]
    
    public init() {}
    
    var filteredItems: [MediaItem] {
        if searchText.isEmpty {
            return mediaItems
        } else {
            return mediaItems.filter { item in
                let title = item.metadata?.title ?? item.fileName
                return title.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                MivioTheme.background.ignoresSafeArea()
                
                if filteredItems.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 60))
                            .foregroundStyle(MivioTheme.accent.opacity(0.7))
                        Text(searchText.isEmpty ? "Search Your Library" : "No Results")
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                        Text(searchText.isEmpty ? "Find movies and series you've added." : "Try a different spelling.")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 16)], spacing: 16) {
                            ForEach(filteredItems) { item in
                                NavigationLink(value: item) {
                                    MediaItemCard(item: item)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Search")
            .navigationDestination(for: MediaItem.self) { item in
                MivioDetailScreen(item: item)
            }
            .searchable(text: $searchText, prompt: "Search movies and series...")
        }
    }
}



public struct MivioRemoteView: View {
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                MivioTheme.background.ignoresSafeArea()
                VStack(spacing: 16) {
                    Image(systemName: "network")
                        .font(.system(size: 60))
                        .foregroundStyle(MivioTheme.accent.opacity(0.7))
                    Text("Remote")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                    Text("Connect to Jellyfin, Emby, and other services.")
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
            }
            .navigationTitle("Remote")
        }
    }
}
