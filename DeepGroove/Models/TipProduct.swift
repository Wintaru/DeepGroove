import Foundation

struct TipProduct: Identifiable, @unchecked Sendable {
    let id: String
    let displayName: String
    let displayPrice: String
    let priceDecimal: Decimal
}
