import Foundation

protocol IRecordAccessor {
    func store(_ request: RequestBase) async -> ResponseBase
    func load(_ request: RequestBase) async -> ResponseBase
    func remove(_ request: RequestBase) async -> ResponseBase
}
