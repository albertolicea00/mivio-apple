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
    @AppStorage("PlayerEngine") private var playerEngine = "Native"

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

    private var mediaURL: URL {
        item.path.hasPrefix("http") ? URL(string: item.path)! : URL(fileURLWithPath: item.path)
    }

    var body: some View {
        VLCPlayerRepresentable(url: mediaURL)
            .ignoresSafeArea()
            .background(Color.black)
    }
}

final class VLCPlayerCoordinator {
    var player: VLCMediaPlayer?
}

#if os(macOS)
struct VLCPlayerRepresentable: NSViewRepresentable {
    let url: URL

    func makeCoordinator() -> VLCPlayerCoordinator { VLCPlayerCoordinator() }

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        let player = VLCMediaPlayer()
        player.drawable = view
        player.media = VLCMedia(url: url)
        player.play()
        context.coordinator.player = player
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}

    static func dismantleNSView(_ nsView: NSView, coordinator: VLCPlayerCoordinator) {
        coordinator.player?.stop()
    }
}
#else
struct VLCPlayerRepresentable: UIViewRepresentable {
    let url: URL

    func makeCoordinator() -> VLCPlayerCoordinator { VLCPlayerCoordinator() }

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        let player = VLCMediaPlayer()
        player.drawable = view
        player.media = VLCMedia(url: url)
        player.play()
        context.coordinator.player = player
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    static func dismantleUIView(_ uiView: UIView, coordinator: VLCPlayerCoordinator) {
        coordinator.player?.stop()
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
