import SwiftUI
import SwiftData

struct RecordDetailView: View {
    let record: VinylRecord
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var vm: RecordDetailViewModel
    @State private var selectedPhotoIndex = 0

    init(record: VinylRecord, recordManager: IRecordManager) {
        self.record = record
        _vm = State(initialValue: RecordDetailViewModel(recordManager: recordManager))
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
                        Button("Edit") { vm.beginEditing(record: record) }
                        Button { vm.showingAddPhotoSource = true } label: {
                            Label("Add Photo", systemImage: "photo.badge.plus")
                        }
                        Divider()
                        Button("Delete", role: .destructive) {
                            vm.showingDeleteConfirm = true
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .confirmationDialog("Add Photo", isPresented: Binding(
            get: { vm.showingAddPhotoSource },
            set: { vm.showingAddPhotoSource = $0 }
        )) {
            Button("Take Photo") { vm.showingCamera = true }
            Button("Choose from Library") { vm.showingPhotoLibrary = true }
        }
        .sheet(isPresented: Binding(
            get: { vm.showingCamera },
            set: { vm.showingCamera = $0 }
        )) {
            CameraView(sourceType: .camera) { image in
                vm.showingCamera = false
                Task { await vm.attachPhoto(image, to: record) }
            } onCancel: {
                vm.showingCamera = false
            }
            .ignoresSafeArea()
        }
        .sheet(isPresented: Binding(
            get: { vm.showingPhotoLibrary },
            set: { vm.showingPhotoLibrary = $0 }
        )) {
            CameraView(sourceType: .photoLibrary) { image in
                vm.showingPhotoLibrary = false
                Task { await vm.attachPhoto(image, to: record) }
            } onCancel: {
                vm.showingPhotoLibrary = false
            }
            .ignoresSafeArea()
        }
        .sheet(isPresented: Binding(
            get: { vm.isEditing },
            set: { vm.isEditing = $0 }
        )) {
            EditRecordView(record: record, vm: model)
        }
        .confirmationDialog("Delete this record?", isPresented: Binding(
            get: { vm.showingDeleteConfirm },
            set: { vm.showingDeleteConfirm = $0 }
        ), titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                let relativePaths = record.photos?.map(\.photoPath) ?? []
                modelContext.delete(record)
                FileManagerUtility().removeFiles(atRelativePaths: relativePaths)
                dismiss()
                // No explicit save — autosave commits after dismiss animation finishes.
            }
        }
        .errorAlert(message: Binding(
            get: { vm.errorMessage },
            set: { vm.errorMessage = $0 }
        ))
    }

    // MARK: - Sections

    private var photoHeader: some View {
        let photos = record.photos ?? []
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
                        if let image = UIImage(contentsOfFile: photo.resolvedPath) {
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
                        .foregroundStyle(Color.accentColor)
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
    @Bindable var vm: RecordDetailViewModel
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
