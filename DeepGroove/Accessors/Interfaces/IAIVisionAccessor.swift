import Foundation

protocol IAIVisionAccessor {
    func load(_ request: RequestBase) async -> ResponseBase
}
