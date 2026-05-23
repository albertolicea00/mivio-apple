import SwiftUI
import MivioUI
import MivioCore
import SwiftData

@main
struct MivioApp: App {
    @AppStorage("AppTheme") private var appTheme = "System"
    
    var colorScheme: ColorScheme? {
        if appTheme == "Light" { return .light }
        if appTheme == "Dark" { return .dark }
        return nil
    }
    
    init() {
        setupFilesDirectory()
    }
    
    private func setupFilesDirectory() {
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let dummyFileURL = documentsURL.appendingPathComponent("Place media here.txt")
        if !FileManager.default.fileExists(atPath: dummyFileURL.path) {
            let text = "Place video files here"
            try? text.write(to: dummyFileURL, atomically: true, encoding: .utf8)
        }
    }
    
    var body: some Scene {
        WindowGroup {
            MivioMainTabView()
                .modelContainer(DatabaseManager.shared.container)
                .preferredColorScheme(colorScheme)
                .task {
                    // Kick off a sync when the app boots up
                    await LibraryManager.shared.syncLocalDocuments(context: DatabaseManager.shared.context)
                }
        }
    }
}
