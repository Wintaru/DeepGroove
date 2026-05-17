import Foundation

protocol IHandler: AnyObject {
    func handle(_ request: RequestBase) async -> ResponseBase
}
