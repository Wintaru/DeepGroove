import Foundation

protocol IWishlistManager {
    func execute(_ request: RequestBase) async -> ResponseBase
}
