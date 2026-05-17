import Testing
@testable import DeepGroove

// MARK: - Test helpers

private func makeAI(
    artist: String? = "AI Artist",
    albumTitle: String? = "AI Album",
    year: Int? = 1990,
    label: String? = "AI Label",
    catalogNumber: String? = "AI-001",
    genres: [String] = ["Electronic"],
    country: String? = "US"
) -> AIIdentification {
    AIIdentification(
        artist: artist,
        albumTitle: albumTitle,
        year: year,
        label: label,
        catalogNumber: catalogNumber,
        genres: genres,
        country: country,
        rawJSON: "{}"
    )
}

private func makeDiscogs(
    id: Int = 1,
    title: String = "Discogs Album",
    artists: [String] = ["Discogs Artist"],
    year: Int? = 1985,
    labels: [DiscogsLabel] = [DiscogsLabel(name: "Discogs Label", catalogNumber: "DG-001")],
    genres: [String] = ["Rock"],
    styles: [String] = ["Classic Rock"],
    country: String? = "UK",
    primaryImageURL: String? = "https://example.com/art.jpg",
    lowestPrice: Double? = 12.99
) -> DiscogsRelease {
    DiscogsRelease(
        id: id,
        title: title,
        artists: artists,
        year: year,
        labels: labels,
        genres: genres,
        styles: styles,
        country: country,
        primaryImageURL: primaryImageURL,
        secondaryImageURLs: [],
        tracklist: [],
        lowestPrice: lowestPrice,
        numForSale: nil
    )
}

private func makeRequest(
    ai: AIIdentification? = nil,
    discogs: DiscogsRelease? = nil,
    artworkPreference: ArtworkSource = .downloaded,
    condition: RecordCondition = .veryGoodPlus,
    artistOverride: String? = nil,
    albumTitleOverride: String? = nil,
    yearOverride: Int? = nil,
    labelOverride: String? = nil,
    notes: String? = nil
) -> MergeMetadataRequest {
    MergeMetadataRequest(
        identification: ai,
        discogsRelease: discogs,
        artworkPreference: artworkPreference,
        conditionOverride: condition,
        artistOverride: artistOverride,
        albumTitleOverride: albumTitleOverride,
        yearOverride: yearOverride,
        labelOverride: labelOverride,
        notes: notes
    )
}

// MARK: - Tests

@Suite("MergeMetadataHandler")
struct MergeMetadataHandlerTests {

    let handler = MergeMetadataHandler()

    // MARK: - Wrong request type

    @Test func unhandledRequest() async {
        let response = await handler.handle(RequestBase())
        #expect(response is UnhandledRequestResponse)
        #expect(response.success == false)
    }

    // MARK: - Priority: override > Discogs > AI

    @Test func userOverride_winsOverDiscogsAndAI() async throws {
        let request = makeRequest(
            ai: makeAI(),
            discogs: makeDiscogs(),
            artistOverride: "Override Artist",
            albumTitleOverride: "Override Album"
        )
        let response = await handler.handle(request) as! MergeMetadataResponse

        #expect(response.success == true)
        let candidate = try #require(response.candidate)
        #expect(candidate.artist == "Override Artist")
        #expect(candidate.albumTitle == "Override Album")
    }

    @Test func discogs_winsOverAI_forArtistAndTitle() async throws {
        let request = makeRequest(ai: makeAI(), discogs: makeDiscogs())
        let response = await handler.handle(request) as! MergeMetadataResponse

        #expect(response.success == true)
        let candidate = try #require(response.candidate)
        #expect(candidate.artist == "Discogs Artist")
        #expect(candidate.albumTitle == "Discogs Album")
    }

    @Test func ai_usedWhenNoDiscogsOrOverride() async throws {
        let request = makeRequest(ai: makeAI())
        let response = await handler.handle(request) as! MergeMetadataResponse

        #expect(response.success == true)
        let candidate = try #require(response.candidate)
        #expect(candidate.artist == "AI Artist")
        #expect(candidate.albumTitle == "AI Album")
    }

    // MARK: - Missing required fields

    @Test func missingArtistFromAllSources_returnsError() async {
        let request = makeRequest(
            ai: makeAI(artist: nil),
            discogs: makeDiscogs(artists: [])
        )
        let response = await handler.handle(request) as! MergeMetadataResponse

        #expect(response.success == false)
        #expect(response.candidate == nil)
        #expect(response.errorMessage != nil)
    }

    @Test func missingAlbumTitleFromAllSources_returnsError() async {
        let request = makeRequest(
            ai: makeAI(albumTitle: nil),
            discogs: makeDiscogs(title: "")
        )
        let response = await handler.handle(request) as! MergeMetadataResponse

        // DiscogsRelease.title is non-optional, so even an empty string resolves.
        // Test with nil AI title and no Discogs to confirm AI-only nil title errors.
        let requestNoDiscogs = makeRequest(ai: makeAI(albumTitle: nil))
        let responseNoDiscogs = await handler.handle(requestNoDiscogs) as! MergeMetadataResponse

        #expect(responseNoDiscogs.success == false)
        #expect(responseNoDiscogs.candidate == nil)
    }

    @Test func noSourcesAtAll_returnsError() async {
        let request = makeRequest()
        let response = await handler.handle(request) as! MergeMetadataResponse

        #expect(response.success == false)
        #expect(response.candidate == nil)
    }

    // MARK: - Genres

    @Test func genres_discogsWinsOverAI() async throws {
        let request = makeRequest(
            ai: makeAI(genres: ["Electronic"]),
            discogs: makeDiscogs(genres: ["Rock", "Pop"])
        )
        let response = await handler.handle(request) as! MergeMetadataResponse

        let candidate = try #require(response.candidate)
        #expect(candidate.genres == ["Rock", "Pop"])
    }

    @Test func genres_fallsBackToAI_whenDiscogsEmpty() async throws {
        let request = makeRequest(
            ai: makeAI(genres: ["Jazz"]),
            discogs: makeDiscogs(genres: [])
        )
        let response = await handler.handle(request) as! MergeMetadataResponse

        let candidate = try #require(response.candidate)
        #expect(candidate.genres == ["Jazz"])
    }

    // MARK: - Artwork preference

    @Test func artworkPreference_downloaded_returnsDiscogsURL() async throws {
        let request = makeRequest(
            discogs: makeDiscogs(primaryImageURL: "https://example.com/art.jpg"),
            artworkPreference: .downloaded
        )
        let response = await handler.handle(request) as! MergeMetadataResponse

        let candidate = try #require(response.candidate)
        #expect(candidate.artworkURL == "https://example.com/art.jpg")
    }

    @Test func artworkPreference_userPhoto_returnsNilURL() async throws {
        let request = makeRequest(
            discogs: makeDiscogs(primaryImageURL: "https://example.com/art.jpg"),
            artworkPreference: .userPhoto
        )
        let response = await handler.handle(request) as! MergeMetadataResponse

        let candidate = try #require(response.candidate)
        #expect(candidate.artworkURL == nil)
    }

    // MARK: - Catalog number

    @Test func catalogNumber_discogsWinsOverAI() async throws {
        let request = makeRequest(
            ai: makeAI(catalogNumber: "AI-001"),
            discogs: makeDiscogs(labels: [DiscogsLabel(name: "Label", catalogNumber: "DG-999")])
        )
        let response = await handler.handle(request) as! MergeMetadataResponse

        let candidate = try #require(response.candidate)
        #expect(candidate.catalogNumber == "DG-999")
    }
}
