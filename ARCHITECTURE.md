# Mivio iOS :: Architecture

**Last updated:** 2026-08-23 · **Doc version:** 1.1 · **Last commit documented:** `b12e162` (refactor: adjust HomeMediaRow layout for improved navigation link placement), plus uncommitted TMDB-key wiring described in §3.6/§4.6 below.

This document describes the codebase **as it actually exists today**, not the aspirational feature set in `README.md`. Where the two diverge (e.g. SMB/WebDAV scanning), that's called out explicitly.

---

## 1. Overview

Mivio is a Swift Package–based, multiplatform media manager/player targeting iOS, macOS, tvOS, and visionOS from a single codebase. It's an Xcode app target (`MivioAppleApp`) that consumes two local Swift Package libraries: `MivioCore` (data + business logic) and `MivioUI` (SwiftUI screens/components).

```
Package.swift          Unified SPM package definition
├── MivioCore           Business logic, SwiftData models, services (no UI deps)
├── MivioUI             SwiftUI views, depends on MivioCore + Kingfisher
Tests/
└── MivioCoreTests      Unit tests (parser only, currently)
MivioAppleApp/           Xcode app target (bootstraps the package)
├── Shared/MivioApp.swift
└── Resources/           Assets.xcassets, app icons per platform
```

Platforms declared in `Package.swift`: iOS 17+, macOS 14+, tvOS 17+, visionOS 1+. Nothing in the code currently branches business logic per platform beyond a handful of `#if os(...)` UI tweaks (tab bar appearance, hover states, layout column counts) — the tvOS/visionOS "server-only, no local files" restrictions described in the README are **not yet enforced in code**; `MivioFilesView`/local scanning run unconditionally on every platform target.

---

## 2. Tech stack (verified in code)

| Concern | What's actually used |
| :--- | :--- |
| Language | Swift 5.9 tools version (`Package.swift`); README claims Swift 6 strict concurrency — not enforced by any build setting in this package. |
| UI | SwiftUI, `NavigationStack` + typed `navigationDestination` |
| Persistence | SwiftData (`@Model`), single `ModelContainer` in `DatabaseManager`, on-disk (not in-memory), no CloudKit |
| Image loading | Kingfisher (`KFImage`) — the one third-party SPM dependency declared in `Package.swift` |
| Video playback | `AVKit`/`AVPlayer` always available. VLCKit (`vlckit-spm`, prebuilt XCFrameworks, pinned to 3.6.0) **is** a declared dependency in `Package.swift`, scoped via `.when(platforms: [.iOS, .macOS, .tvOS])` — so the `VLCPlayerView` branch (behind `#if canImport(VLCKitSPM)`) compiles in on those three platforms. visionOS has no upstream VLCKit build, so it always shows the dedicated "VLCKit Player Unavailable" fallback view regardless of the `"PlayerEngine"` setting. |
| Secrets | Keychain (`KeychainHelper`), Security framework, no third-party wrapper |
| Networking | Plain `URLSession` + `async/await` + `Codable`, no networking library |
| Local scanning | `FileManager` + `FileManager.enumerator`, no third-party |
| Remote scanning (SMB/WebDAV) | **Not implemented.** `SMBMediaScanner` and `WebDAVMediaScanner` exist as protocol-conforming stubs that yield a hardcoded list of fake filenames after an artificial `Task.sleep` delay — no `AMSMB2`, no real WebDAV client, no such dependency in `Package.swift`. |
| Preferences | `UserDefaults` (JSON-encoded), see `HomeSectionsStore` |

---

## 3. `MivioCore` — data & business logic

No UI imports; safe to unit test and reuse across app targets.

### 3.1 SwiftData models (`Models/MivioModels.swift`)

```
Source 1 ──< MediaItem 1 ──1 Metadata
                    │
                    └──1 WatchProgress
```

- **`Source`** — a media origin. `SourceType` enum: `local | smb | webdav` (stored as raw string, computed `type` property). Holds `host`/`username`/`passwordKey` for future remote auth (password itself lives in Keychain via `passwordKey`, not on the model). Cascade-deletes its `mediaItems`.
- **`MediaItem`** — one physical file: `path`, `size`, `fileName`, `addedAt`, `MediaType` (`movie | episode`). Cascade-owns one `Metadata` and one `WatchProgress`.
- **`Metadata`** — TMDB-sourced enrichment: title, year, poster/backdrop URL strings, synopsis, rating, cast, genres, `originalLanguage`. `isAnime` is a computed heuristic (`genres.contains("Animation") && originalLanguage == "ja"`) — TMDB has no dedicated Anime genre, so this is a best-effort proxy, not a guarantee.
- **`WatchProgress`** — `positionMs`/`durationMs`/`isWatched`. Nothing currently writes to this model outside its default initializer — playback position is not yet persisted anywhere in `MivioPlayerView`.

### 3.2 `DatabaseManager` (Database/)

`@MainActor` singleton wrapping a single `ModelContainer` for the four models above, on-disk, no CloudKit. `context` returns `container.mainContext`. This is the only place a `ModelContainer` is constructed; a failed init is a `fatalError`.

### 3.3 `LibraryManager` (Scanner/)

`@MainActor` singleton, one entry point: `syncLocalDocuments(context:)`, called once from `MivioApp.init`'s `.task` on launch, and again from `MivioHomeScreen`'s pull-to-refresh.

Flow:
1. Find (or create) the single `Source` of type `.local`, matched **by type, not path** — the sandbox container path changes across reinstalls, so path-matching would leave stale duplicates. Any extra duplicates found are deleted.
2. Run `LocalMediaScanner` over that source's path as an `AsyncStream<MediaItem>`, inserting only paths not already tracked.
3. For each newly inserted item, call `fetchMetadata(for:context:)`, which parses the filename (`MivioGuessItParser`) and hits `TMDBService`. On any TMDB failure it falls back to a bare `Metadata(title: parsed.title)` so the item still renders instead of being left metadata-less.

### 3.4 Scanners (`Scanner/MivioScanner.swift`)

Common `MediaScanner` protocol: `func scan(source:) -> AsyncStream<MediaItem>`.

- **`LocalMediaScanner`** — the only real implementation. Recursively enumerates a directory via `FileManager.enumerator`, filters to `mkv/mp4/avi/mov/webm`, streams a `MediaItem` per match.
- **`SMBMediaScanner`** / **`WebDAVMediaScanner`** — explicitly labeled "Network Interface Skeleton" in the source. Each yields a fixed, hardcoded array of fake filenames (e.g. `"Interstellar.2014.2160p.UHD.x265.mkv"`) with a sleep to simulate latency, and a synthesized `smb://`/`https://` path. **Nothing in `LibraryManager` currently invokes either of these** — they exist but are unwired.

### 3.5 `MivioGuessItParser` (Parser/)

Pure `static func parse(fileName:) -> ParsedMediaInfo`, no dependencies. Uses Swift's native `Regex` DSL (not a third-party GuessIt port despite the name) to extract, in order: season/episode (`SxxExx` or `xXxx`), resolution (`480p`–`2160p`/`4k`/`uhd` all normalize `2160p`→`"4K"`), codec (`x264`/`x265`/`hevc`/etc. normalize to `"H.264"`/`"H.265"`), year (`19xx`/`20xx`), and title (everything before the earliest of those markers, with `.`/`_`/`-` replaced by spaces). Covered by 4 unit tests in `MivioParserTests` — standard movie, standard `SxxExx` episode, alternate `NxNN` episode, and a title with literal spaces plus a year.

### 3.6 Services (`Services/`)

- **`KeychainHelper`** — thin `Security` framework wrapper storing exactly one secret today: `tmdbApiKey` (service `com.mivio.apikeys`, account `tmdb`). Generic-password `SecItemAdd`/`Update`/`Delete`, no biometric/access-control gating. The `tmdbApiKey` getter checks Keychain first (a user-supplied key from Settings) and, if none is stored, falls back to `Secrets.tmdbDefaultAPIKey` — a dev-supplied default baked in via an **untracked, gitignored** `Sources/MivioCore/Services/Secrets.swift` (template checked in as `Secrets.swift.example`; the repo is public, so this file is never committed with a real value). Anyone cloning fresh must copy the example and fill in a key, or set one from Settings, before metadata will resolve.
- **`TMDBService`** — `search/movie` or `search/tv` by parsed title (+ year, when known), then a details call with `append_to_response=credits` to also pull genres, original language, and top-5 cast. Takes the API key as a plain init argument — `LibraryManager` sources it from `KeychainHelper.shared.tmdbApiKey ?? ""`. With no default key configured and no user override set, that resolves to `""`, every search 404s, and every item falls back to bare metadata (no poster/backdrop/cast) — this is the #1 reason "posters never download" for a fresh checkout.
- **`OpenSubtitlesService`** — attempts a real GET against `api.opensubtitles.com`, but **discards the response entirely** ("Here is where standard OpenSubtitles JSON mapping occurs" — unimplemented) and always returns two hardcoded `SubtitleFile` entries pointing at `example.com` placeholder URLs. Not called from anywhere in `MivioUI` currently — no subtitle UI exists yet.

### 3.7 `HomeSectionsStore` (Preferences/)

`ObservableObject` singleton persisting which Home-screen sections are visible and in what order, JSON-encoded into `UserDefaults` under `mivio.homeSections.v1`. `HomeSectionKind` enum: `recentlyAdded, movies, series, anime, topRated, byGenre, byYear`. On load, merges any new kinds added since a user's last save onto the end of their existing order (so shipping a new section kind doesn't require a migration). Exposes `move(fromOffsets:toOffset:)` and `setEnabled(_:for:)` for a reorderable settings list.

---

## 4. `MivioUI` — SwiftUI layer

Depends on `MivioCore` + Kingfisher. Ships its own asset catalog (`BrandPrimary/Secondary/Tertiary` colorsets) bundled via SPM resources.

### 4.1 `MivioTheme` (Shared/Views.swift)

Central design-token enum: `background`/`cardBackground` map to system semantic colors per platform (`NSColor`/`UIColor`), `accent` = `brandPrimary` from the asset catalog, plus a `glassColor` constant. No dark/light-specific overrides beyond what the system colors already provide.

### 4.2 Navigation shell — `MivioMainTabView`

5-tab `TabView`: **Remote** (0) → **Files** (1) → **Home** (2, default selected) → **Search** (3) → **Settings** (4). iOS gets a custom opaque `UITabBarAppearance` matching `MivioTheme.background`.

- **`MivioRemoteView`** — placeholder screen only ("Connect to Jellyfin, Emby, and other services."); no actual remote-server client exists yet.
- **`MivioFilesView`** / **`MivioFileBrowserView`** / `FolderContentsView` — browses the local `Source`'s filesystem tree directly (not the SwiftData `MediaItem` list) via `FileManager.contentsOfDirectory`, cross-referencing each file against known `MediaItem`s by path to decide whether to link into `MivioDetailScreen` or show it as an unrecognized file.
- **`MivioSearchView`** — client-side, case-insensitive substring filter over all `MediaItem`s by title/filename; no debouncing, no server-side search.

### 4.3 `MivioHomeScreen`

`@Query`-driven over all `MediaItem`s. Renders one `HomeMediaRow` per **enabled** `HomeSectionConfig` from `HomeSectionsStore`, in the user's saved order. `.byGenre` is special-cased: instead of one row, it fans out into one `HomeMediaRow` per distinct genre string found across the library (alphabetical). Each row has a "See All" link to a `HomeSectionDetailScreen` grid (column count varies: 2 on iOS, 5 on macOS, 6 fixed-width on tvOS). Pull-to-refresh re-runs `LibraryManager.shared.syncLocalDocuments`. Empty state prompts to connect local/SMB/WebDAV sources — note SMB/WebDAV aren't actually connectable yet (§3.4).

### 4.4 `MivioDetailScreen`

Backdrop + poster (Kingfisher, blurred backdrop gradient), title/year/type/rating chips, "Watch Now" button presenting `MivioPlayerView` as a full-screen cover, synopsis, and a cast-name chip row (only rendered if cast is non-empty).

### 4.5 `MivioPlayerView`

Picks between two internal views based on the `"PlayerEngine"` `@AppStorage` value (shared with the Settings > Playback picker):
- **`NativeAVPlayerView`** — always available. Builds a file or `http` `AVPlayer` URL directly from `item.path`; sets `.playback` audio session category on iOS/tvOS so playback isn't silenced by the ringer switch. No scrubber persistence to `WatchProgress` yet.
- **`VLCPlayerView`** — compiles under `#if canImport(VLCKitSPM)` on iOS/macOS/tvOS (§2). On visionOS specifically there's a dedicated fallback view explaining "VLCKit has no build for this platform," shown unconditionally there.

### 4.6 `MivioSettingsView`

A 7-section `List`: Profile/Multi-Account → App Preferences (Appearance, **Home Sections** — wired to `HomeSectionsStore`, Privacy, Rescan Library) → Library & Sources (Add Files, Library, Sync, Metadata & Artwork, Collections) → Playback Experience (Playback, Audio, Video, Subtitles, Language→deep-links to OS Settings) → Network & Experimental (Casting, Network, Lab, Parental Control, Reset All Settings) → Support & Community (Help/Bug/Rate/Share/Follow/Donate) → About (version, developer).

Of these, **`HomeSectionsSettingsView` and the TMDB API Key field in `MetadataSettingsView`** are the only settings with real, persisted behavior. The TMDB key field is a `SecureField` seeded from `KeychainHelper.shared.tmdbApiKey`; "Save Key" writes the entered value back to Keychain (or clears it, falling back to the bundled default, when left blank), which then takes priority over the dev default on the next scan/metadata fetch. The rest (`AppearanceSettingsView`, `LibrarySettingsView`, `PlaybackSettingsView`, `CastingSettingsView`, etc.) are static/placeholder detail views — UI shells with no backing logic yet. "Rescan Library" and "Reset All Settings" buttons currently only toggle a confirmation `.alert`; the alert's primary action closures are empty (`Button("Scan", role: .none) { }`).

---

## 5. `MivioAppleApp` — app entry point

`MivioApp.swift`'s `init()` seeds a `"Place media here.txt"` file into the app's Documents directory on first launch — a convenience for testing local scanning in the simulator without needing Files-app drag-and-drop. On scene launch it injects `DatabaseManager.shared.container` as the environment's model container, applies the `"AppTheme"` `@AppStorage` preference (System/Light/Dark) as `preferredColorScheme`, and kicks off `LibraryManager.shared.syncLocalDocuments` in a `.task`.

---

## 6. Testing

`Tests/MivioCoreTests/MivioParserTests.swift` is the **only** test file in the repo — 4 tests, all against `MivioGuessItParser` (§3.5). There is currently no coverage for `DatabaseManager`, `LibraryManager`, `TMDBService`, `LocalMediaScanner`, or any SwiftUI view, despite the README's claim of "Database Relational Integrity" tests with cascade-delete verification — that test does not exist in this codebase yet.

---

## 7. Known gaps vs. README's stated architecture

The README (`README.md`) describes a more complete product than what's implemented. For anyone using it as a reference, the concrete deltas as of `b12e162`:

| README claims | Actual state |
| :--- | :--- |
| SMB integration via AMSMB2 | `SMBMediaScanner` returns hardcoded fake data; no AMSMB2 dependency |
| WebDAV via async URLSession | `WebDAVMediaScanner` returns hardcoded fake data; no PROPFIND logic |
| Swift 6 strict concurrency | `Package.swift` declares tools-version 5.9; no strict-concurrency build setting present |
| tvOS/visionOS restricted to server-only, no local files | No platform gating exists — `MivioFilesView`/local scan run identically everywhere |
| Cascade-delete integration tests | No such tests exist; only parser unit tests |
| OpenSubtitles integration | Network call is made but response is discarded; result is always two hardcoded placeholder URLs |

None of this is necessarily wrong to build toward — it's the intended shape — but treat the README as a **product spec**, and this document as the **as-built** reference.

**Setup note for new clones:** `Sources/MivioCore/Services/Secrets.swift` is gitignored and won't exist after `git clone`. Copy `Secrets.swift.example` to `Secrets.swift` in the same folder and either fill in a TMDB key there (bundled default, no user action needed) or leave it blank and set a key from **Settings > Metadata & Artwork > TMDB API Key** at runtime. Without one or the other, `MivioCore` still builds fine, but every metadata fetch 404s silently and items only ever show the filename-fallback card.
