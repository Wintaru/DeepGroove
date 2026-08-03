import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var container: DependencyContainer
    @Environment(\.scenePhase) private var scenePhase
    @State private var selectedTab = 0
    @State private var showingCameraAdd = false
    @State private var wishlistFailureMessage: String?

    var body: some View {
        TabView(selection: $selectedTab) {
            CollectionView()
                .tabItem { Label("Collection", systemImage: "record.circle") }
                .tag(0)
            WishlistView(recordManager: container.recordManager,
                         wishlistManager: container.wishlistManager)
                .tabItem { Label("Wishlist", systemImage: "star.circle") }
                .tag(1)
            StatisticsView(statisticsManager: container.statisticsManager)
                .tabItem { Label("Statistics", systemImage: "chart.bar.fill") }
                .tag(2)
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gear") }
                .tag(3)
        }
        .sheet(isPresented: $showingCameraAdd) {
            AddRecordView(recordManager: container.recordManager, startFromCamera: true)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task { await processPendingWishlistItems() }
            }
        }
        .alert("Couldn't Add to Wishlist", isPresented: Binding(
            get: { wishlistFailureMessage != nil },
            set: { if !$0 { wishlistFailureMessage = nil } }
        )) {
            Button("OK") { wishlistFailureMessage = nil }
        } message: {
            Text(wishlistFailureMessage ?? "")
        }
        .onOpenURL { url in
            guard url.scheme == "deepgroove",
                  let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            else { return }

            if components.host == "add",
               components.queryItems?.contains(where: { $0.name == "source" && $0.value == "camera" }) == true {
                showingCameraAdd = true
            }
        }
    }

    // Reads UserDefaults directly rather than through an Accessor — this is the one place
    // in the app that has to bridge state handed off by DeepGrooveShareExtension, a
    // separate process the DI container doesn't reach into.
    private func processPendingWishlistItems() async {
        let items = PendingWishlistQueue.drainAll()
        guard !items.isEmpty else { return }

        // Each execute() re-fetches the whole wishlist for its duplicate check (see
        // AddToWishlistHandler), so this is an N+1 across the drained queue. Accepted:
        // the queue only grows across shares made before the app is reopened, so N is
        // realistically 1-2, not worth a batch-add Manager operation for.
        var failures: [String] = []
        var anySucceeded = false
        for item in items {
            let request = AddToWishlistRequest(
                chosenResult: item.chosenResult,
                artistOverride: item.artistOverride,
                albumTitleOverride: item.albumTitleOverride,
                yearOverride: item.yearOverride,
                labelOverride: item.labelOverride
            )
            let response = await container.wishlistManager.execute(request)
            if response.success {
                anySucceeded = true
            } else {
                failures.append("\(item.displayTitle): \(response.errorMessage ?? "unknown error")")
            }
        }

        if anySucceeded {
            selectedTab = 1
        }
        if !failures.isEmpty {
            wishlistFailureMessage = failures.joined(separator: "\n")
        }
    }
}
