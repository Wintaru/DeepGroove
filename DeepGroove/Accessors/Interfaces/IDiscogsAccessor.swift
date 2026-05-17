import Foundation

protocol IDiscogsAccessor {
    func load(_ request: RequestBase) async -> ResponseBase
}
