import SwiftData

enum AppSchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 1, 0)
    static var models: [any PersistentModel.Type] = [VinylRecord.self, RecordPhoto.self, WishlistRecord.self]
}
