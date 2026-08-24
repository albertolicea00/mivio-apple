import SwiftUI
import AVKit
import MivioCore

struct NativeAVPlayerView: View {
    let item: MediaItem
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("BackgroundAudio") private var backgroundAudio = false
    @State private var player: AVPlayer?

    var body: some View {
        ZStack(alignment: .top) {
            VideoPlayer(player: player)
                .ignoresSafeArea()

            HStack {
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Label("Exit", systemImage: "xmark")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(.black.opacity(0.15)))
                }
                .buttonStyle(.plain)
            }
            .padding()
        }
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
        .onChange(of: scenePhase) { newPhase in
            if newPhase != .active && !backgroundAudio {
                player?.pause()
            }
        }
    }
}
