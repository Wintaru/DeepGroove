import Foundation

final class ITunesAccessor: IITunesAccessor {
    private let loadResolver: HandlerResolver

    init(loadResolver: HandlerResolver) {
        self.loadResolver = loadResolver
    }

    func load(_ request: RequestBase) async -> ResponseBase { await loadResolver.resolve(request) }
}
