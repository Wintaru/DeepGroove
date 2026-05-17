import Foundation

protocol IStoreKitAccessor {
    func load(_ request: RequestBase) async -> ResponseBase
    func store(_ request: RequestBase) async -> ResponseBase
}
