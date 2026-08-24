import SwiftUI
import MivioCore

#if canImport(VLCKitSPM)

struct VLCPlayerView: View {
    let item: MediaItem

    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("BackgroundAudio") private var backgroundAudio = false
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

            // Dedicated SwiftUI tap-catcher above the embedded UIKit/AppKit video view.
            // A gesture on the surrounding ZStack competed with the representable's own
            // view for the touch and lost, which is why controls never came back once hidden.
            Color.clear
                .contentShape(Rectangle())
                .ignoresSafeArea()
                .onTapGesture { toggleControls() }

            if controlsVisible {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.title3)
                            .foregroundStyle(.white)
                            .padding(12)
                            .background(Circle().fill(.black.opacity(0.4)))
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .transition(.opacity)
            }

            if controlsVisible {
                VLCPlayerControls(coordinator: coordinator)
                    .transition(.opacity)
            }
        }
        .onChange(of: coordinator.isPlaying) { _ in scheduleAutoHide() }
        .onChange(of: scenePhase) { newPhase in
            if newPhase != .active && !backgroundAudio {
                coordinator.pauseForBackground()
            }
        }
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
