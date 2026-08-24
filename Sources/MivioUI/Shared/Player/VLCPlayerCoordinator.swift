import Foundation

#if canImport(VLCKitSPM)
import VLCKitSPM

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

    func pauseForBackground() {
        guard let player, player.isPlaying else { return }
        player.pause()
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

#endif
