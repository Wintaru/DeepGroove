import Foundation

final class HandlerResolver: Sendable {
    private let handlers: [ObjectIdentifier: any IHandler]

    init(_ handlers: [ObjectIdentifier: any IHandler]) {
        self.handlers = handlers
    }

    func resolve(_ request: RequestBase) async -> ResponseBase {
        guard let handler = handlers[ObjectIdentifier(type(of: request))] else {
            return UnhandledRequestResponse(
                correlationId: request.correlationId,
                requestType: String(describing: type(of: request))
            )
        }
        return await handler.handle(request)
    }
}

final class HandlerResolverBuilder {
    private var handlers: [ObjectIdentifier: any IHandler] = [:]

    @discardableResult
    func register(_ handler: any IHandler, for requestType: RequestBase.Type) -> Self {
        handlers[ObjectIdentifier(requestType)] = handler
        return self
    }

    func build() -> HandlerResolver {
        HandlerResolver(handlers)
    }
}
