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
                case .selectSource:          sourceSelectionView
                case .showingCamera:         cameraSheet
                case .showingPhotoLibrary:   photoLibrarySheet
                case .showingBarcodeScanner: barcodeScannerSheet
                case .showingManualEntry:    manualEntryView(model: $model)
                case .identifying:           identifyingView
                case .success(let record):   successView(record)
                case .failure(let message):  failureView(message)
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

    // MARK: - States

    private var sourceSelectionView: some View {
        VStack(spacing: 20) {
            Text("How would you like to add this record?")
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding(.top, 32)

            VStack(spacing: 12) {
                sourceButton(
                    title: "Take a Photo",
                    subtitle: "AI identifies the record from a photo",
                    icon: "camera.fill",
                    color: .blue
                ) { vm.state = .showingCamera }

                sourceButton(
                    title: "Choose from Library",
                    subtitle: "Pick an existing photo of the record",
                    icon: "photo.fill",
                    color: .purple
                ) { vm.state = .showingPhotoLibrary }

                sourceButton(
                    title: "Scan Barcode",
                    subtitle: "Fast lookup using the record's barcode",
                    icon: "barcode.viewfinder",
                    color: .green
                ) { vm.state = .showingBarcodeScanner }

                sourceButton(
                    title: "Manual Entry",
                    subtitle: "Type in the details yourself",
                    icon: "pencil",
                    color: .orange
                ) { vm.state = .showingManualEntry }
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

    @ViewBuilder
    private var cameraSheet: some View {
        CameraView(sourceType: .camera) { image in
            Task { await vm.addFromPhoto(image) }
        } onCancel: {
            vm.state = .selectSource
        }
        .ignoresSafeArea()
    }

    @ViewBuilder
    private var photoLibrarySheet: some View {
        CameraView(sourceType: .photoLibrary) { image in
            Task { await vm.addFromPhoto(image) }
        } onCancel: {
            vm.state = .selectSource
        }
        .ignoresSafeArea()
    }

    @ViewBuilder
    private var barcodeScannerSheet: some View {
        BarcodeView { barcode in
            Task { await vm.addFromBarcode(barcode) }
        } onCancel: {
            vm.state = .selectSource
        }
        .ignoresSafeArea()
    }

    private func manualEntryView(model: Bindable<AddRecordViewModel>) -> some View {
        Form {
            Section("Required") {
                TextField("Artist", text: model.manualArtist)
                TextField("Album Title", text: model.manualAlbumTitle)
            }
            Section("Optional") {
                TextField("Year", text: model.manualYear)
                    .keyboardType(.numberPad)
                TextField("Label", text: model.manualLabel)
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
                Button("Add Record") {
                    Task { await vm.addManually() }
                }
                .frame(maxWidth: .infinity)
                .disabled(vm.manualArtist.isEmpty || vm.manualAlbumTitle.isEmpty)
            }
        }
    }

    private var identifyingView: some View {
        VStack(spacing: 24) {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
            Text("Identifying record…")
                .font(.headline)
            Text("Looking up artist, album, and metadata")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding()
    }

    private func successView(_ record: VinylRecord) -> some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(.green)
            VStack(spacing: 6) {
                Text("Added to Collection")
                    .font(.title2)
                    .fontWeight(.bold)
                Text(record.displayTitle)
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            Button("Done") { dismiss() }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            Button("Add Another") { vm.reset() }
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding()
    }

    private func failureView(_ message: String) -> some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(.red)
            VStack(spacing: 6) {
                Text("Something went wrong")
                    .font(.title2)
                    .fontWeight(.bold)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            Button("Try Again") { vm.state = .selectSource }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            Spacer()
        }
        .padding()
    }
}
