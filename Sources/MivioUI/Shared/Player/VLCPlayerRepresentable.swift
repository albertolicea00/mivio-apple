import SwiftUI

#if canImport(VLCKitSPM)

#if os(macOS)
import AppKit

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
import UIKit

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

#endif
