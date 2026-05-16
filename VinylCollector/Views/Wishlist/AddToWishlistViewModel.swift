import UIKit

enum AddToWishlistState {
    case selectSource
    case showingCamera
    case showingPhotoLibrary
    case showingBarcodeScanner
    case showingManualEntry
    case confirmingCrop(image: UIImage, detectedRect: CGRect?)
    case searching
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
final class AddToWishlistViewModel {
    var state: AddToWishlistState = .selectSource

    var manualArtist = ""
    var manualAlbumTitle = ""
    var manualYear = ""
    var manualLabel = ""

    var isLoadingMore = false

    private let recordManager: IRecordManager
    private let wishlistManager: IWishlistManager
    private let imageUtility = ImageUtility()

    init(recordManager: IRecordManager, wishlistManager: IWishlistManager) {
        self.recordManager = recordManager
        self.wishlistManager = wishlistManager
    }

    // MARK: - Source selection

    func selectCamera() { state = .showingCamera }
    func selectPhotoLibrary() { state = .showingPhotoLibrary }
    func selectBarcodeScanner() { state = .showingBarcodeScanner }
    func goToManualEntry() { state = .showingManualEntry }

    func reset() {
        state = .selectSource
        manualArtist = ""
        manualAlbumTitle = ""
        manualYear = ""
        manualLabel = ""
    }

    // MARK: - Search

    func photoSelected(_ image: UIImage) {
        let rect = imageUtility.detectCoverRect(in: image)
        state = .confirmingCrop(image: image, detectedRect: rect)
    }

    func searchWithCrop(_ image: UIImage, rect: CGRect?) async {
        let searchImage = rect.map { imageUtility.crop(image: image, to: $0) } ?? image
        await searchFromPhoto(searchImage)
    }

    func searchFromPhoto(_ image: UIImage) async {
        state = .searching
        let response = await recordManager.query(SearchRecordRequest(source: .photo(image)))
        handleSearchResponse(response)
    }

    func searchFromBarcode(_ barcode: String) async {
        state = .searching
        let response = await recordManager.query(SearchRecordRequest(source: .barcode(barcode)))
        handleSearchResponse(response)
    }

    func searchDiscogsFromManualFields() async {
        state = .searching
        let response = await recordManager.query(SearchRecordRequest(
            source: .text(artist: manualArtist, albumTitle: manualAlbumTitle)
        ))
        handleSearchResponse(response)
    }

    func selectNoMatch(identification: AIIdentification?) {
        manualArtist = identification?.artist ?? ""
        manualAlbumTitle = identification?.albumTitle ?? ""
        manualYear = identification?.year.map { String($0) } ?? ""
        manualLabel = identification?.label ?? ""
        state = .showingManualEntry
    }

    // MARK: - Save to wishlist

    func confirmResult(_ chosen: DiscogsSearchResult) async {
        state = .searching
        let response = await wishlistManager.execute(AddToWishlistRequest(chosenResult: chosen))
        handleSaveResponse(response)
    }

    func addManually() async {
        guard !manualArtist.isEmpty, !manualAlbumTitle.isEmpty else {
            state = .failure("Artist and album title are required.")
            return
        }
        state = .searching
        let response = await wishlistManager.execute(AddToWishlistRequest(
            artistOverride: manualArtist,
            albumTitleOverride: manualAlbumTitle,
            yearOverride: Int(manualYear),
            labelOverride: manualLabel.isEmpty ? nil : manualLabel
        ))
        handleSaveResponse(response)
    }

    // MARK: - Private

    func loadMoreResults() async {
        guard case let .showingDiscogsResults(existing, identification, currentPage, totalPages) = state,
              currentPage < totalPages,
              !manualArtist.isEmpty || !manualAlbumTitle.isEmpty else { return }
        isLoadingMore = true
        let response = await recordManager.query(SearchRecordRequest(
            source: .text(artist: manualArtist, albumTitle: manualAlbumTitle),
            page: currentPage + 1
        ))
        isLoadingMore = false
        guard let result = response as? SearchRecordResponse, result.success else { return }
        state = .showingDiscogsResults(
            candidates: existing + result.candidates,
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
        if let result = response as? AddToWishlistResponse, result.success,
           let title = result.displayTitle {
            state = .success(title)
        } else {
            state = .failure(response.errorMessage ?? "Failed to add to wishlist.")
        }
    }
}
