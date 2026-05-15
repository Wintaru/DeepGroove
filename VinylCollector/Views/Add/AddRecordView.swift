import SwiftUI

struct AddRecordView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var vm: AddRecordViewModel

    init(recordManager: IRecordManager) {
        _vm = State(initialValue: AddRecordViewModel(recordManager: recordManager))
    }

    var body: some View {
        @Bindable var model = vm
        NavigationStack {
            Group {
                switch vm.state {
                case .selectSource:
                    sourceSelectionView
                case .showingCamera:
                    cameraSheet
                case .showingPhotoLibrary:
                    photoLibrarySheet
                case .showingBarcodeScanner:
                    barcodeScannerSheet
                case .showingManualEntry:
                    manualEntryView(model: $model)
                case .confirmingCrop(let image, let detectedRect):
                    CoverCropView(image: image, detectedRect: detectedRect) { rect in
                        Task { await vm.searchWithCrop(image, rect: rect) }
                    }
                case .identifying:
                    identifyingView
                case .showingDiscogsResults(let candidates, let identification, let userPhoto):
                    DiscogsPickerView(candidates: candidates,
                                      identification: identification,
                                      userPhoto: userPhoto,
                                      vm: vm)
                case .success(let title):
                    successView(title)
                case .noResults(let message):
                    noResultsView(message)
                case .failure(let message):
                    failureView(message)
                }
            }
            .navigationTitle("Add Record")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    // MARK: - Source selection

    private var sourceSelectionView: some View {
        VStack(spacing: 20) {
            Text("How would you like to add this record?")
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding(.top, 32)

            VStack(spacing: 12) {
                sourceButton(
                    title: "Take a Photo",
                    subtitle: "Photo of album art or barcode — AI identifies it",
                    icon: "camera.fill",
                    color: .blue
                ) { vm.selectCamera() }

                sourceButton(
                    title: "Choose from Library",
                    subtitle: "Pick a photo of the cover or barcode",
                    icon: "photo.fill",
                    color: .purple
                ) { vm.selectPhotoLibrary() }

                sourceButton(
                    title: "Scan Barcode",
                    subtitle: "Live barcode scanner for instant lookup",
                    icon: "barcode.viewfinder",
                    color: .green
                ) { vm.selectBarcodeScanner() }

                sourceButton(
                    title: "Manual Entry",
                    subtitle: "Type in the details yourself",
                    icon: "pencil",
                    color: .orange
                ) { vm.goToManualEntry() }
            }
            .padding(.horizontal)

            Spacer()
        }
    }

    private func sourceButton(title: String, subtitle: String, icon: String,
                               color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                    .frame(width: 40)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.headline).foregroundStyle(.primary)
                    Text(subtitle).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.tertiary)
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Camera / library / barcode sheets

    @ViewBuilder
    private var cameraSheet: some View {
        CameraView(sourceType: .camera) { image in
            vm.photoSelected(image)
        } onCancel: {
            vm.state = .selectSource
        }
        .ignoresSafeArea()
    }

    @ViewBuilder
    private var photoLibrarySheet: some View {
        CameraView(sourceType: .photoLibrary) { image in
            vm.photoSelected(image)
        } onCancel: {
            vm.state = .selectSource
        }
        .ignoresSafeArea()
    }

    @ViewBuilder
    private var barcodeScannerSheet: some View {
        BarcodeView { barcode in
            Task { await vm.searchFromBarcode(barcode) }
        } onCancel: {
            vm.state = .selectSource
        }
        .ignoresSafeArea()
    }

    // MARK: - Manual entry

    private func manualEntryView(model: Bindable<AddRecordViewModel>) -> some View {
        let canSearch = !vm.manualArtist.isEmpty || !vm.manualAlbumTitle.isEmpty
        let doSearch = { _ = Task { await vm.searchDiscogsFromManualFields() } }
        return Form {
            Section("Required") {
                TextField("Artist", text: model.manualArtist)
                    .submitLabel(.next)
                TextField("Album Title", text: model.manualAlbumTitle)
                    .submitLabel(.search)
                    .onSubmit { if canSearch { doSearch() } }
            }
            Section("Optional") {
                TextField("Year", text: model.manualYear)
                    .keyboardType(.numberPad)
                TextField("Label", text: model.manualLabel)
                    .submitLabel(.search)
                    .onSubmit { if canSearch { doSearch() } }
                Picker("Condition", selection: model.condition) {
                    ForEach(RecordCondition.allCases, id: \.self) { c in
                        Text(c.displayName).tag(c)
                    }
                }
            }
            Section("Notes") {
                TextEditor(text: model.notes)
                    .frame(minHeight: 60)
            }
            Section {
                Button {
                    Task { await vm.searchDiscogsFromManualFields() }
                } label: {
                    Label("Search Discogs", systemImage: "magnifyingglass")
                        .frame(maxWidth: .infinity)
                }
                .disabled(vm.manualArtist.isEmpty && vm.manualAlbumTitle.isEmpty)

                Button("Add Without Searching") {
                    Task { await vm.addManually() }
                }
                .frame(maxWidth: .infinity)
                .disabled(vm.manualArtist.isEmpty || vm.manualAlbumTitle.isEmpty)
                .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Status screens

    private var identifyingView: some View {
        VStack(spacing: 24) {
            Spacer()
            ProgressView().scaleEffect(1.5)
            Text("Searching…").font(.headline)
            Text("Looking up artist, album, and metadata")
                .font(.subheadline).foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding()
    }

    private func successView(_ title: String) -> some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 72)).foregroundStyle(.green)
            VStack(spacing: 6) {
                Text("Added to Collection").font(.title2).fontWeight(.bold)
                Text(title)
                    .font(.headline).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            Button("Done") { dismiss() }.buttonStyle(.borderedProminent).controlSize(.large)
            Button(vm.addAnotherLabel) { vm.reset() }.foregroundStyle(.secondary)
            if vm.lastUsedMethod != nil {
                Button("Choose different method") { vm.chooseDifferentMethod() }
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            Spacer()
        }
        .padding()
    }

    private func noResultsView(_ message: String) -> some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 72)).foregroundStyle(.secondary)
            VStack(spacing: 6) {
                Text("No Results Found").font(.title2).fontWeight(.bold)
                Text(message).font(.subheadline).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            Button("Try Again") { vm.reset() }
                .buttonStyle(.borderedProminent).controlSize(.large)
            Button("Enter Manually") { vm.goToManualEntry() }
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding()
    }

    private func failureView(_ message: String) -> some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 72)).foregroundStyle(.red)
            VStack(spacing: 6) {
                Text("Something went wrong").font(.title2).fontWeight(.bold)
                Text(message).font(.subheadline).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            Button("Try Again") { vm.state = .selectSource }
                .buttonStyle(.borderedProminent).controlSize(.large)
            Spacer()
        }
        .padding()
    }
}
