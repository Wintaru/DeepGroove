# VinylCollector — Project Rules

## Architecture

This project follows iDesign / volatility-based decomposition with the Handler Resolver pattern.
See the global `~/.claude/CLAUDE.md` for the full layer rules and resolver pattern.

### Layer summary

| Layer | Location | Method names |
|---|---|---|
| Manager | `Managers/<Domain>/` | `execute` / `query` |
| Engine | `Engines/<Domain>/` | `evaluate` / `transform` |
| Accessor | `Accessors/<Domain>/` | `store` / `load` / `remove` |
| Utility | `Common/Utilities/` | (stateless helpers) |

All wiring is in `App/DependencyContainer.swift`. Never register handlers anywhere else.

---

## SwiftData rules — critical

### @MainActor isolation
Any handler that **creates, reads, or mutates a `@Model` object** must be `@MainActor`.
SwiftData model objects are tied to their `ModelContext`, which lives on `@MainActor`.
Accessing a `@Model` object off the main actor triggers CoreData fault resolution on the wrong
thread and causes the crash:
> `Fatal error: This backing data was detached from a context without resolving attribute faults`

Current `@MainActor` handlers:
- `SaveRecordHandler`, `LoadRecordHandler`, `LoadAllRecordsHandler`, `DeleteRecordHandler`
- `SavePhotoHandler`, `LoadPhotoHandler`, `DeletePhotoHandler`
- `AddRecordHandler`, `EditRecordHandler`, `RemoveRecordHandler`
- `GetStatisticsHandler`

Handlers that are safe off main actor (no SwiftData contact):
- `SearchRecordHandler`, `IdentifyRecordHandler`, `ParseIdentificationHandler`
- `MergeMetadataHandler`, `ComputeStatisticsHandler`
- All Discogs accessor handlers

### Deleting records from SwiftUI views
Two rules that must both be followed:

**Rule 1**: Never delete via an async `Task {}` in `onDelete` or confirmation dialogs.
By the time the task runs, SwiftUI's delete animation has started rendering the row, accessing
faulted attributes that no longer exist — crash.

**Rule 2**: Never call `modelContext.save()` inside the delete handler.
`save()` immediately detaches the record's backing data. SwiftUI's removal animation then tries
to render the disappearing row (to animate it out), accessing `artworkSource` (via `thumbnailPhoto`)
on the now-detached object — crash. Leave the save to SwiftData's autosave, which runs after the
animation settles.

**Correct pattern:**

```swift
@Environment(\.modelContext) private var modelContext

// In onDelete:
.onDelete { indexSet in
    for index in indexSet {
        guard displayRecords.indices.contains(index) else { continue }
        let record = displayRecords[index]
        let paths = record.photos?.map(\.photoPath) ?? []
        modelContext.delete(record)
        for path in paths { try? FileManager.default.removeItem(atPath: path) }
    }
    // No modelContext.save() here — autosave handles it after animation.
}

// In confirmation dialog:
Button("Delete", role: .destructive) {
    let paths = record.photos?.map(\.photoPath) ?? []
    modelContext.delete(record)
    for path in paths { try? FileManager.default.removeItem(atPath: path) }
    dismiss()
    // No modelContext.save() here — autosave handles it after dismiss animation.
}
```

### CloudKit-compatible model design
`ModelConfiguration` uses `cloudKitDatabase: .automatic`. CloudKit requires:
- All stored properties must have **default values** (no non-optional properties without defaults)
- All relationships must be **optional** (`[RecordPhoto]?` not `[RecordPhoto]`)
- **No `@Attribute(.unique)`** constraints — CloudKit handles its own record IDs
- Enums stored as raw values must have a default value expressed as the Swift type, not a string literal:
  `var condition: RecordCondition = RecordCondition.veryGoodPlus`

### SortDescriptor and #Predicate — avoid
`SortDescriptor(\.someProperty)` and `#Predicate { $0.id == id }` with SwiftData `@Model`
keypaths cause `KeyPath<Model, T> does not conform to Sendable` warnings/errors in strict
concurrency mode. Use in-memory sort/filter instead:

```swift
// Instead of SortDescriptor:
records.sorted { $0.artist < $1.artist }

// Instead of #Predicate:
let all = try modelContext.fetch(FetchDescriptor<VinylRecord>())
let match = all.first(where: { $0.id == id })
```

---

## SwiftUI + @Observable binding rules

ViewModels use `@Observable` (not `ObservableObject`). To get `$binding` syntax from an
`@Observable` object you **must** use `@Bindable`, not `@State`:

```swift
// In body or a sub-function:
@Bindable var model = vm
TextField("Artist", text: $model.manualArtist)  // works

// WRONG — computed properties cannot produce $ bindings:
private var model: SomeViewModel { ... }
TextField("Artist", text: $model.manualArtist)  // compile error
```

When a ViewModel depends on an environment object (e.g. `recordManager`), initialize it via
`State(initialValue:)` in the view's `init` rather than lazily:

```swift
@State private var vm: AddRecordViewModel

init(recordManager: IRecordManager) {
    _vm = State(initialValue: AddRecordViewModel(recordManager: recordManager))
}
```

---

## Concurrency mode

`SWIFT_STRICT_CONCURRENCY = targeted` in `project.yml`. After any `xcodegen generate`, verify
this setting is still in place. Do not use `complete` mode — SwiftData `@Model` keypaths used
in `SortDescriptor` generate false-positive errors that have no clean fix.

---

## CloudKit setup

- Bundle ID: `com.jdonner.vinylcollector`
- Team ID: `9C5WLPGP58`
- CloudKit container: `iCloud.com.jdonner.vinylcollector`
- Required entitlements: `icloud-services: [CloudKit]`, `icloud-container-identifiers`, `ubiquity-kvstore-identifier`
- Required Info.plist key: `UIBackgroundModes: [remote-notification]`

---

## API integrations

### Anthropic (AI identification)
- Endpoint: `https://api.anthropic.com/v1/messages`
- Model: `claude-sonnet-4-6`
- Headers: `x-api-key`, `anthropic-version: 2023-06-01`
- Key stored in `UserDefaults` via `APIConfiguration`. Entered by user in Settings tab.
- If key is missing, `SearchRecordHandler` returns a descriptive error immediately.

### Discogs
- Base URL: `https://api.discogs.com`
- Auth: `Authorization: Discogs token=<token>` header
- Token stored in `UserDefaults` via `APIConfiguration`. Entered by user in Settings tab.
- Barcode search is tried before text search — more precise results.
- Up to 8 candidates are returned to the picker; user selects the correct release.

---

## Add record flow (two-step)

1. **Search phase** (`SearchRecordRequest` → `SearchRecordHandler` → query resolver)
   - Photo source: Vision barcode detection first → Discogs barcode search
   - If no barcode: Claude AI identification → Discogs text search
   - Barcode scanner: direct Discogs barcode search
   - Returns up to 8 `DiscogsSearchResult` candidates

2. **Save phase** (`AddRecordRequest` → `AddRecordHandler` → execute resolver)
   - Takes the user's chosen `DiscogsSearchResult` (or nil for manual)
   - Loads full Discogs release details
   - Merges with AI identification via `MergeMetadataEngine`
   - Saves record, user photo, downloaded artwork

If no Discogs results found and AI identified something, manual entry is pre-filled with AI data.

---

## Project generation

Uses XcodeGen. After changing `project.yml`, run:
```
xcodegen generate
```
Then reopen `VinylCollector.xcodeproj` in Xcode.

Do not commit `.xcodeproj` — it is gitignored and regenerated from `project.yml`.
`VinylCollector/Configuration/Secrets.swift` is also gitignored.
