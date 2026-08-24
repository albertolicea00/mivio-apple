import SwiftUI
import AVKit
import MivioCore

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
