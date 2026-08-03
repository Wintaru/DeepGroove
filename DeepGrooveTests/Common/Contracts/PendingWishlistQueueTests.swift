import Testing
@testable import DeepGroove

@Suite("PendingWishlistQueue")
struct PendingWishlistQueueTests {

    init() { _ = PendingWishlistQueue.drainAll() }

    @Test func enqueue_appendsRatherThanOverwriting() {
        #expect(PendingWishlistQueue.enqueue(PendingWishlistItem(artistOverride: "A", albumTitleOverride: "One")))
        #expect(PendingWishlistQueue.enqueue(PendingWishlistItem(artistOverride: "B", albumTitleOverride: "Two")))

        let drained = PendingWishlistQueue.drainAll()
        #expect(drained.count == 2)
        #expect(drained[0].artistOverride == "A")
        #expect(drained[1].artistOverride == "B")
    }

    @Test func drainAll_clearsTheQueue() {
        PendingWishlistQueue.enqueue(PendingWishlistItem(artistOverride: "A", albumTitleOverride: "One"))
        _ = PendingWishlistQueue.drainAll()

        #expect(PendingWishlistQueue.drainAll().isEmpty)
    }

    @Test func roundTrip_preservesChosenResultFieldsLosslessly() {
        let result = DiscogsSearchResult(
            id: 42, masterId: 7, isMaster: false, title: "Artist - Album",
            year: "1977", labels: ["Some Label"], catalogNumber: "CAT-1",
            genres: ["Rock, Prog", "Jazz"], styles: ["Fusion"], country: "US",
            thumbURL: "https://example.com/thumb.jpg", coverImageURL: nil, barcodes: ["123"]
        )
        PendingWishlistQueue.enqueue(PendingWishlistItem(chosenResult: result))

        let drained = PendingWishlistQueue.drainAll()
        #expect(drained.count == 1)
        #expect(drained[0].chosenResult == result)
    }

    @Test func drainAll_emptyQueue_returnsEmptyArray() {
        #expect(PendingWishlistQueue.drainAll().isEmpty)
    }
}
