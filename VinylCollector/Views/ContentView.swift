import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var container: DependencyContainer

    var body: some View {
        TabView {
            CollectionView()
                .tabItem {
                    Label("Collection", systemImage: "record.circle")
                }
            WishlistView()
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
    }
}
