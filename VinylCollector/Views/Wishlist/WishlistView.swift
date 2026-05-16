import SwiftUI
import SwiftData

struct WishlistView: View {
    @EnvironmentObject private var container: DependencyContainer
    @Environment(\.modelContext) private var modelContext
    @Query private var allItems: [WishlistRecord]
    @State private var vm = WishlistViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if allItems.isEmpty {
                    emptyState
                } else {
                    itemList
                }
            }
            .navigationTitle("Wishlist")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if vm.isAddingToCollection {
                        ProgressView()
                    } else {
                        Button { vm.showingAddToWishlist = true } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $vm.showingAddToWishlist) {
                AddToWishlistView(
                    recordManager: container.recordManager,
                    wishlistManager: container.wishlistManager
                )
            }
            .sheet(isPresented: Binding(
                get: { vm.addedRecord != nil },
                set: { if !$0 { vm.addedRecord = nil } }
            )) {
                if let record = vm.addedRecord {
                    NavigationStack {
                        RecordDetailView(record: record, recordManager: container.recordManager)
                    }
                }
            }
            .errorAlert(message: Binding(
                get: { vm.errorMessage },
                set: { vm.errorMessage = $0 }
            ))
        }
        .onAppear {
            vm.setManagers(recordManager: container.recordManager,
                           wishlistManager: container.wishlistManager)
        }
    }

    private var itemList: some View {
        List {
            ForEach(allItems) { item in
                WishlistItemRowView(item: item) {
                    Task { await vm.foundIt(item) }
                }
                .disabled(vm.isAddingToCollection)
            }
            .onDelete { indexSet in
                for index in indexSet {
                    guard allItems.indices.contains(index) else { continue }
                    modelContext.delete(allItems[index])
                }
            }
        }
        .listStyle(.plain)
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "Wishlist is Empty",
            systemImage: "star.circle",
            description: Text("Tap + to add records you want to find.")
        )
    }
}
