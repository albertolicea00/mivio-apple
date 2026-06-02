import Foundation
import SwiftData

@MainActor
public final class LibraryManager {
    public static let shared = LibraryManager()
    
    private init() {}
    
    /// Synchronizes the local "Documents" directory with the SwiftData store.
    public func syncLocalDocuments(context: ModelContext) async {
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let path = documentsURL.path
        
        // 1. Ensure the default local Source exists.
        let descriptor = FetchDescriptor<Source>(predicate: #Predicate { $0.path == path })
        let sources = (try? context.fetch(descriptor)) ?? []
        
        let localSource: Source
        if let existing = sources.first {
            localSource = existing
        } else {
            localSource = Source(type: .local, path: path, nickname: "Local Documents")
            context.insert(localSource)
            try? context.save()
        }
        
        // 2. Scan the source using LocalMediaScanner
        let scanner = LocalMediaScanner()
        let stream = scanner.scan(source: localSource)
        
        var newlyAddedItems: [MediaItem] = []
        
        // Fetch existing items to avoid duplicates
        let existingItemsDescriptor = FetchDescriptor<MediaItem>()
        let allItems = (try? context.fetch(existingItemsDescriptor)) ?? []
        let existingItems = allItems.filter { $0.source?.id == localSource.id }
        let existingPaths = Set(existingItems.map { $0.path })
        
        for await item in stream {
            if !existingPaths.contains(item.path) {
                // New item found
                context.insert(item)
                newlyAddedItems.append(item)
            }
        }
        
        try? context.save()
        
        // 3. Fetch Metadata for newly added items
        for item in newlyAddedItems {
            await fetchMetadata(for: item, context: context)
        }
    }
    
    public func fetchMetadata(for item: MediaItem, context: ModelContext) async {
        let parsed = MivioGuessItParser.parse(fileName: item.fileName)
        
        // TODO: Replace with a real API key or fetch from AppStorage/Keychain
        let tmdb = TMDBService(apiKey: KeychainHelper.shared.tmdbApiKey ?? "")
        do {
            let metadata = try await tmdb.fetchMetadata(for: parsed)
            item.metadata = metadata
            try? context.save()
        } catch {
            print("Mivio: Failed to fetch metadata for \(parsed.title) - \(error)")
            let defaultMeta = Metadata(title: parsed.title)
            item.metadata = defaultMeta
            try? context.save()
        }
    }
}
