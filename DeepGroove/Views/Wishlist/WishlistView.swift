import SwiftUI
import SwiftData

struct WishlistView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allItems: [WishlistRecord]
    @State private var vm: WishlistViewModel

    private let recordManager: IRecordManager
    private let wishlistManager: IWishlistManager

    init(recordManager: IRecordManager, wishlistManager: IWishlistManager) {
        self.recordManager = recordManager
        self.wishlistManager = wishlistManager
        _vm = State(initialValue: WishlistViewModel(
            recordManager: recordManager,
            wishlistManager: wishlistManager
        ))
    }

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
                AddToWishlistView(recordManager: recordManager, wishlistManager: wishlistManager)
            }
            .sheet(isPresented: $vm.showingLookup, onDismiss: { vm.lookupItem = nil }) {
                if let item = vm.lookupItem {
                    AddToWishlistView(
                        recordManager: recordManager,
                        wishlistManager: wishlistManager,
                        artist: item.artist,
                        albumTitle: item.albumTitle,
                        year: item.year.map(String.init),
                        existingItemId: item.id
                    )
                }
            }
            .sheet(isPresented: Binding(
                get: { vm.addedRecord != nil },
                set: { if !$0 { vm.addedRecord = nil } }
            )) {
                if let record = vm.addedRecord {
                    NavigationStack {
                        RecordDetailView(record: record, recordManager: recordManager)
                    }
                }
            }
            .errorAlert(message: Binding(
                get: { vm.errorMessage },
                set: { vm.errorMessage = $0 }
            ))
        }
    }

    private var itemList: some View {
        List {
            ForEach(allItems) { item in
                WishlistItemRowView(item: item) {
                    Task { await vm.foundIt(item) }
                }
                .disabled(vm.isAddingToCollection)
                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                    Button {
                        vm.beginLookup(item)
                    } label: {
                        Label("Find on Discogs", systemImage: "magnifyingglass")
                    }
                    .tint(.blue)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        modelContext.delete(item)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.plain)
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "Mostly Harmless",
            systemImage: "star.circle",
            description: Text("Your wishlist is as empty as space. Tap + to add records you're hunting for.")
        )
    }
}
