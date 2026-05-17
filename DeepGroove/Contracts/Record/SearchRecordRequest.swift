import Foundation

final class SearchRecordRequest: RequestBase, @unchecked Sendable {
    let source: AddRecordSource
    let page: Int

    init(source: AddRecordSource, page: Int = 1) {
        self.source = source
        self.page = page
        super.init()
    }
}
