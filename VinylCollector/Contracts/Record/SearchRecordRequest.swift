import Foundation

final class SearchRecordRequest: RequestBase, @unchecked Sendable {
    let source: AddRecordSource

    init(source: AddRecordSource) {
        self.source = source
        super.init()
    }
}
