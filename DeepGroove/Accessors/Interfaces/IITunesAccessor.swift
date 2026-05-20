import Foundation

protocol IITunesAccessor: Sendable {
    func load(_ request: RequestBase) async -> ResponseBase
}
