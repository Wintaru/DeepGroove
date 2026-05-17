import SwiftUI
import SwiftData

@main
struct DeepGrooveApp: App {
    private let modelContainer: ModelContainer?
    private let dependencyContainer: DependencyContainer?
    private let storeError: String?

    init() {
        do {
            let schema = Schema([VinylRecord.self, RecordPhoto.self, WishlistRecord.self])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false,
                                            cloudKitDatabase: .automatic)
            let container = try ModelContainer(for: schema, configurations: [config])
            modelContainer = container
            dependencyContainer = DependencyContainer(modelContext: container.mainContext)
            storeError = nil
        } catch {
            modelContainer = nil
            dependencyContainer = nil
            storeError = error.localizedDescription
        }
    }

    var body: some Scene {
        WindowGroup {
            if let container = modelContainer, let deps = dependencyContainer {
                ContentView()
                    .modelContainer(container)
                    .environmentObject(deps)
                    .environmentObject(deps.apiConfiguration)
            } else {
                StoreErrorView(error: storeError ?? "Unknown error")
            }
        }
    }
}

private struct StoreErrorView: View {
    let error: String
    @State private var didReset = false

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(.orange)
            Text("Unable to Open Library")
                .font(.title2.bold())
            Text("Your vinyl collection could not be loaded. This can happen after a failed sync or interrupted update.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            if didReset {
                Text("Local data cleared. Force-quit and reopen the app to continue.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.green)
            } else {
                Button("Reset Local Data", role: .destructive) {
                    deleteStore()
                    didReset = true
                }
            }
            Text(error)
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .padding(.top, 8)
        }
        .padding(32)
    }

    private func deleteStore() {
        let fm = FileManager.default
        guard let support = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return }
        for name in ["default.store", "default.store-shm", "default.store-wal"] {
            try? fm.removeItem(at: support.appendingPathComponent(name))
        }
    }
}
