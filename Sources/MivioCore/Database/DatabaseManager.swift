import Foundation
import SwiftData

@MainActor
public final class DatabaseManager {
    public static let shared = DatabaseManager()
    
    public let container: ModelContainer
    
    public var context: ModelContext {
        container.mainContext
    }
    
    private init() {
        do {
            let schema = Schema([
                Source.self,
                MediaItem.self,
                Metadata.self,
                WatchProgress.self
            ])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false, cloudKitDatabase: .none)
            self.container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not initialize SwiftData ModelContainer: \(error.localizedDescription)")
        }
    }
}
