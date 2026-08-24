import SwiftUI

#if canImport(VLCKitSPM)

struct VLCPlayerControls: View {
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

#endif
