import UIKit

enum RecordInputMethod {
    case camera, photoLibrary, barcodeScanner, manualEntry

    var resumeState: AddRecordState {
        switch self {
        case .camera:        return .showingCamera
        case .photoLibrary:  return .showingPhotoLibrary
        case .barcodeScanner: return .showingBarcodeScanner
        case .manualEntry:   return .showingManualEntry
        }
    }

    var addAnotherLabel: String {
        switch self {
        case .camera:         return "Take Another Photo"
        case .photoLibrary:   return "Choose Another Photo"
        case .barcodeScanner: return "Scan Another"
        case .manualEntry:    return "Add Another Manually"
        }
    }
}

enum AddRecordState {
    case selectSource
    case showingCamera
    case showingPhotoLibrary
    case showingBarcodeScanner
    case showingManualEntry
    // Photo captured — waiting for user to confirm crop region before searching
    case confirmingCrop(image: UIImage, detectedRect: CGRect?)
    case identifying
    case showingDiscogsResults(
            candidates: [DiscogsSearchResult],
            identification: AIIdentification?,
            currentPage: Int,
            totalPages: Int)
    case success(String)
    case noResults(String)
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

    // Photo captured during the search phase — kept so manual entry can still attach it
    var pendingUserPhoto: UIImage?
    private(set) var lastUsedMethod: RecordInputMethod?

    var addAnotherLabel: String { lastUsedMethod?.addAnotherLabel ?? "Add Another" }
    var isLoadingMore = false

    private let recordManager: IRecordManager
    private let imageUtility = ImageUtility()
    private let onSuccess: (() -> Void)?

    init(recordManager: IRecordManager, onSuccess: (() -> Void)? = nil) {
        self.recordManager = recordManager
        self.onSuccess = onSuccess
    }

    // MARK: - Source selection

    func selectCamera() {
        lastUsedMethod = .camera
        state = .showingCamera
    }

    func selectPhotoLibrary() {
        lastUsedMethod = .photoLibrary
        state = .showingPhotoLibrary
    }

    func selectBarcodeScanner() {
        lastUsedMethod = .barcodeScanner
        state = .showingBarcodeScanner
    }

    // Clears the remembered method and returns to source selection.
    func chooseDifferentMethod() {
        lastUsedMethod = nil
        state = .selectSource
    }

    // MARK: - Step 1: Search

    // Called immediately after photo capture — detects the cover rect and shows crop confirmation.
    func photoSelected(_ image: UIImage) {
        let rect = imageUtility.detectCoverRect(in: image)
        state = .confirmingCrop(image: image, detectedRect: rect)
    }

    // Called from the crop confirmation screen — crops if a rect was chosen, then searches.
    func searchWithCrop(_ image: UIImage, rect: CGRect?) async {
        let searchImage = rect.map { imageUtility.crop(image: image, to: $0) } ?? image
        await searchFromPhoto(searchImage)
    }

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
        lastUsedMethod = .manualEntry
        state = .showingManualEntry
    }

    func selectNoMatch(identification: AIIdentification?) {
        manualArtist = identification?.artist ?? ""
        manualAlbumTitle = identification?.albumTitle ?? ""
        manualYear = identification?.year.map { String($0) } ?? ""
        manualLabel = identification?.label ?? ""
        state = .showingManualEntry
    }

    func searchDiscogsFromManualFields() async {
        state = .identifying
        let response = await recordManager.query(SearchRecordRequest(
            source: .text(artist: manualArtist, albumTitle: manualAlbumTitle)
        ))
        handleSearchResponse(response)
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
            userPhoto: pendingUserPhoto,
            artworkPreference: pendingUserPhoto != nil ? .userPhoto : artworkPreference,
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
        state = lastUsedMethod?.resumeState ?? .selectSource
        notes = ""
        manualArtist = ""
        manualAlbumTitle = ""
        manualYear = ""
        manualLabel = ""
        pendingUserPhoto = nil
    }

    // MARK: - Private

    func loadMoreResults() async {
        let maxCandidates = 40
        guard case let .showingDiscogsResults(existing, identification, currentPage, totalPages) = state,
              currentPage < totalPages,
              existing.count < maxCandidates,
              !manualArtist.isEmpty || !manualAlbumTitle.isEmpty else { return }
        isLoadingMore = true
        let response = await recordManager.query(SearchRecordRequest(
            source: .text(artist: manualArtist, albumTitle: manualAlbumTitle),
            page: currentPage + 1
        ))
        isLoadingMore = false
        guard let result = response as? SearchRecordResponse, result.success else { return }
        let combined = (existing + result.candidates).prefix(maxCandidates)
        state = .showingDiscogsResults(
            candidates: Array(combined),
            identification: identification,
            currentPage: result.currentPage,
            totalPages: result.totalPages
        )
    }

    private func handleSearchResponse(_ response: ResponseBase) {
        guard let result = response as? SearchRecordResponse else {
            state = .failure(response.errorMessage ?? "Search failed.")
            return
        }
        if let photo = result.userPhoto {
            pendingUserPhoto = photo
        }
        if !result.candidates.isEmpty {
            state = .showingDiscogsResults(
                candidates: result.candidates,
                identification: result.identification,
                currentPage: result.currentPage,
                totalPages: result.totalPages
            )
        } else if let id = result.identification,
                  id.artist != nil || id.albumTitle != nil {
            manualArtist = id.artist ?? ""
            manualAlbumTitle = id.albumTitle ?? ""
            manualYear = id.year.map { String($0) } ?? ""
            manualLabel = id.label ?? ""
            state = .showingManualEntry
        } else {
            state = .noResults(response.errorMessage ?? "No results found. Try adding it manually.")
        }
    }

    private func handleSaveResponse(_ response: ResponseBase) {
        if let result = response as? AddRecordResponse, result.success,
           let title = result.displayTitle {
            state = .success(title)
            onSuccess?()
        } else {
            state = .failure(response.errorMessage ?? "Failed to add record.")
        }
    }
}
