import Foundation

protocol IMetadataEngine {
    func transform(_ request: RequestBase) async -> ResponseBase
}
