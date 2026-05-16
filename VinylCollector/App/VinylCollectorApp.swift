import SwiftUI
import SwiftData

@main
struct VinylCollectorApp: App {
    private let modelContainer: ModelContainer
    private let dependencyContainer: DependencyContainer

    init() {
        do {
            let schema = Schema([VinylRecord.self, RecordPhoto.self, WishlistRecord.self])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false,
                                            cloudKitDatabase: .none)
            let container = try ModelContainer(for: schema, configurations: [config])
            modelContainer = container
            dependencyContainer = DependencyContainer(modelContext: container.mainContext)
        } catch {
            fatalError("Failed to initialise SwiftData store: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(modelContainer)
                .environmentObject(dependencyContainer)
                .environmentObject(dependencyContainer.apiConfiguration)
        }
    }
}
