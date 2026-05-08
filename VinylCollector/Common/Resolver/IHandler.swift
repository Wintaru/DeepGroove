import Foundation

protocol IHandler: AnyObject, Sendable {
    func handle(_ request: RequestBase) async -> ResponseBase
}
