import Foundation

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
