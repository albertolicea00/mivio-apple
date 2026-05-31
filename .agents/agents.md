# Mivio Apple Ecosystem Agents Configuration

## Project Overview
Mivio for Apple Ecosystem is a premium, high-performance media management and playback application meticulously designed for the unified Apple Ecosystem (iOS, macOS, tvOS, visionOS). Built using Swift 6, SwiftUI, and SwiftData.

## Key Technologies
- Language: Swift 6 (Modern Swift with strict concurrency check)
- UI Framework: SwiftUI (Native Apple Human Interface Guidelines)
- Database (ORM): SwiftData (SQLite backing with CoreData power, native @Model macro)
- Dependency Injection: Native Protocol-Oriented DI / SwiftUI @Environment
- Networking: Native URLSession + Async/Await + Codable
- Image Loading: Kingfisher (highly performant, disk & memory caching)
- Video Player: AVKit / AVPlayer (native PIP, hardware acceleration, spatial visionOS)
- Async / Concurrency: Swift Concurrency (async/await, Actors, AsyncSequence)
- Local Scanning: FileManager + native POSIX APIs
- SMB Integration: AMSMB2 (Swift/ObjC client built on high-performance libsmb2)
- WebDAV Integration: Custom Async WebDAV Service (built on native URLSession)
- Media Parsing: Custom Swift Regex DSL parser

## Project Structure
```
mivio-apple/
├── Package.swift                     # Unified package definition for core modules
├── Sources/
│   ├── MivioCore/                    # Core Business Logic & Shared Data Layer
│   │   ├── Models/                   # SwiftData Models (MediaItem, Metadata, etc.)
│   │   │   └── MivioModels.swift     # Core SwiftData @Model declarations
│   │   ├── Database/                 # Database managers & schema definition
│   │   ├── Parser/                   # Swift Regex GuessIt parser
│   │   ├── Scanner/                  # Local, SMB, WebDAV directory crawlers
│   │   ├── Services/                 # TMDB and OpenSubtitles API clients
│   │   └── Storage/                  # Key-value configuration & user credentials
│   └── MivioUI/                      # Unified/Multiplatform SwiftUI UI components
│       └── Shared/                   # Multiplatform views (Details, Home grid items)
│           └── Views.swift           # MivioTheme design system, MediaItemCard, and Screens
├── Tests/
│   ├── MivioCoreTests/               # Unit tests for scanner, parser, and database
│   │   └── MivioParserTests.swift    # String matching and Regex correctness tests
└── MivioAppleApp/                    # Main Swift application bootstrapper (multiplatform)
    ├── Shared/                       # App Entry Point, DI container, & App Delegate
    ├── Resources/                    # Assets catalogs, icons, launch screens
    └── Info.plist
```

## Platform-Specific Features
### iOS & macOS
- Local Multi-Account: Each user saves progress independently
- Local File Reading: Full access to internal storage and local files
- Metadata Management: Sort and display metadata (locally fetched or from server)
- Native Player: Fully optimized playback using AVPlayer

### tvOS
- Pure Server Client: Designed exclusively to consume content from home servers
- Native tvOS Player: Hardware-accelerated decoding
- No Local Multi-Account or Local/USB Reading

### visionOS
- Home Server Client: Stream media directly to spatial windows
- Immersive Environments: Downloadable USDZ/RealityKit immersive theaters
- Internal Marketplace: Community-driven marketplace for 3D models and environments
- Native Spatial Player: Integration of AVPlayer with RealityKit
- No Local Multi-Account or Local/USB Reading

## Development Guidelines
- Target branch for PRs: `beta` (main is production-ready)
- Follow commit conventions outlined in CONTRIBUTING.md
- Prerequisites: macOS Sonoma (14.0) or later, Xcode 15.0 or later
- Test using Cmd+U in Xcode or `swift test` in terminal

## Agent Instructions
When working on this project:
1. Respect the Swift Package-based Multiplatform architecture
2. Use Swift idioms and best practices, especially Swift Concurrency
3. Follow SwiftUI guidelines for UI development
4. Leverage SwiftData's @Model macro for data persistence
5. Ensure proper error handling and edge case management
6. Write unit tests for core logic (parsing, scanning, database operations)
7. Update documentation when changing public APIs or significant functionality
8. Maintain platform-specific implementations where needed