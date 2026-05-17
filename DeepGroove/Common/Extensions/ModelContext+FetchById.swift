import Foundation
import SwiftData

protocol ModelWithUUID: PersistentModel {
    var id: UUID { get }
}

extension ModelContext {
    func fetchFirst<T: ModelWithUUID>(_ type: T.Type, id: UUID) throws -> T? {
        try fetch(FetchDescriptor<T>()).first(where: { $0.id == id })
    }
}
