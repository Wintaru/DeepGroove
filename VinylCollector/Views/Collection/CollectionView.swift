import SwiftUI
import SwiftData

struct CollectionView: View {
    @EnvironmentObject private var container: DependencyContainer
    @Environment(\.modelContext) private var modelContext
    @Query private var allRecords: [VinylRecord]
    @State private var vm = CollectionViewModel()

    private var displayRecords: [VinylRecord] {
        let filter = CollectionFilter(
            searchText: vm.searchText.isEmpty ? nil : vm.searchText,
            genres: vm.selectedGenres.isEmpty ? nil : Array(vm.selectedGenres),
            decades: vm.selectedDecades.isEmpty ? nil : vm.selectedDecades
        )
        return vm.sortOrder.apply(to: filter.applying(allRecords))
    }

    var body: some View {
        @Bindable var vm = vm
        return NavigationStack {
            Group {
                if allRecords.isEmpty {
                    emptyState
                } else {
                    recordList
                }
            }
            .navigationTitle("Collection")
            .searchable(text: $vm.searchText,
                        placement: .navigationBarDrawer(displayMode: .always),
                        prompt: "Search artist, album, or label")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    sortMenu
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        if vm.hasActiveFilters {
                            Button("Clear") { vm.clearFilters() }
                                .foregroundStyle(.red)
                        }
                        Button { vm.showingFilters = true } label: {
                            Image(systemName: vm.hasActiveFilters
                                  ? "line.3.horizontal.decrease.circle.fill"
                                  : "line.3.horizontal.decrease.circle")
                        }
                        Button { vm.showingAddRecord = true } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $vm.showingAddRecord) {
                AddRecordView(recordManager: container.recordManager)
            }
            .sheet(isPresented: $vm.showingFilters) {
                FilterView(vm: vm, allRecords: allRecords)
            }
            .errorAlert(message: $vm.errorMessage)
        }
    }

    private var recordList: some View {
        List {
            ForEach(displayRecords) { record in
                NavigationLink(destination: RecordDetailView(record: record, recordManager: container.recordManager)) {
                    RecordRowView(record: record)
                }
            }
            .onDelete { indexSet in
                let fileManager = FileManagerUtility()
                for index in indexSet {
                    guard displayRecords.indices.contains(index) else { continue }
                    let record = displayRecords[index]
                    let relativePaths = record.photos?.map(\.photoPath) ?? []
                    modelContext.delete(record)
                    fileManager.removeFiles(atRelativePaths: relativePaths)
                }
                // No explicit save — autosave commits after the removal animation finishes.
            }
        }
        .listStyle(.plain)
        .overlay {
            if displayRecords.isEmpty {
                ContentUnavailableView.search
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "No Records Yet",
            systemImage: "record.circle",
            description: Text("Tap + to add your first record using the camera, barcode scanner, or manual entry.")
        )
    }

    private var sortMenu: some View {
        Menu {
            ForEach(CollectionSortOrder.allCases, id: \.self) { order in
                Button {
                    vm.sortOrder = order
                } label: {
                    if vm.sortOrder == order {
                        Label(order.displayName, systemImage: "checkmark")
                    } else {
                        Text(order.displayName)
                    }
                }
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
        }
    }
}

// MARK: - Filter Sheet

private struct FilterView: View {
    @Environment(\.dismiss) private var dismiss
    var vm: CollectionViewModel
    let allRecords: [VinylRecord]

    private var availableGenres: [String] {
        Array(Set(allRecords.flatMap { $0.genres })).sorted()
    }

    private var availableDecades: [Int] {
        let decades = Set(allRecords.compactMap { $0.year }.map { $0 / 10 * 10 })
        return decades.sorted()
    }

    private func decadeLabel(_ decade: Int) -> String {
        "\(decade)s"
    }

    var body: some View {
        NavigationStack {
            Form {
                if !availableGenres.isEmpty {
                    Section("Genre") {
                        ForEach(availableGenres, id: \.self) { genre in
                            Toggle(genre, isOn: Binding(
                                get: { vm.selectedGenres.contains(genre) },
                                set: { selected in
                                    if selected { vm.selectedGenres.insert(genre) }
                                    else { vm.selectedGenres.remove(genre) }
                                }
                            ))
                        }
                    }
                }

                if !availableDecades.isEmpty {
                    Section("Decade") {
                        ForEach(availableDecades, id: \.self) { decade in
                            Toggle(decadeLabel(decade), isOn: Binding(
                                get: { vm.selectedDecades.contains(decade) },
                                set: { selected in
                                    if selected { vm.selectedDecades.insert(decade) }
                                    else { vm.selectedDecades.remove(decade) }
                                }
                            ))
                        }
                    }
                }
            }
            .navigationTitle("Filter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Clear All") { vm.clearFilters() }
                }
            }
        }
    }
}
