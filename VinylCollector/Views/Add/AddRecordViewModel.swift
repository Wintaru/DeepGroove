import UIKit

enum AddRecordState {
    case selectSource
    case showingCamera
    case showingPhotoLibrary
    case showingBarcodeScanner
    case showingManualEntry
    case identifying
    case success(VinylRecord)
    case failure(String)
}

@Observable
final class AddRecordViewModel {
    var state: AddRecordState = .selectSource
    var artworkPreference: ArtworkSource = .downloaded
    var condition: RecordCondition = .veryGoodPlus
    var notes = ""

    // Manual entry fields
    var manualArtist = ""
    var manualAlbumTitle = ""
    var manualYear = ""
    var manualLabel = ""

    private let recordManager: IRecordManager

    init(recordManager: IRecordManager) {
        self.recordManager = recordManager
    }

    var isIdentifying: Bool {
        if case .identifying = state { return true }
        return false
    }

    func addFromPhoto(_ image: UIImage) async {
        state = .identifying
        let response = await recordManager.execute(AddRecordRequest(
            source: .photo(image),
            artworkPreference: artworkPreference,
            condition: condition,
            notes: notes.isEmpty ? nil : notes
        ))
        handleResponse(response)
    }

    func addFromBarcode(_ barcode: String) async {
        state = .identifying
        let response = await recordManager.execute(AddRecordRequest(
            source: .barcode(barcode),
            artworkPreference: artworkPreference,
            condition: condition,
            notes: notes.isEmpty ? nil : notes
        ))
        handleResponse(response)
    }

    func addManually() async {
        guard !manualArtist.isEmpty, !manualAlbumTitle.isEmpty else {
            state = .failure("Artist and album title are required.")
            return
        }
        state = .identifying
        let response = await recordManager.execute(AddRecordRequest(
            source: .manual,
            artworkPreference: artworkPreference,
            condition: condition,
            notes: notes.isEmpty ? nil : notes,
            artistOverride: manualArtist,
            albumTitleOverride: manualAlbumTitle,
            yearOverride: Int(manualYear),
            labelOverride: manualLabel.isEmpty ? nil : manualLabel
        ))
        handleResponse(response)
    }

    func reset() {
        state = .selectSource
        notes = ""
        manualArtist = ""
        manualAlbumTitle = ""
        manualYear = ""
        manualLabel = ""
    }

    private func handleResponse(_ response: ResponseBase) {
        if let result = response as? AddRecordResponse, result.success, let record = result.record {
            state = .success(record)
        } else {
            state = .failure(response.errorMessage ?? "Failed to add record.")
        }
    }
}
