import UIKit

enum AddToWishlistState {
    case selectSource
    case showingCamera
    case showingPhotoLibrary
    case showingBarcodeScanner
    case showingManualEntry
    case confirmingCrop(image: UIImage)
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
    var lastSearchSnapshot: SearchSnapshot?

    private let recordManager: IRecordManager
    private let wishlistManager: IWishlistManager
    private let imageUtility = ImageUtility()
    private var existingWishlistItemId: UUID?

    init(recordManager: IRecordManager, wishlistManager: IWishlistManager) {
        self.recordManager = recordManager
        self.wishlistManager = wishlistManager
    }

    init(recordManager: IRecordManager, wishlistManager: IWishlistManager,
         artist: String, albumTitle: String, year: String?, existingItemId: UUID? = nil) {
        self.recordManager = recordManager
        self.wishlistManager = wishlistManager
        self.manualArtist = artist
        self.manualAlbumTitle = albumTitle
        self.manualYear = year ?? ""
        self.existingWishlistItemId = existingItemId
        self.state = .showingManualEntry
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
        state = .confirmingCrop(image: image)
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
        if response.success, let id = existingWishlistItemId {
            _ = await wishlistManager.execute(RemoveFromWishlistRequest(itemId: id))
        }
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
        if response.success, let id = existingWishlistItemId {
            _ = await wishlistManager.execute(RemoveFromWishlistRequest(itemId: id))
        }
        handleSaveResponse(response)
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
        if !result.candidates.isEmpty {
            lastSearchSnapshot = SearchSnapshot(candidates: result.candidates, identification: result.identification,
                                                currentPage: result.currentPage, totalPages: result.totalPages,
                                                correctedArtist: result.correctedArtist)
            state = .showingDiscogsResults(
                candidates: result.candidates,
                identification: result.identification,
                currentPage: result.currentPage,
                totalPages: result.totalPages
            )
        } else {
            state = .noResults(response.errorMessage ?? "No results found. Try editing the artist or album title.")
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
