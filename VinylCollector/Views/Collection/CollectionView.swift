import SwiftUI
import SwiftData

struct CollectionView: View {
    @EnvironmentObject private var container: DependencyContainer
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \VinylRecord.dateAdded, order: .reverse) private var allRecords: [VinylRecord]
    @State private var viewModel: CollectionViewModel?

    private var vm: CollectionViewModel { viewModel ?? CollectionViewModel(recordManager: container.recordManager) }

    private var displayRecords: [VinylRecord] {
        guard let vm = viewModel else { return allRecords }
        let filter = vm.activeFilter
        var records = allRecords

        if let searchText = filter.searchText {
            let lower = searchText.lowercased()
            records = records.filter {
                $0.artist.lowercased().contains(lower) ||
                $0.albumTitle.lowercased().contains(lower) ||
                ($0.label?.lowercased().contains(lower) ?? false)
            }
        }
        if let genres = filter.genres {
            records = records.filter { !Set($0.genres).isDisjoint(with: genres) }
        }
        if let conditions = filter.conditions {
            records = records.filter { conditions.contains($0.condition) }
        }

        switch vm.sortOrder {
        case .artistAscending:      return records.sorted { $0.artist < $1.artist }
        case .artistDescending:     return records.sorted { $0.artist > $1.artist }
        case .titleAscending:       return records.sorted { $0.albumTitle < $1.albumTitle }
        case .titleDescending:      return records.sorted { $0.albumTitle > $1.albumTitle }
        case .yearNewest:           return records.sorted { ($0.year ?? 0) > ($1.year ?? 0) }
        case .yearOldest:           return records.sorted { ($0.year ?? 0) < ($1.year ?? 0) }
        case .dateAddedNewest:      return records
        case .dateAddedOldest:      return records.reversed()
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if allRecords.isEmpty {
                    emptyState
                } else {
                    recordList
                }
            }
            .navigationTitle("Collection")
            .searchable(text: Binding(
                get: { vm.searchText },
                set: { vm.searchText = $0 }
            ))
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
                            Image(systemName: vm.hasActiveFilters ? "line.3.horizontal.decrease.circle.fill"
                                                                  : "line.3.horizontal.decrease.circle")
                        }
                        Button { vm.showingAddRecord = true } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .sheet(isPresented: Binding(
                get: { vm.showingAddRecord },
                set: { vm.showingAddRecord = $0 }
            )) {
                AddRecordView(recordManager: container.recordManager)
            }
            .sheet(isPresented: Binding(
                get: { vm.showingFilters },
                set: { vm.showingFilters = $0 }
            )) {
                FilterView(vm: vm)
            }
            .alert("Error", isPresented: Binding(
                get: { vm.errorMessage != nil },
                set: { if !$0 { vm.errorMessage = nil } }
            )) {
                Button("OK") { vm.errorMessage = nil }
            } message: {
                Text(vm.errorMessage ?? "")
            }
        }
        .task {
            if viewModel == nil {
                viewModel = CollectionViewModel(recordManager: container.recordManager)
            }
        }
    }

    private var recordList: some View {
        List {
            ForEach(displayRecords) { record in
                NavigationLink(destination: RecordDetailView(record: record)) {
                    RecordRowView(record: record)
                }
            }
            .onDelete { indexSet in
                for index in indexSet {
                    guard displayRecords.indices.contains(index) else { continue }
                    let record = displayRecords[index]
                    let paths = record.photos?.map(\.resolvedPath) ?? []
                    modelContext.delete(record)
                    for path in paths { try? FileManager.default.removeItem(atPath: path) }
                }
                // No explicit save — autosave commits after the removal animation finishes.
                // Calling save() here would detach backing data while SwiftUI still renders the
                // disappearing row, causing a "backing data detached" crash on artworkSource.
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
                    Label(order.displayName,
                          systemImage: vm.sortOrder == order ? "checkmark" : "")
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

    var body: some View {
        NavigationStack {
            Form {
                Section("Condition") {
                    ForEach(RecordCondition.allCases, id: \.self) { condition in
                        Toggle(condition.displayName, isOn: Binding(
                            get: { vm.selectedConditions.contains(condition) },
                            set: { selected in
                                if selected { vm.selectedConditions.append(condition) }
                                else { vm.selectedConditions.removeAll { $0 == condition } }
                            }
                        ))
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
