import SwiftUI
import MivioUI
import MivioCore
import SwiftData

@main
struct MivioApp: App {
    // shared SwiftData model container
    let container: ModelContainer
    
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
            MivioHomeScreen()
                .modelContainer(container)
                .preferredColorScheme(.dark) // Sleek Premium Dark Mode by default
        }
    }
}
