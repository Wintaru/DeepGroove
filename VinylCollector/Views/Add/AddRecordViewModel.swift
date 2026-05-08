import UIKit

enum AddRecordState {
    case selectSource
    case showingCamera
    case showingPhotoLibrary
    case showingBarcodeScanner
    case showingManualEntry
    case identifying
    case showingDiscogsResults(
            candidates: [DiscogsSearchResult],
            identification: AIIdentification?,
            userPhoto: UIImage?)
    case success(String)
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

    // MARK: - Step 1: Search

    func searchFromPhoto(_ image: UIImage) async {
        state = .identifying
        let response = await recordManager.query(SearchRecordRequest(source: .photo(image)))
        handleSearchResponse(response)
    }

    func searchFromBarcode(_ barcode: String) async {
        state = .identifying
        let response = await recordManager.query(SearchRecordRequest(source: .barcode(barcode)))
        handleSearchResponse(response)
    }

    func goToManualEntry() {
        state = .showingManualEntry
    }

    // MARK: - Step 2: Confirm selection and save

    func confirmResult(_ chosen: DiscogsSearchResult?,
                       identification: AIIdentification?,
                       userPhoto: UIImage?) async {
        state = .identifying
        let response = await recordManager.execute(AddRecordRequest(
            chosenResult: chosen,
            identification: identification,
            userPhoto: userPhoto,
            artworkPreference: artworkPreference,
            condition: condition,
            notes: notes.isEmpty ? nil : notes
        ))
        handleSaveResponse(response)
    }

    func addManually() async {
        guard !manualArtist.isEmpty, !manualAlbumTitle.isEmpty else {
            state = .failure("Artist and album title are required.")
            return
        }
        state = .identifying
        let response = await recordManager.execute(AddRecordRequest(
            artworkPreference: artworkPreference,
            condition: condition,
            notes: notes.isEmpty ? nil : notes,
            artistOverride: manualArtist,
            albumTitleOverride: manualAlbumTitle,
            yearOverride: Int(manualYear),
            labelOverride: manualLabel.isEmpty ? nil : manualLabel
        ))
        handleSaveResponse(response)
    }

    func reset() {
        state = .selectSource
        notes = ""
        manualArtist = ""
        manualAlbumTitle = ""
        manualYear = ""
        manualLabel = ""
    }

    // MARK: - Private

    private func handleSearchResponse(_ response: ResponseBase) {
        guard let result = response as? SearchRecordResponse else {
            state = .failure(response.errorMessage ?? "Search failed.")
            return
        }
        if !result.candidates.isEmpty {
            state = .showingDiscogsResults(
                candidates: result.candidates,
                identification: result.identification,
                userPhoto: result.userPhoto
            )
        } else if let id = result.identification, id.artist != nil || id.albumTitle != nil {
            // AI found something but no Discogs match — pre-fill manual entry
            manualArtist = id.artist ?? ""
            manualAlbumTitle = id.albumTitle ?? ""
            manualYear = id.year.map { String($0) } ?? ""
            manualLabel = id.label ?? ""
            state = .showingManualEntry
        } else {
            state = .failure(response.errorMessage ?? "No results found. Try manual entry.")
        }
    }

    private func handleSaveResponse(_ response: ResponseBase) {
        if let result = response as? AddRecordResponse, result.success,
           let title = result.displayTitle {
            state = .success(title)
        } else {
            state = .failure(response.errorMessage ?? "Failed to add record.")
        }
    }
}
