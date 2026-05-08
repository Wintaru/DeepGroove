import Foundation

final class SearchRecordRequest: RequestBase {
    let source: AddRecordSource

    init(source: AddRecordSource) {
        self.source = source
        super.init()
    }
}
