import Foundation

final class LoadDiscogsReleaseHandler: IHandler {
    private let networkUtility: NetworkUtility

    init(networkUtility: NetworkUtility) {
        self.networkUtility = networkUtility
    }

    func handle(_ request: RequestBase) async -> ResponseBase {
        guard let req = request as? LoadDiscogsReleaseRequest else {
            return UnhandledRequestResponse(correlationId: request.correlationId,
                                           requestType: String(describing: type(of: request)))
        }
        do {
            guard let url = URL(string: "\(DiscogsAPI.releaseURL)/\(req.releaseId)") else {
                return LoadDiscogsReleaseResponse(correlationId: req.correlationId,
                                                 errorMessage: NetworkError.invalidURL.localizedDescription)
            }
            let data = try await networkUtility.get(
                url: url,
                headers: DiscogsAPI.headers(token: req.token)
            )
            let decoded = try JSONDecoder().decode(DiscogsReleaseAPIResponse.self, from: data)
            let release = decoded.toRelease()
            return LoadDiscogsReleaseResponse(correlationId: req.correlationId, release: release)
        } catch {
            return LoadDiscogsReleaseResponse(correlationId: req.correlationId,
                                               errorMessage: error.localizedDescription)
        }
    }
}

// MARK: - Private API response types

private struct DiscogsReleaseAPIResponse: Decodable {
    let id: Int
    let title: String
    let artists: [DiscogsArtistAPI]?
    let year: Int?
    let labels: [DiscogsLabelAPI]?
    let genres: [String]?
    let styles: [String]?
    let country: String?
    let images: [DiscogsImageAPI]?
    let tracklist: [DiscogsTrackAPI]?
    let lowestPrice: Double?
    let numForSale: Int?

    enum CodingKeys: String, CodingKey {
        case id, title, artists, year, labels, genres, styles, country, images, tracklist
        case lowestPrice = "lowest_price"
        case numForSale = "num_for_sale"
    }

    func toRelease() -> DiscogsRelease {
        let primaryImage = images?.first(where: { $0.type == "primary" })?.uri
            ?? images?.first?.uri
        let secondaryImages = images?.filter { $0.type != "primary" }.map { $0.uri } ?? []

        return DiscogsRelease(
            id: id,
            title: title,
            artists: artists?.map { $0.name } ?? [],
            year: year,
            labels: labels?.map { DiscogsLabel(name: $0.name, catalogNumber: $0.catno) } ?? [],
            genres: genres ?? [],
            styles: styles ?? [],
            country: country,
            primaryImageURL: primaryImage,
            secondaryImageURLs: secondaryImages,
            tracklist: tracklist?.map {
                DiscogsTrack(position: $0.position, title: $0.title, duration: $0.duration)
            } ?? [],
            lowestPrice: lowestPrice,
            numForSale: numForSale
        )
    }
}

private struct DiscogsArtistAPI: Decodable { let name: String }
private struct DiscogsLabelAPI: Decodable { let name: String; let catno: String? }
private struct DiscogsImageAPI: Decodable { let type: String; let uri: String }
private struct DiscogsTrackAPI: Decodable {
    let position: String
    let title: String
    let duration: String?
}
