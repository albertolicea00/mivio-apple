import SwiftUI
import MivioUI
import MivioCore
import SwiftData

@main
struct MivioApp: App {
    // shared SwiftData model container
    let container: ModelContainer
    
    @AppStorage("AppTheme") private var appTheme = "System"
    
    var colorScheme: ColorScheme? {
        if appTheme == "Light" { return .light }
        if appTheme == "Dark" { return .dark }
        return nil
    }
    
    init() {
        do {
            let schema = Schema([
                Source.self,
                MediaItem.self,
                Metadata.self,
                WatchProgress.self
            ])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            self.container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not initialize SwiftData ModelContainer: \(error.localizedDescription)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            MivioMainTabView()
                .modelContainer(container)
                .preferredColorScheme(colorScheme)
                // .tint() logic to be added if needed
        }
    }
}
