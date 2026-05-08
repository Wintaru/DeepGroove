import SwiftUI

struct RecordDetailView: View {
    let record: VinylRecord
    @EnvironmentObject private var container: DependencyContainer
    @Environment(\.dismiss) private var dismiss
    @State private var vm: RecordDetailViewModel?
    @State private var selectedPhotoIndex = 0

    private var model: RecordDetailViewModel {
        vm ?? RecordDetailViewModel(recordManager: container.recordManager)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                photoHeader
                    .padding(.bottom, 20)

                VStack(alignment: .leading, spacing: 16) {
                    artistAlbumSection
                    metadataSection
                    if !record.genres.isEmpty { genreSection }
                    if let notes = record.notes, !notes.isEmpty { notesSection(notes) }
                }
                .padding(.horizontal)
            }
        }
        .navigationTitle(record.albumTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    shareButton
                    Menu {
                        Button("Edit") { model.beginEditing(record: record) }
                        Divider()
                        Button("Delete", role: .destructive) {
                            model.showingDeleteConfirm = true
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .sheet(isPresented: Binding(
            get: { model.isEditing },
            set: { model.isEditing = $0 }
        )) {
            EditRecordView(record: record, vm: model)
        }
        .confirmationDialog("Delete this record?", isPresented: Binding(
            get: { model.showingDeleteConfirm },
            set: { model.showingDeleteConfirm = $0 }
        ), titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                Task { await model.deleteRecord(record) }
            }
        }
        .onChange(of: model.didDelete) { _, deleted in
            if deleted { dismiss() }
        }
        .alert("Error", isPresented: Binding(
            get: { model.errorMessage != nil },
            set: { if !$0 { model.errorMessage = nil } }
        )) {
            Button("OK") { model.errorMessage = nil }
        } message: {
            Text(model.errorMessage ?? "")
        }
        .task {
            if vm == nil {
                vm = RecordDetailViewModel(recordManager: container.recordManager)
            }
        }
    }

    // MARK: - Sections

    private var photoHeader: some View {
        let photos = record.photos
        return Group {
            if photos.isEmpty {
                Image(systemName: "record.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 280)
                    .background(Color(.systemGray6))
            } else {
                TabView(selection: $selectedPhotoIndex) {
                    ForEach(Array(photos.enumerated()), id: \.element.id) { index, photo in
                        if let image = UIImage(contentsOfFile: photo.photoPath) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .tag(index)
                        }
                    }
                }
                .tabViewStyle(.page)
                .frame(height: 320)
                .background(Color.black)
            }
        }
    }

    private var artistAlbumSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(record.albumTitle)
                .font(.title2)
                .fontWeight(.bold)
            Text(record.artist)
                .font(.title3)
                .foregroundStyle(.secondary)
        }
    }

    private var metadataSection: some View {
        Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 8) {
            if let year = record.year {
                metadataRow(label: "Year", value: String(year))
            }
            if let label = record.label {
                metadataRow(label: "Label", value: label)
            }
            if let catNo = record.catalogNumber {
                metadataRow(label: "Cat. No.", value: catNo)
            }
            if let country = record.country {
                metadataRow(label: "Country", value: country)
            }
            metadataRow(label: "Condition", value: record.condition.displayName)
            if let value = record.estimatedValue {
                metadataRow(label: "Est. Value", value: String(format: "$%.2f", value))
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func metadataRow(label: String, value: String) -> some View {
        GridRow {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .gridColumnAlignment(.leading)
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .gridColumnAlignment(.leading)
        }
    }

    private var genreSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Genres")
                .font(.headline)
            FlowLayout(spacing: 8) {
                ForEach(record.genres + record.styles, id: \.self) { tag in
                    Text(tag)
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.accentColor.opacity(0.1))
                        .foregroundStyle(.accentColor)
                        .clipShape(Capsule())
                }
            }
        }
    }

    private func notesSection(_ notes: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes")
                .font(.headline)
            Text(notes)
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }

    private var shareButton: some View {
        let text = "\(record.artist) – \(record.albumTitle)"
            + (record.year.map { " (\($0))" } ?? "")
            + "\n#VinylCollection"
        return ShareLink(item: text) {
            Image(systemName: "square.and.arrow.up")
        }
    }
}

// MARK: - Edit Sheet

private struct EditRecordView: View {
    let record: VinylRecord
    let vm: RecordDetailViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Artist & Album") {
                    TextField("Artist", text: $vm.editArtist)
                    TextField("Album Title", text: $vm.editAlbumTitle)
                }
                Section("Details") {
                    TextField("Year", text: $vm.editYear)
                        .keyboardType(.numberPad)
                    TextField("Label", text: $vm.editLabel)
                    TextField("Catalog Number", text: $vm.editCatalogNumber)
                    Picker("Condition", selection: $vm.editCondition) {
                        ForEach(RecordCondition.allCases, id: \.self) { c in
                            Text(c.displayName).tag(c)
                        }
                    }
                }
                Section("Notes") {
                    TextEditor(text: $vm.editNotes)
                        .frame(minHeight: 80)
                }
            }
            .navigationTitle("Edit Record")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task { await vm.saveEdits(record: record) }
                    }
                }
            }
        }
    }
}

// MARK: - Flow layout for genre tags

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        let height = rows.map { $0.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0 }
            .reduce(0) { $0 + $1 + spacing } - spacing
        return CGSize(width: proposal.width ?? 0, height: max(height, 0))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(proposal: ProposedViewSize(width: bounds.width, height: nil),
                               subviews: subviews)
        var y = bounds.minY
        for row in rows {
            var x = bounds.minX
            let rowHeight = row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
            for view in row {
                let size = view.sizeThatFits(.unspecified)
                view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += rowHeight + spacing
        }
    }

    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [[LayoutSubview]] {
        var rows: [[LayoutSubview]] = [[]]
        var currentRowWidth: CGFloat = 0
        let maxWidth = proposal.width ?? .infinity
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if currentRowWidth + size.width > maxWidth, !rows[rows.endIndex - 1].isEmpty {
                rows.append([])
                currentRowWidth = 0
            }
            rows[rows.endIndex - 1].append(view)
            currentRowWidth += size.width + spacing
        }
        return rows
    }
}
