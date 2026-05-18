# Changelog

All notable changes to Deep Groove are documented here.
Format: `[version] – release date` followed by categorized changes.

---

## [1.1] – Unreleased

### Added
- Share extension — share any song from Apple Music; the extension immediately searches Discogs by artist, ranks results by fuzzy album-title match, and shows the best candidate for one-tap confirmation; "Not this one" reveals the full result list
- Wishlist "Find on Discogs" — swipe left on any wishlist item to search Discogs for it; confirming a result replaces the plain entry with the enriched Discogs record (thumbnail, label, genres)
- Wishlist delete — swipe right on any wishlist item to delete it
- Home screen widget (small) and lock screen widgets (circular, rectangular) — tap to open the camera and identify a record with AI, bypassing the source selection screen
- `deepgroove://add?source=camera` deep link scheme for widget integration

### Changed
- Discogs text search now uses artist-field search (fetches 40 results) with fuzzy album-title ranking so title formatting differences (e.g. "ROCKISDEAD" vs "Rock Is Dead") no longer prevent matches
- Share extension confirmation UI: instead of silently queuing the item, the extension now shows the Discogs result for user confirmation before saving
- Wishlist items saved via share extension now carry full Discogs metadata (thumbnail, label, genres) when a match is confirmed in the extension
- Enabled CloudKit sync (`cloudKitDatabase: .automatic`) — collection now syncs across all devices signed into the same Apple ID
- Debug builds use local SwiftData only (`cloudKitDatabase: .none`) to avoid polluting the production CloudKit container

### Infrastructure
- Discogs token mirrored to App Group UserDefaults on save so the share extension can authenticate API requests
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
