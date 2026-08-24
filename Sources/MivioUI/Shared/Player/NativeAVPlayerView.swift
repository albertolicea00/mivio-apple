import SwiftUI
import AVKit
import MivioCore

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
