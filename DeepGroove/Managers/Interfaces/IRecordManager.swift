import Foundation

protocol IRecordManager {
    func execute(_ request: RequestBase) async -> ResponseBase
    func query(_ request: RequestBase) async -> ResponseBase
}
