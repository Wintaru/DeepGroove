import Foundation

final class SearchDiscogsByBarcodeRequest: RequestBase, @unchecked Sendable {
    let barcode: String
    let token: String?
    let page: Int

    init(barcode: String, token: String? = nil, page: Int = 1) {
        self.barcode = barcode
        self.token = token
        self.page = page
        super.init()
    }
}
