# 🍿 Mivio for Apple Ecosystem

[![Swift 6](https://img.shields.io/badge/Swift-6.0-orange.svg?style=flat-square&logo=swift)](https://swift.org)
[![SwiftUI](https://img.shields.io/badge/UI-SwiftUI-blue.svg?style=flat-square)](https://developer.apple.com/xcode/swiftui/)
[![SwiftData](https://img.shields.io/badge/Database-SwiftData-red.svg?style=flat-square)](https://developer.apple.com/documentation/swiftdata)
[![Platform Compatibility](https://img.shields.io/badge/Platforms-iOS%20%7C%20macOS%20%7C%20tvOS%20%7C%20visionOS-brightgreen.svg?style=flat-square)](#platform-specific-goals)
[![License: Non-Commercial](https://img.shields.io/badge/License-Non_Commercial-red.svg?style=flat-square)](LICENSE)

**Mivio** is a premium, high-performance media management and playback application meticulously designed for the unified Apple Ecosystem. Rewritten from the ground up to move beyond the traditional Android architecture, Mivio leverages modern Swift, SwiftUI, and SwiftData to deliver an elegant, fast, and native media cataloging and streaming experience across **iOS, macOS, visionOS, and tvOS**.

Whether scanning local folders on a Mac, connecting to high-speed home network shares via **SMB**, or streaming over a secure cloud-based **WebDAV** server, Mivio handles metadata collection, naming parsing, watch progress tracking, and media playback seamlessly.

---

## 🗺️ Architectural Blueprint: Android vs. Apple Ecosystem

Mivio has transitioned from a fragmented Kotlin/Jetpack library stack to a cohesive, type-safe, and highly performant Apple native stack:

| Feature / Capability | Android Stack | Apple Ecosystem (Unified Stack) |
| :--- | :--- | :--- |
| **Language** | Kotlin | **Swift 6** (Modern Swift with strict concurrency check) |
| **UI Framework** | Jetpack Compose (Material 3) | **SwiftUI** (Native Apple Human Interface Guidelines) |
| **Navigation** | Jetpack Navigation | SwiftUI Native Navigation (`NavigationStack`, `NavigationSplitView`) |
| **Database (ORM)** | Room (SQLite) | **SwiftData** (SQLite backing with CoreData power, native `@Model` macro) |
| **DI** | Dagger Hilt | Native Protocol-Oriented DI / SwiftUI `@Environment` |
| **Networking** | Retrofit2 + Gson | Native `URLSession` + `Async/Await` + `Codable` |
| **Image Loading** | Coil | **Kingfisher** (highly performant, disk & memory caching) |
| **Video Player** | Media3 ExoPlayer | **AVKit / AVPlayer** (native PIP, hardware acceleration, spatial visionOS) |
| **Async / Concurrency** | Coroutines & Flow | Swift Concurrency (`async/await`, `Actors`, `AsyncSequence`) |
| **Local Scanning** | `LocalMediaScannerImpl` | `FileManager` + native POSIX APIs |
| **SMB Integration** | `jcifs-ng` | **AMSMB2** (Swift/ObjC client built on high-performance `libsmb2`) |
| **WebDAV Integration**| `Sardine` (OkHttp) | Custom Async WebDAV Service (built on native `URLSession`) |
| **Media Parsing** | `GuessItParser` (Regex) | Custom **Swift Regex DSL** parser |

---

## 🎨 Platform Features & Limitations

Mivio is a single Xcode project with multiple targets, sharing a robust core for home server connections (Plex/Jellyfin/Emby), metadata management, and data models. However, the experience is tailored per platform:

### 📱 iOS & 💻 macOS
- ✅ **Local Multi-Account**: Each user saves their progress independently on the same device.
- ✅ **Local File Reading**: Full access to internal storage and local files.
- ✅ **Metadata Management**: Sort and display metadata (locally fetched or from the server).
- ✅ **Native Player**: Fully optimized playback using `AVPlayer`.

### 📺 tvOS
- ❌ **No Local Multi-Account**: Accounts are managed by the server.
- ❌ **No Local/USB Reading**: Operates exclusively as a streaming client.
- ✅ **Pure Server Client**: Designed exclusively to consume content from your home servers.
- ✅ **Native tvOS Player**: Hardware-accelerated decoding.

### 🥽 visionOS
- ❌ **No Local Multi-Account**: Accounts are managed by the server.
- ❌ **No Local/USB Reading**: Operates exclusively as a streaming client.
- ✅ **Home Server Client**: Stream your media directly to spatial windows.
- ✅ **Immersive Environments**: Downloadable USDZ/RealityKit immersive theaters.
- ✅ **Internal Marketplace**: Community-driven marketplace to upload and download 3D models and environments.
- ✅ **Native Spatial Player**: Integration of `AVPlayer` with RealityKit for a true spatial experience.

---

## 📂 Project Directory Structure

The project is designed with a **Swift Package-based Multiplatform architecture** to keep the core and user-interface modular, clean, and easily testable:

```text
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

---

## 🛠️ Key Components & Design Patterns

### 1. Unified Shared Data Models (`MivioCore/Models`)
Built using SwiftData's native `@Model` macro. Relationships cascade automatically to keep storage in sync:
- **`Source`**: Represents an endpoint. Enum `SourceType` (`local`, `smb`, `webdav`), containing hostnames, folder paths, and nickname tags.
- **`MediaItem`**: Represents a physical file. Handles size, filename, path, type (enum `MediaType`: `movie`/`episode`), and tracks relations to its metadata and watch progress.
- **`Metadata`**: Rich parsed metadata from the **TMDB API**, including synopsis, rating, cast list, year, and URLs for posters/backdrops.
- **`WatchProgress`**: Tracks microsecond playback details (`positionMs`, `durationMs`) and flags if the media is fully watched.

### 2. High-Performance GuessIt Parser (`MivioCore/Parser`)
A dedicated media scanner parser using modern **Swift Regex DSL** to instantly extract metadata from raw filenames:
```swift
// Example matching: "Inception.2010.1080p.BluRay.x264.mkv"
// Extracted Properties:
// - Title: "Inception"
// - Year: 2010
// - Resolution: "1080p"
// - Codec: "x264"
```

### 3. Media Scanning Services (`MivioCore/Scanner`)
- **Local Scanner**: Traverses directories asynchronously using standard POSIX and native `FileManager` streams.
- **SMB Scanner**: Leverages `AMSMB2` (wrapping the highly performant `libsmb2` C-library) to read directory tables on sandboxed platforms (iOS/tvOS/visionOS).
- **WebDAV Scanner**: Employs efficient HTTP request/response mechanisms via async/await `URLSession`.

### 4. Premium SwiftUI Design System (`MivioUI`)
Configured with **MivioTheme**, a highly refined visual specification utilizing tailored dark tones, micro-animations, and warm accents:
- `MivioTheme.background` (Dark sleek blue-black)
- `MivioTheme.cardBackground` (Deep obsidian)
- `MivioTheme.accent` (Elegant Gold)
- Dynamic spring transitions and responsive card hover states.

---

## 🚀 Getting Started

### Prerequisites
- A Mac running **macOS Sonoma (14.0) or later**.
- **Xcode 15.0 or later** (with Swift 5.9/6.0 toolchain).
- Simulator runtime components installed (iOS 17, tvOS 17, or visionOS 1).

### Setup and Running the Project
1. **Clone the Repository:**
   ```bash
   git clone https://github.com/albertolicea00/mivio-apple.git
   cd mivio-apple
   ```

2. **Open the Workspace in Xcode:**
   Double-click `Package.swift` to open it in Xcode as a Swift Package, or open the main `MivioAppleApp` project (which imports the Swift Package modules `MivioCore` and `MivioUI`).

3. **Fetch Dependencies:**
   Xcode will automatically fetch the third-party dependencies declared in `Package.swift`:
   - [Kingfisher](https://github.com/onevcat/Kingfisher.git) for image downloading and memory/disk caching.

4. **Select a Target Platform:**
   In the active scheme dropdown in Xcode, select your desired simulator or physical device (e.g., `MivioAppleApp (iOS Simulator)` or `MivioAppleApp (macOS)`).

5. **Run the Application:**
   Press `Cmd + R` to build and launch the application.

---

## 🧪 Running Automated Tests

To ensure the parsing engines, scanner crawlers, and SwiftData relationship models are working properly across all platforms, run the test suites:

- **Via Xcode:**
  Press `Cmd + U` to execute all unit tests.
- **Via Terminal (Swift Package Manager):**
  ```bash
  swift test
  ```

Test suites cover:
* **`MivioParserTests`**: Checks filename strings against the regex engine.
* **Database Relational Integrity**: Inserts mocked items and verifies Cascade deletes on watch history and metadata records.

---

## 🤝 Contribution Guidelines

We use a structured branch strategy to protect stable builds while supporting active feature implementation:
- **`main`**: Production-ready release branch.
- **`beta`**: Standard development target. **Always target your PRs to `beta`!**

For detailed instructions on commit formats, coding style guidelines, and platform-specific PR checks, please review [CONTRIBUTING.md](CONTRIBUTING.md).

For vulnerability reporting or security-related matters, see [SECURITY.md](SECURITY.md).

---

## 📄 License
This project is licensed under the **Mivio Source-Available End User License Agreement (EULA)**. Commercial use, monetization, and unauthorized redistribution are strictly prohibited. See the [LICENSE](LICENSE) file for details.
