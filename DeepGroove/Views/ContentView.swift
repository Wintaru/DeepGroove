import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var container: DependencyContainer
    @Environment(\.scenePhase) private var scenePhase
    @State private var selectedTab = 0
    @State private var showingCameraAdd = false

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
                Task { await checkPendingWishlistItem() }
            }
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

    private func checkPendingWishlistItem() async {
        let defaults = UserDefaults(suiteName: "group.com.jdonner.deepgroove")
        guard let item = defaults?.dictionary(forKey: "pendingWishlistItem") as? [String: String],
              let artist = item["artist"], let album = item["album"],
              !artist.isEmpty, !album.isEmpty else { return }
        defaults?.removeObject(forKey: "pendingWishlistItem")
        let yearInt = item["year"].flatMap(Int.init)
        let request: AddToWishlistRequest
        if let discogsIdStr = item["discogsId"], let discogsId = Int(discogsIdStr) {
            let chosenResult = DiscogsSearchResult(
                id: discogsId,
                masterId: nil,
                title: item["discogsTitle"] ?? "\(artist) - \(album)",
                year: item["year"],
                labels: item["label"].map { [$0] } ?? [],
                catalogNumber: nil,
                genres: item["genres"].map { $0.components(separatedBy: ",") } ?? [],
                styles: [],
                country: nil,
                thumbURL: item["thumb"],
                coverImageURL: nil,
                barcodes: []
            )
            request = AddToWishlistRequest(chosenResult: chosenResult)
        } else {
            request = AddToWishlistRequest(artistOverride: artist, albumTitleOverride: album, yearOverride: yearInt)
        }
        let response = await container.wishlistManager.execute(request)
        if response.success {
            selectedTab = 1
        }
    }
}
