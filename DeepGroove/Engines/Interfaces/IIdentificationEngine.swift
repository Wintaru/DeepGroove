import Foundation

protocol IIdentificationEngine {
    func evaluate(_ request: RequestBase) async -> ResponseBase
}
