import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var container: DependencyContainer
    @State private var showingCameraAdd = false

    var body: some View {
        TabView {
            CollectionView()
                .tabItem {
                    Label("Collection", systemImage: "record.circle")
                }
            WishlistView(recordManager: container.recordManager,
                         wishlistManager: container.wishlistManager)
                .tabItem {
                    Label("Wishlist", systemImage: "star.circle")
                }
            StatisticsView(statisticsManager: container.statisticsManager)
                .tabItem {
                    Label("Statistics", systemImage: "chart.bar.fill")
                }
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .sheet(isPresented: $showingCameraAdd) {
            AddRecordView(recordManager: container.recordManager, startFromCamera: true)
        }
        .onOpenURL { url in
            guard url.scheme == "deepgroove",
                  let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                  components.host == "add",
                  components.queryItems?.contains(where: { $0.name == "source" && $0.value == "camera" }) == true
            else { return }
            showingCameraAdd = true
        }
    }
}
