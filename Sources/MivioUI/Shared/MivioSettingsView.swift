import SwiftUI
import MivioCore

public struct MivioSettingsView: View {
    public init() {}
    
    // Fetch app version
    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
    
    @State private var showingRescanAlert = false
    @State private var showingResetAlert = false
    
    public var body: some View {
        NavigationStack {
            List {
                // Section 1: Top Profile Card (Multi-Accounts)
                Section {
                    NavigationLink(destination: MultiAccountSettingsView()) {
                        HStack(spacing: 16) {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 60))
                                .foregroundStyle(MivioTheme.accent.opacity(0.8), MivioTheme.cardBackground)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Default Profile")
                                    .font(.title3.bold())
                                    .foregroundStyle(.primary)
                                Text("Manage Accounts")
                                    .font(.subheadline)
                                    .foregroundStyle(MivioTheme.accent)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                // Section 2: App Preferences
                Section(header: Text("App Preferences")) {
                    SettingsRow(icon: "paintpalette.fill", color: .indigo, title: "Appearance", destination: AnyView(AppearanceSettingsView()))
                    SettingsRow(icon: "square.grid.2x2.fill", color: .purple, title: "Home Sections", destination: AnyView(HomeSectionsSettingsView()))
                    SettingsRow(icon: "hand.raised.fill", color: .blue, title: "Privacy", destination: AnyView(PrivacySettingsView()))
                    
                    Button {
                        showingRescanAlert = true
                    } label: {
                        HStack(spacing: 16) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(MivioTheme.accent)
                                    .frame(width: 30, height: 30)
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                            Text("Rescan Library")
                                .foregroundStyle(.primary)
                        }
                        .padding(.vertical, 2)
                    }
                    .buttonStyle(.plain)
                    .alert("Rescan Library", isPresented: $showingRescanAlert) {
                        Button("Scan", role: .none) { }
                        Button("Cancel", role: .cancel) { }
                    } message: {
                        Text("This will look for new files and update metadata.")
                    }
                }
                
                // Section 3: Library & Sources
                Section(header: Text("Library & Sources")) {
                    SettingsRow(icon: "plus.circle.fill", color: MivioTheme.accent, title: "Add Files", destination: AnyView(SettingsDetailPlaceholder(title: "Add Files")))
                    SettingsRow(icon: "books.vertical.fill", color: .teal, title: "Library", destination: AnyView(LibrarySettingsView()))
                    SettingsRow(icon: "arrow.triangle.2.circlepath", color: .green, title: "Sync", destination: AnyView(SyncSettingsView()))
                    SettingsRow(icon: "photo.artframe", color: .pink, title: "Metadata & Artwork", destination: AnyView(MetadataSettingsView()))
                    SettingsRow(icon: "rectangle.stack.fill", color: .orange, title: "Collection & Groups", destination: AnyView(CollectionsSettingsView()))
                }
                
                // Section 4: Playback Experience
                Section(header: Text("Playback Experience")) {
                    SettingsRow(icon: "play.circle.fill", color: .red, title: "Playback", destination: AnyView(PlaybackSettingsView()))
                    SettingsRow(icon: "speaker.wave.2.fill", color: .cyan, title: "Audio", destination: AnyView(AudioSettingsView()))
                    SettingsRow(icon: "tv.fill", color: .blue, title: "Video", destination: AnyView(VideoSettingsView()))
                    SettingsRow(icon: "captions.bubble.fill", color: .yellow, title: "Subtitles", destination: AnyView(SubtitleSettingsView()))
                    
                    // Language opens OS settings directly
                    Button {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        HStack(spacing: 16) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.teal)
                                    .frame(width: 30, height: 30)
                                Image(systemName: "globe")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.white)
                            }
                            Text("Language")
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                    .buttonStyle(.plain)
                }
                
                // Section 5: Network & Experimental
                Section(header: Text("Network & Experimental")) {
                    SettingsRow(icon: "airplayvideo", color: .indigo, title: "Casting", destination: AnyView(CastingSettingsView()))
                    SettingsRow(icon: "network", color: .gray, title: "Network", destination: AnyView(NetworkSettingsView()))
                    SettingsRow(icon: "flask.fill", color: .mint, title: "Lab", destination: AnyView(LabSettingsView()))
                    SettingsRow(icon: "figure.child", color: .orange, title: "Parental Control", destination: AnyView(ParentalControlSettingsView()))
                    
                    Button(role: .destructive) {
                        showingResetAlert = true
                    } label: {
                        HStack(spacing: 16) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.red)
                                    .frame(width: 30, height: 30)
                                Image(systemName: "arrow.uturn.backward")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                            Text("Reset All Settings")
                                .foregroundStyle(.red)
                        }
                        .padding(.vertical, 2)
                    }
                    .buttonStyle(.plain)
                    .alert("Reset Settings", isPresented: $showingResetAlert) {
                        Button("Reset", role: .destructive) { }
                        Button("Cancel", role: .cancel) { }
                    } message: {
                        Text("This will restore all default preferences. Your library will not be affected.")
                    }
                }
                
                // Section 6: Support & Community
                Section(header: Text("Support & Community")) {
                    LinkRow(icon: "questionmark.circle.fill", color: .indigo, title: "Help Center", url: "https://mivio.app/help")
                    SettingsRow(icon: "ladybug.fill", color: .red, title: "Report a Bug", destination: AnyView(ReportBugView()))
                    LinkRow(icon: "star.fill", color: .yellow, title: "Rate Mivio", url: "https://apps.apple.com/app/id123456789")
                    ShareRow(icon: "person.2.wave.2.fill", color: .blue, title: "Tell a Friend", url: "https://mivio.app")
                    SettingsRow(icon: "bird.fill", color: .cyan, title: "Follow Us", destination: AnyView(FollowUsView()))
                    SettingsRow(icon: "heart.fill", color: .pink, title: "Make a Donation", destination: AnyView(SettingsDetailPlaceholder(title: "Donation")))
                }
                
                // Section 7: About
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("\(appVersion)")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Developer")
                        Spacer()
                        Text("Alberto Licea")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            #if os(iOS)
            .listStyle(.insetGrouped)
            #endif
            .scrollContentBackground(.hidden)
            .background(MivioTheme.background.ignoresSafeArea())
        }
    }
}

// MARK: - Row Helpers

struct SettingsRow: View {
    let icon: String
    let color: Color
    let title: String
    let destination: AnyView
    
    var body: some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(color)
                        .frame(width: 30, height: 30)
                    
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                }
                Text(title)
                    .foregroundStyle(.primary)
            }
            .padding(.vertical, 2)
        }
    }
}

struct LinkRow: View {
    let icon: String
    let color: Color
    let title: String
    let url: String
    
    var body: some View {
        Button {
            if let link = URL(string: url) {
                #if os(macOS)
                NSWorkspace.shared.open(link)
                #else
                UIApplication.shared.open(link)
                #endif
            }
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(color)
                        .frame(width: 30, height: 30)
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                }
                Text(title)
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 2)
        }
        .buttonStyle(.plain)
    }
}

struct ShareRow: View {
    let icon: String
    let color: Color
    let title: String
    let url: String
    
    var body: some View {
        ShareLink(item: URL(string: url)!, message: Text("Check out Mivio, the ultimate media player!")) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(color)
                        .frame(width: 30, height: 30)
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                }
                Text(title)
                    .foregroundStyle(.primary)
            }
            .padding(.vertical, 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - App Preferences Views

struct AppearanceSettingsView: View {
    @AppStorage("AppTheme") private var appTheme = "System"
    @AppStorage("ShowProfilesHome") private var showProfilesHome = true
    @AppStorage("AppLayout") private var appLayout = "Modern"
    @State private var customAccentColor = MivioTheme.accent
    
    var body: some View {
        Form {
            Section(header: Text("Theme")) {
                Picker("Theme", selection: $appTheme) {
                    Text("System").tag("System")
                    Text("Light").tag("Light")
                    Text("Dark").tag("Dark")
                }
            }
            
            Section(header: Text("Home Layout")) {
                Picker("Layout Style", selection: $appLayout) {
                    Text("Modern").tag("Modern")
                    Text("Classic").tag("Classic")
                    Text("Compact").tag("Compact")
                }
                Toggle("Show Profiles in Home", isOn: $showProfilesHome)
            }
            
            Section(header: Text("Accent Color"), footer: Text("Changes the primary color of buttons and highlights.")) {
                ColorPicker("Primary Color", selection: $customAccentColor)
            }
        }
        .navigationTitle("Appearance")
    }
}

struct HomeSectionsSettingsView: View {
    @ObservedObject private var sectionsStore = HomeSectionsStore.shared
    @State private var showingResetAlert = false

    var body: some View {
        List {
            Section(header: Text("Sections"), footer: Text("Toggle which sections appear on Home, and drag to reorder them.")) {
                ForEach(sectionsStore.sections) { config in
                    HStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(MivioTheme.accent)
                                .frame(width: 30, height: 30)
                            Image(systemName: config.kind.icon)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                        Text(config.kind.title)
                            .foregroundStyle(.primary)
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { config.isEnabled },
                            set: { sectionsStore.setEnabled($0, for: config.kind) }
                        ))
                        .labelsHidden()
                    }
                    .padding(.vertical, 2)
                }
                .onMove { source, destination in
                    sectionsStore.move(fromOffsets: source, toOffset: destination)
                }
            }

            Section {
                Button("Reset to Default Order") {
                    showingResetAlert = true
                }
                .foregroundStyle(MivioTheme.accent)
                .alert("Reset Home Sections", isPresented: $showingResetAlert) {
                    Button("Reset", role: .destructive) { sectionsStore.resetToDefault() }
                    Button("Cancel", role: .cancel) { }
                } message: {
                    Text("This restores the default sections, order, and visibility.")
                }
            }
        }
        .navigationTitle("Home Sections")
        #if os(iOS) || os(tvOS)
        .toolbar { EditButton() }
        #endif
    }
}

struct PrivacySettingsView: View {
    @AppStorage("DisableFilesFinder") private var disableFinder = false
    @AppStorage("ShareAnalytics") private var shareAnalytics = false
    @AppStorage("SendCrashReports") private var sendCrashReports = false
    
    var body: some View {
        Form {
            Section(header: Text("App Permissions"), footer: Text("Mivio requires access to your local network and files to function properly. You can manage these in iOS Settings.")) {
                Button("Manage OS Permissions") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .foregroundStyle(MivioTheme.accent)
            }
            Section(header: Text("File Visibility")) {
                Toggle("Hide from Files App & Finder", isOn: $disableFinder)
            }
            Section(header: Text("Diagnostics")) {
                Toggle("Share Analytics", isOn: $shareAnalytics)
                Toggle("Send Crash Reports", isOn: $sendCrashReports)
            }
        }
        .navigationTitle("Privacy")
    }
}

// MARK: - Library & Sources Views

struct LibrarySettingsView: View {
    @AppStorage("ScanOnStartup") private var scanOnStartup = true
    @AppStorage("MonitorFolders") private var monitorFolders = true
    
    var body: some View {
        Form {
            Section {
                Toggle("Scan Library on Startup", isOn: $scanOnStartup)
                Toggle("Monitor Folders for Changes", isOn: $monitorFolders)
            }
        }
        .navigationTitle("Library")
    }
}

struct SyncSettingsView: View {
    @AppStorage("EnableiCloudSync") private var enableiCloudSync = true
    @AppStorage("SyncWatchProgress") private var syncWatchProgress = true
    @State private var isTraktConnected = false
    
    var body: some View {
        Form {
            Section(footer: Text("Sync your metadata, watch history, and library settings across all your Apple devices using iCloud.")) {
                Toggle("iCloud Sync", isOn: $enableiCloudSync)
                Toggle("Sync Watch Progress", isOn: $syncWatchProgress)
            }
            
            Section(header: Text("Trakt.tv"), footer: Text("Automatically scrobble what you're watching and sync your watch history.")) {
                if isTraktConnected {
                    HStack {
                        Text("Connected Account")
                        Spacer()
                        Text("albertolicea00")
                            .foregroundStyle(.secondary)
                    }
                    Button("Disconnect Trakt") {
                        isTraktConnected = false
                    }
                    .foregroundStyle(.red)
                } else {
                    Button("Sign In to Trakt") {
                        // Action to authenticate with Trakt
                        isTraktConnected = true
                    }
                    .foregroundStyle(MivioTheme.accent)
                }
            }
        }
        .navigationTitle("Sync")
    }
}

struct CollectionsSettingsView: View {
    @AppStorage("GroupCollections") private var groupCollections = true
    @AppStorage("ShowEmptyCollections") private var showEmptyCollections = false
    
    var body: some View {
        Form {
            Section {
                Toggle("Group Movies into Collections", isOn: $groupCollections)
                Toggle("Show Empty Collections", isOn: $showEmptyCollections)
            }
        }
        .navigationTitle("Collections")
    }
}

struct MetadataSettingsView: View {
    @AppStorage("ScraperSource") private var scraperSource = "TMDB"
    @State private var customRegexes: [String] = ["^(.*?)\\.[S]?([0-9]+)[E|x]([0-9]+)"]
    
    var body: some View {
        Form {
            Section(header: Text("Scraper Source")) {
                Picker("Primary Source", selection: $scraperSource) {
                    Text("TheMovieDB (TMDB)").tag("TMDB")
                    Text("TheTVDB").tag("TVDB")
                    Text("Local NFO Only").tag("Local")
                }
            }
            Section(header: Text("Custom Regex Parsing"), footer: Text("Add custom regular expressions to help Mivio extract TV Show names, seasons, and episodes from complex file names.")) {
                ForEach(customRegexes, id: \.self) { regex in
                    Text(regex)
                        .font(.system(.footnote, design: .monospaced))
                }
                .onDelete { indexSet in
                    customRegexes.remove(atOffsets: indexSet)
                }
                Button("Add Regex Pattern...") {
                    // Action to add regex
                }
                .foregroundStyle(MivioTheme.accent)
            }
        }
        .navigationTitle("Metadata & Artwork")
    }
}

// MARK: - Playback Experience Views

struct PlaybackSettingsView: View {
    @AppStorage("PlayerEngine") private var playerEngine = "VLC"
    @AppStorage("EnablePiP") private var enablePiP = true
    @AppStorage("BackgroundAudio") private var backgroundAudio = false
    
    var body: some View {
        Form {
            Section(header: Text("Engine"), footer: Text("The Integrated VLC engine supports more formats (MKV, AVI) while Native is better optimized for battery life.")) {
                Picker("Player Engine", selection: $playerEngine) {
                    Text("Integrated (VLC)").tag("VLC")
                    Text("Native (AVPlayer)").tag("Native")
                }
            }
            Section(header: Text("Features")) {
                Toggle("Allow Picture-in-Picture (PiP)", isOn: $enablePiP)
                Toggle("Background Audio", isOn: $backgroundAudio)
            }
        }
        .navigationTitle("Playback")
    }
}

struct AudioSettingsView: View {
    @AppStorage("AudioPassthrough") private var audioPassthrough = false
    @AppStorage("NormalizeAudio") private var normalizeAudio = true
    @AppStorage("VolumeBoost") private var volumeBoost = false
    
    var body: some View {
        Form {
            Section {
                Toggle("Audio Passthrough (VLC)", isOn: $audioPassthrough)
                Toggle("Normalize Audio", isOn: $normalizeAudio)
                Toggle("Volume Boost (Over 100%)", isOn: $volumeBoost)
            }
        }
        .navigationTitle("Audio")
    }
}

struct VideoSettingsView: View {
    @AppStorage("VLCHardwareDecoding") private var hardwareDecoding = true
    @AppStorage("MatchFrameRate") private var matchFrameRate = true
    @AppStorage("DeinterlacingMode") private var deinterlacingMode = "Auto"
    
    var body: some View {
        Form {
            Section(header: Text("Hardware & Processing")) {
                Toggle("Hardware Decoding", isOn: $hardwareDecoding)
                Toggle("Match Frame Rate", isOn: $matchFrameRate)
            }
            Section(header: Text("Deinterlacing (VLC)")) {
                Picker("Deinterlacing Mode", selection: $deinterlacingMode) {
                    Text("Auto").tag("Auto")
                    Text("On").tag("On")
                    Text("Off").tag("Off")
                }
            }
        }
        .navigationTitle("Video")
    }
}

struct SubtitleSettingsView: View {
    @AppStorage("SubtitleSource") private var subtitleSource = "OpenSubtitles"
    @AppStorage("AutoDownloadSubtitles") private var autoDownload = false
    @AppStorage("BurnInSubtitles") private var burnIn = false
    
    var body: some View {
        Form {
            Section(header: Text("Download Provider")) {
                Picker("Subtitle Source", selection: $subtitleSource) {
                    Text("OpenSubtitles.org").tag("OpenSubtitles")
                    Text("Subscene").tag("Subscene")
                    Text("Addic7ed").tag("Addic7ed")
                }
            }
            Section {
                Toggle("Auto-download Subtitles", isOn: $autoDownload)
                Toggle("Burn-in Subtitles (VLC)", isOn: $burnIn)
            }
        }
        .navigationTitle("Subtitles")
    }
}

// MARK: - Network & Experimental Views

struct CastingSettingsView: View {
    @AppStorage("EnableAirPlay") private var enableAirPlay = true
    @AppStorage("EnableGoogleCast") private var enableGoogleCast = false
    
    var body: some View {
        Form {
            Section(footer: Text("Enable discovery for casting devices on your local network.")) {
                Toggle("Enable AirPlay", isOn: $enableAirPlay)
                Toggle("Enable Google Cast", isOn: $enableGoogleCast)
            }
        }
        .navigationTitle("Casting")
    }
}

struct NetworkSettingsView: View {
    @AppStorage("StreamOverCellular") private var streamOverCellular = false
    @AppStorage("DownloadOverCellular") private var downloadOverCellular = false
    @AppStorage("NetworkCaching") private var networkCaching = "Normal"
    
    var body: some View {
        Form {
            Section(header: Text("Cellular Data")) {
                Toggle("Stream over Cellular", isOn: $streamOverCellular)
                Toggle("Download over Cellular", isOn: $downloadOverCellular)
            }
            Section(header: Text("VLC Network Caching"), footer: Text("Increase this if you experience buffering on remote streams.")) {
                Picker("Caching Level", selection: $networkCaching) {
                    Text("Lowest (Local)").tag("Lowest")
                    Text("Normal").tag("Normal")
                    Text("High (Remote)").tag("High")
                }
            }
        }
        .navigationTitle("Network")
    }
}

struct LabSettingsView: View {
    @AppStorage("VerboseLogging") private var verboseLogging = false
    @AppStorage("BetaFeatures") private var betaFeatures = false
    @AppStorage("ShowSiriShortcuts") private var showSiri = true
    
    @State private var showingDumpAlert = false
    
    var body: some View {
        Form {
            Section(header: Text("Experimental"), footer: Text("These features are in development and may cause instability.")) {
                Toggle("Enable Beta Features", isOn: $betaFeatures)
                Toggle("Enable Siri Shortcuts", isOn: $showSiri)
            }
            
            Section(header: Text("Developer Tools")) {
                Toggle("Verbose Logging", isOn: $verboseLogging)
                
                Button("Save Debug Log to Device") {
                    // Action
                }
                .foregroundStyle(MivioTheme.accent)
                
                Button("Dump Media Library") {
                    showingDumpAlert = true
                }
                .foregroundStyle(.red)
                .alert("Dump Media Library", isPresented: $showingDumpAlert) {
                    Button("Dump", role: .destructive) { }
                    Button("Cancel", role: .cancel) { }
                } message: {
                    Text("This will export your entire library database to a JSON file.")
                }
            }
        }
        .navigationTitle("Lab")
    }
}

struct ParentalControlSettingsView: View {
    @AppStorage("EnablePasscode") private var enablePasscode = false
    
    var body: some View {
        Form {
            Section(footer: Text("Require a passcode to open Mivio.")) {
                Toggle("Enable Passcode Lock", isOn: $enablePasscode)
                if enablePasscode {
                    Button("Change Passcode") {
                        // Action
                    }
                    .foregroundStyle(MivioTheme.accent)
                }
            }
        }
        .navigationTitle("Parental Control")
    }
}

struct MultiAccountSettingsView: View {
    var body: some View {
        Form {
            Section(header: Text("Profiles")) {
                HStack {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.title)
                        .foregroundStyle(MivioTheme.accent)
                    Text("Default Profile")
                    Spacer()
                    Image(systemName: "checkmark")
                        .foregroundStyle(MivioTheme.accent)
                }
                Button("Add New Profile...") {
                    // Action
                }
                .foregroundStyle(MivioTheme.accent)
            }
        }
        .navigationTitle("Manage Accounts")
    }
}

// MARK: - Support Views

struct ReportBugView: View {
    @State private var title = ""
    @State private var description = ""
    @State private var attachLogs = true
    
    var body: some View {
        Form {
            Section(header: Text("Bug Details")) {
                TextField("Title", text: $title)
                if #available(macOS 13.0, iOS 16.0, tvOS 16.0, *) {
                    TextField("Describe the issue...", text: $description, axis: .vertical)
                        .lineLimit(5...10)
                } else {
                    TextField("Describe the issue...", text: $description)
                }
            }
            Section(footer: Text("Attaching device logs helps us fix the issue faster.")) {
                Toggle("Attach diagnostic logs", isOn: $attachLogs)
            }
            Section {
                Button("Submit Report") {
                    // Submission logic
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .foregroundStyle(MivioTheme.accent)
            }
        }
        .navigationTitle("Report a Bug")
    }
}

struct FollowUsView: View {
    var body: some View {
        Form {
            Section {
                LinkRow(icon: "xmark", color: .black, title: "Follow on X", url: "https://x.com/mivioapp")
                LinkRow(icon: "paperplane.fill", color: .blue, title: "Join Telegram Channel", url: "https://t.me/mivioapp")
                LinkRow(icon: "camera.fill", color: .purple, title: "Follow on Instagram", url: "https://instagram.com/mivioapp")
            }
            Section(header: Text("Newsletter")) {
                Button("Subscribe to Newsletter") {
                    // Action
                }
                .foregroundStyle(MivioTheme.accent)
            }
        }
        .navigationTitle("Follow Us")
    }
}

struct SettingsDetailPlaceholder: View {
    let title: String
    var body: some View {
        ZStack {
            MivioTheme.background.ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "gearshape.2.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(MivioTheme.accent.opacity(0.7))
                Text(title)
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                Text("Configuration options for \(title) will go here.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
        .navigationTitle(title)
    }
}
