# Changelog

All notable changes to Deep Groove are documented here.
Format: `[version] – release date` followed by categorized changes.

---

## [1.1] – Unreleased

### Added
- Home screen widget (small) and lock screen widgets (circular, rectangular) — tap to open the camera and identify a record with AI, bypassing the source selection screen
- `deepgroove://add?source=camera` deep link scheme for widget integration

### Changed
- Enabled CloudKit sync (`cloudKitDatabase: .automatic`) — collection now syncs across all devices signed into the same Apple ID

### Infrastructure
- Fastlane `beta` and `release` lanes for versioned, gated App Store submissions

---

## [1.0] – Initial Release

### Added
- Vinyl record collection management with SwiftData persistence
- AI-powered record identification via Anthropic Claude (photo → artist, title, year, label, genres)
- Discogs integration — barcode search, text search, full release detail loading, up to 8 candidate results with pagination
- Two-step add flow: search phase (photo, barcode scan, photo library, manual text) → save phase (Discogs picker or manual entry)
- Album art crop confirmation with Vision-based cover rectangle detection
- Artwork sourcing preference: downloaded from Discogs or user-captured photo
- Record condition grading (VG+, VG, G+, etc.) and freeform notes
- Collection browsing with search, sort, and filter
- Record detail view
- Wishlist with Discogs-backed search
- Collection statistics dashboard (total records, genres, decades, most recently added, etc.)
- Settings: Anthropic and Discogs API key entry, tip jar (StoreKit), privacy policy
- iDesign / Handler Resolver architecture throughout
- CloudKit entitlements wired (container `iCloud.com.jdonner.deepgroove`)
