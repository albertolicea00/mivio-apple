import SwiftUI
import AVKit
import MivioCore

#if canImport(VLCKitSPM)
import VLCKitSPM
#endif

#if os(macOS)
import AppKit
#elseif os(iOS) || os(tvOS)
import UIKit
#endif

public struct MivioPlayerView: View {
    let item: MediaItem

    // Shared with Settings > Playback's "Player Engine" picker ("Native" or "VLC").
    @AppStorage("PlayerEngine") private var playerEngine = "VLC"

    public init(item: MediaItem) {
        self.item = item
    }

    public var body: some View {
        Group {
            if playerEngine == "VLC" {
                VLCPlayerView(item: item)
            } else {
                NativeAVPlayerView(item: item)
            }
        }
        #if os(iOS) || os(tvOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        // .ignoresSafeArea() can cause navigation bar to overlap, AVKit handles its own fullscreen
    }
}

struct NativeAVPlayerView: View {
    let item: MediaItem
    @State private var player: AVPlayer?

    var body: some View {
        VideoPlayer(player: player)
            .ignoresSafeArea()
            .onAppear {
                // If it's a local file, create a file URL.
                // For SMB/WebDAV, we would need to stream or download.
                // Currently only local path is completely supported by AVPlayer out of the box if it's not an http stream.
                let url: URL
                if item.path.hasPrefix("http") {
                    url = URL(string: item.path)!
                } else {
                    url = URL(fileURLWithPath: item.path)
                }

                let newPlayer = AVPlayer(url: url)
                self.player = newPlayer
                newPlayer.play()

                #if os(iOS) || os(tvOS)
                // Ensure audio plays even if the phone is on silent mode
                try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback, options: [])
                #endif
            }
            .onDisappear {
                player?.pause()
            }
    }
}

// MARK: - VLC Player

#if canImport(VLCKitSPM)

struct VLCPlayerView: View {
    let item: MediaItem

    @StateObject private var coordinator = VLCPlayerCoordinator()
    @State private var controlsVisible = true
    @State private var hideControlsTask: Task<Void, Never>?

    private var mediaURL: URL {
        item.path.hasPrefix("http") ? URL(string: item.path)! : URL(fileURLWithPath: item.path)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.ignoresSafeArea()

            VLCPlayerRepresentable(url: mediaURL, coordinator: coordinator)
                .ignoresSafeArea()

            if controlsVisible {
                VLCPlayerControls(coordinator: coordinator)
                    .transition(.opacity)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { toggleControls() }
        .onChange(of: coordinator.isPlaying) { _ in scheduleAutoHide() }
        .onAppear { scheduleAutoHide() }
        .onDisappear { hideControlsTask?.cancel() }
    }

    private func toggleControls() {
        withAnimation(.easeInOut(duration: 0.2)) { controlsVisible.toggle() }
        if controlsVisible { scheduleAutoHide() }
    }

    private func scheduleAutoHide() {
        hideControlsTask?.cancel()
        guard coordinator.isPlaying else { return }
        hideControlsTask = Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            guard !Task.isCancelled, !coordinator.isScrubbing else { return }
            withAnimation(.easeInOut(duration: 0.2)) { controlsVisible = false }
        }
    }
}

private struct VLCPlayerControls: View {
    @ObservedObject var coordinator: VLCPlayerCoordinator

    var body: some View {
        VStack(spacing: 8) {
            Slider(value: $coordinator.position, in: 0...1, onEditingChanged: { editing in
                if editing {
                    coordinator.beginScrub()
                } else {
                    coordinator.endScrub()
                }
            })
            .tint(MivioTheme.accent)

            HStack {
                Text(Self.format(coordinator.currentTime))
                    .font(.caption).monospacedDigit().foregroundStyle(.white)
                Spacer()
                Button {
                    coordinator.togglePlayPause()
                } label: {
                    Image(systemName: coordinator.isPlaying ? "pause.fill" : "play.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
                Spacer()
                Text(Self.format(coordinator.duration))
                    .font(.caption).monospacedDigit().foregroundStyle(.white)
            }
        }
        .padding()
        .background(
            LinearGradient(colors: [.clear, .black.opacity(0.75)], startPoint: .top, endPoint: .bottom)
        )
    }

    private static func format(_ seconds: Double) -> String {
        guard seconds.isFinite, seconds >= 0 else { return "--:--" }
        let total = Int(seconds)
        let h = total / 3600, m = (total % 3600) / 60, s = total % 60
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, s) : String(format: "%d:%02d", m, s)
    }
}

final class VLCPlayerCoordinator: NSObject, ObservableObject, VLCMediaPlayerDelegate {
    @Published var isPlaying = false
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var position: Double = 0

    private(set) var isScrubbing = false
    private var player: VLCMediaPlayer?

    func attach(url: URL, drawable: Any) {
        guard player == nil else { return }
        let player = VLCMediaPlayer()
        player.drawable = drawable
        player.delegate = self
        player.media = VLCMedia(url: url)
        player.play()
        self.player = player
    }

    func togglePlayPause() {
        guard let player else { return }
        player.isPlaying ? player.pause() : player.play()
    }

    func beginScrub() { isScrubbing = true }

    func endScrub() {
        isScrubbing = false
        player?.position = Float(position)
    }

    func stop() {
        player?.stop()
    }

    func mediaPlayerTimeChanged(_ aNotification: Notification) {
        guard let player else { return }
        isPlaying = player.isPlaying
        currentTime = Double(player.time.intValue) / 1000
        duration = Double(player.media?.length.intValue ?? 0) / 1000
        if !isScrubbing {
            position = Double(player.position)
        }
    }

    func mediaPlayerStateChanged(_ aNotification: Notification) {
        isPlaying = player?.isPlaying ?? false
    }
}

#if os(macOS)
struct VLCPlayerRepresentable: NSViewRepresentable {
    let url: URL
    let coordinator: VLCPlayerCoordinator

    func makeCoordinator() -> VLCPlayerCoordinator { coordinator }

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        coordinator.attach(url: url, drawable: view)
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}

    static func dismantleNSView(_ nsView: NSView, coordinator: VLCPlayerCoordinator) {
        coordinator.stop()
    }
}
#else
struct VLCPlayerRepresentable: UIViewRepresentable {
    let url: URL
    let coordinator: VLCPlayerCoordinator

    func makeCoordinator() -> VLCPlayerCoordinator { coordinator }

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        coordinator.attach(url: url, drawable: view)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    static func dismantleUIView(_ uiView: UIView, coordinator: VLCPlayerCoordinator) {
        coordinator.stop()
    }
}
#endif

#else

/// visionOS (and any platform without the VLCKit dependency): VLCKit has no upstream build there.
struct VLCPlayerView: View {
    let item: MediaItem

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 20) {
                Image(systemName: "cone.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.orange)

                Text("VLC Player Unavailable")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text("VLCKit has no build for this platform.\n\nCurrently trying to play:\n\(item.fileName)")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)
                    .padding()
            }
        }
    }
}

#endif
