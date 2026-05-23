import SwiftUI
import SwiftData
import Kingfisher
import AVKit
import MivioCore

// MARK: - Premium Color System
public enum MivioTheme {
    public static let background = Color(red: 0.05, green: 0.05, blue: 0.08)
    public static let cardBackground = Color(red: 0.11, green: 0.11, blue: 0.16)
    
    // Brand Colors
    public static let brandPrimary = Color(red: 241/255, green: 73/255, blue: 17/255) // #F14911
    public static let brandSecondary = Color(red: 249/255, green: 129/255, blue: 2/255) // #F98102
    public static let brandTertiary = Color(red: 254/255, green: 193/255, blue: 149/255) // #FEC195
    
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

// MARK: - Premium Home Screen
public struct MivioHomeScreen: View {
    @Query private var mediaItems: [MediaItem]
    
    // Adaptive Columns based on platform
    private var columns: [GridItem] {
        #if os(tvOS)
        return Array(repeating: GridItem(.fixed(200), spacing: 24), count: 6)
        #elseif os(macOS)
        return Array(repeating: GridItem(.flexible(), spacing: 18), count: 5)
        #else
        return Array(repeating: GridItem(.flexible(), spacing: 12), count: 2) // Mobile adaptive layout
        #endif
    }
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                MivioTheme.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Section Header
                        HStack {
                            Text("Your Library")
                                .font(.system(.title, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                            Spacer()
                        }
                        .padding(.top, 12)
                        
                        if mediaItems.isEmpty {
                            // Empty Library Display
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
                            // Gorgeous LazyGrid displaying content
                            LazyVGrid(columns: columns, spacing: 24) {
                                ForEach(mediaItems) { item in
                                    NavigationLink(value: item) {
                                        MediaItemCard(item: item)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }
            .navigationDestination(for: MediaItem.self) { item in
                MivioDetailScreen(item: item)
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
        #if os(macOS)
        .sheet(isPresented: $showingPlayer) {
            MivioPlayerView(videoUrl: URL(string: item.path) ?? URL(fileURLWithPath: item.path))
                .frame(minWidth: 800, minHeight: 450)
        }
        #else
        .fullScreenCover(isPresented: $showingPlayer) {
            MivioPlayerView(videoUrl: URL(string: item.path) ?? URL(fileURLWithPath: item.path))
        }
        #endif
    }
}

// MARK: - Premium Playback Screen (AVPlayer Native Wrapper)
public struct MivioPlayerView: View {
    let videoUrl: URL
    @Environment(\.dismiss) private var dismiss
    @State private var player: AVPlayer?
    
    public init(videoUrl: URL) {
        self.videoUrl = videoUrl
    }
    
    public var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            if let player = player {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
                    .onAppear {
                        player.play()
                    }
            } else {
                ProgressView("Buffering stream...")
                    .tint(.white)
                    .foregroundStyle(.white)
            }
            
            // Top Translucent Back Button Overlay
            VStack {
                HStack {
                    Button {
                        player?.pause()
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .bold))
                            .padding(12)
                            .background(.black.opacity(0.5))
                            .foregroundStyle(.white)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .padding(.leading, 20)
                    .padding(.top, 20)
                    Spacer()
                }
                Spacer()
            }
        }
        .onAppear {
            self.player = AVPlayer(url: videoUrl)
        }
        .onDisappear {
            self.player?.pause()
            self.player = nil
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

// MARK: - Placeholder Views

public struct MivioFilesView: View {
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                MivioTheme.background.ignoresSafeArea()
                VStack(spacing: 16) {
                    Image(systemName: "folder.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(MivioTheme.accent.opacity(0.7))
                    Text("Files")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                    Text("Browse local and cloud files here.")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Files")
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

public struct MivioSettingsView: View {
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                MivioTheme.background.ignoresSafeArea()
                VStack(spacing: 16) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(MivioTheme.accent.opacity(0.7))
                    Text("Settings")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                    Text("App preferences and account details.")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
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
