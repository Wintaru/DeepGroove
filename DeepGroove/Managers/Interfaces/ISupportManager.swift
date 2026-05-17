import Foundation

protocol ISupportManager {
    func query(_ request: RequestBase) async -> ResponseBase
    func execute(_ request: RequestBase) async -> ResponseBase
}
