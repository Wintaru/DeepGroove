# Add Tests

You are a senior iOS engineer writing tests for this Swift project. The codebase
follows iDesign / Handler Resolver architecture — layers are Managers, Engines,
Accessors, and Utilities. All logic lives in Handler files under
`<Layer>/<Domain>/Handlers/`. Full layer rules are in CLAUDE.md.

---

## Step 1 — Identify the target

If `$ARGUMENTS` names a file or handler, read it. If no argument is given, read
the file open in the editor. Read enough surrounding context to understand:

- Which layer this belongs to (Engine, Manager, Accessor, Utility)
- What dependencies it takes (injected via init vs. hard-coded)
- Whether it is `@MainActor` (see the list in CLAUDE.md)
- Every code path and conditional branch

---

## Step 2 — Check test target

Read `project.yml`. If a `VinylCollectorTests` target is absent, you will need
to add one. Use this template:

```yaml
  VinylCollectorTests:
    type: bundle.unit-test
    platform: iOS
    deploymentTarget: "17.0"
    sources:
      - path: VinylCollectorTests
        excludes:
          - "**/.DS_Store"
    settings:
      base:
        SWIFT_VERSION: "5.10"
        SWIFT_STRICT_CONCURRENCY: targeted
    dependencies:
      - target: VinylCollector
```

Add the target to `project.yml`, create the `VinylCollectorTests/` directory,
and run `xcodegen generate` before writing any test files.

Also add the test target to the scheme's test action in `project.yml`:

```yaml
    test:
      config: Debug
      targets:
        - VinylCollectorTests
```

---

## Step 3 — Plan the tests

List every test case you intend to write before writing any code. For each test:

- Name it descriptively (`testMergeMetadata_discogsWinsOverAI`,
  `testComputeStatistics_emptyCollection`)
- Note the input, the expected output, and which branch it exercises

Present the plan. **Wait for the user to confirm before writing any code.**

---

## Step 4 — Write the tests

### Framework

Use **Swift Testing** (`import Testing`). Never use XCTest for new tests.

```swift
import Testing
@testable import VinylCollector

@Suite("ComputeStatisticsHandler")
struct ComputeStatisticsHandlerTests {

    @Test func emptyCollection() async {
        let handler = ComputeStatisticsHandler()
        let request = ComputeStatisticsRequest(records: [])
        let response = await handler.handle(request) as! ComputeStatisticsResponse
        #expect(response.statistics.totalRecords == 0)
    }
}
```

### What to test by layer

**Engine handlers** — highest priority. Pure logic, no mocks needed unless the
handler injects a dependency. Test every branch:
- Happy path with realistic input
- Guard failures: wrong request type → response is `UnhandledRequestResponse`
- Edge cases: empty arrays, nil optionals, boundary values (year range, etc.)
- Each distinct merge-priority path (e.g. override beats Discogs beats AI)

**Utilities** — pure functions. Test every public method, happy path and edges
(empty string, nil, malformed input).

**Manager handlers** — need lightweight mock stubs for each injected dependency.
Write a minimal `Mock<Interface>` struct or class inside the test file that
returns hard-coded responses. Test orchestration: correct dependencies called,
results mapped correctly, error paths short-circuit properly.

**Accessor handlers** — skip unless the user explicitly asks. They touch real
I/O and require heavier infrastructure.

### @MainActor handlers

Any handler listed as `@MainActor` in CLAUDE.md must have its test suite and
all individual test methods annotated `@MainActor` as well.

```swift
@MainActor
@Suite("SaveRecordHandler")
struct SaveRecordHandlerTests {
    @Test @MainActor func savesRecord() async { ... }
}
```

### File placement

Mirror the source tree under `VinylCollectorTests/`:

```
VinylCollectorTests/
  Engines/Statistics/Handlers/ComputeStatisticsHandlerTests.swift
  Engines/Metadata/Handlers/MergeMetadataHandlerTests.swift
  Engines/Identification/Handlers/ParseIdentificationHandlerTests.swift
  Common/Utilities/StringUtilityTests.swift
  Managers/Record/Handlers/SearchRecordHandlerTests.swift
  ...
```

### Mock stubs

Keep mocks small and co-located in the test file unless more than two test
suites need the same mock, in which case put it in
`VinylCollectorTests/Mocks/<ProtocolName>Mock.swift`.

```swift
// Minimal mock — only implement what the handler under test actually calls
final class MockRecordAccessor: IRecordAccessor {
    var stubbedLoadResponse: ResponseBase = LoadRecordResponse(...)

    func store(_ request: RequestBase) async -> ResponseBase { fatalError("not used") }
    func load(_ request: RequestBase) async -> ResponseBase { stubbedLoadResponse }
    func remove(_ request: RequestBase) async -> ResponseBase { fatalError("not used") }
}
```

---

## Step 5 — Stage and commit

Stage only the new/modified files by name. Then output the commit message as a
plain code block — no `git commit -m` wrapper, no heredoc, no Co-Authored-By
line. Wrap all lines at 80 characters.

```
add tests for ComputeStatisticsHandler

Cover all computation branches: top artists, genre/decade/condition
breakdown, estimated value totals, and recently-added ordering.
```
