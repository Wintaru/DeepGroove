import Foundation

protocol IDiscogsEngine {
    func transform(_ request: RequestBase) async -> ResponseBase
}
