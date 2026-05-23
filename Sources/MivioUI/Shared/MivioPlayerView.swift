import SwiftUI
import AVKit
import MivioCore

public struct MivioPlayerView: View {
    let item: MediaItem
    
    @AppStorage("VideoPlayer") private var videoPlayerPref = "Native" // "Native" or "VLC"
    
    public init(item: MediaItem) {
        self.item = item
    }
    
    public var body: some View {
        Group {
            if videoPlayerPref == "VLC" {
                VLCPlayerPlaceholderView(item: item)
            } else {
                NativeAVPlayerView(item: item)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
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
                
                // Ensure audio plays even if the phone is on silent mode
                try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback, options: [])
            }
            .onDisappear {
                player?.pause()
            }
    }
}

struct VLCPlayerPlaceholderView: View {
    let item: MediaItem
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 20) {
                Image(systemName: "cone.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.orange)
                
                Text("VLC Player Integration")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("MobileVLCKit is not yet linked in the project.\n\nCurrently trying to play:\n\(item.fileName)")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)
                    .padding()
            }
        }
    }
}
