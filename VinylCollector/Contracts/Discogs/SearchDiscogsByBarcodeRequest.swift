import Foundation

final class SearchDiscogsByBarcodeRequest: RequestBase {
    let barcode: String
    let token: String?

    init(barcode: String, token: String? = nil) {
        self.barcode = barcode
        self.token = token
        super.init()
    }
}
