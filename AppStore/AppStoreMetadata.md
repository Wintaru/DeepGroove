# App Store Metadata — Deep Groove

Reference doc for App Store Connect submission. Fill in URLs once hosting is set up.

---

## Identity

| Field | Value |
|---|---|
| **App Name** | Deep Groove |
| **Bundle ID** | com.jdonner.deepgroove |
| **SKU** | deepgroove-1 |
| **Primary Language** | English (U.S.) |
| **Primary Category** | Music |
| **Secondary Category** | Lifestyle |

---

## Version 1.0

### Description (max 4000 chars)

```
Deep Groove is the smartest way to catalogue your vinyl record collection.

Point your camera at a record sleeve and let AI identify it instantly — or scan the barcode for immediate, precise results. Deep Groove searches Discogs automatically to fill in the artist, album, year, genre, label, and tracklist, so you spend less time typing and more time listening.

KEY FEATURES

• AI Record Identification — Photograph any album cover and Claude AI identifies it for you, even without a barcode.
• Barcode Scanning — Scan EAN-13 and UPC barcodes for instant, accurate Discogs lookups.
• Full Discogs Metadata — Automatically fetches artist, title, release year, genre, label, country, tracklist, and cover artwork.
• Collection Management — Add, edit, and remove records. Track condition (Mint through Poor), personal notes, and purchase price.
• Filter & Sort — Browse your collection by genre, condition, decade, or artist. Full-text search across all fields.
• Collection Statistics — See your top artists, genre and decade breakdowns, condition distribution, and estimated collection value.
• Wishlist — Keep a wishlist of records you're hunting for, with the same Discogs-powered search.
• iCloud Sync — Your collection syncs privately across all your iPhones via iCloud.
• Share — Share any record's details via the iOS share sheet.

WHAT YOU NEED

To use AI identification, you'll need a free Anthropic API key (anthropic.com). To search Discogs, you'll need a free Discogs developer token (discogs.com). Both are entered in the app's Settings tab and stored only on your device.

PRIVACY

Deep Groove collects no personal data and sends nothing to the developer. Your collection lives on your device and in your private iCloud account. See the full privacy policy at https://wintaru.github.io/DeepGroove/privacy
```

### Subtitle (max 30 chars)

```
Your vinyl collection, catalogued
```

### Keywords (max 100 chars, comma-separated)

```
vinyl,records,collection,music,discogs,LP,album,catalog,turntable,wishlist
```

### Support URL

`https://github.com/Wintaru/DeepGroove/issues`

### Marketing URL (optional)

`[YOUR MARKETING URL]`

### Privacy Policy URL (required)

`https://wintaru.github.io/DeepGroove/privacy`

---

## Age Rating

Answer "None" to all content descriptor questions → **4+** rating.

---

## Pricing

Free (no in-app purchases).

---

## Screenshots Required

App Store requires at least **6.5" iPhone** (iPhone 14 Pro Max / 15 Plus). Recommended to also include **6.7" iPhone** (iPhone 16 Plus) and **5.5" iPhone** (iPhone 8 Plus) for broader coverage. Minimum 3, maximum 10 screenshots per device size.

Suggested screens to capture:
1. Collection list (populated with a few records)
2. Add record — barcode scanner or AI identification in progress
3. Discogs result picker
4. Record detail view
5. Statistics view
6. Filter/sort panel or Wishlist

---

## App Review Information

### Sign-in Required?
No.

### Notes for Reviewer
```
Deep Groove uses two third-party APIs that require user-supplied keys:
- Anthropic API key (for AI record identification from photos)
- Discogs developer token (for record metadata search)

Both keys are entered in Settings > API Keys. The app is fully functional for browsing and manual entry without keys. AI identification requires an Anthropic key; Discogs search requires a Discogs token.

If needed for review, a test Discogs token can be obtained free at discogs.com/settings/developers.
```

---

## Export Compliance

`ITSAppUsesNonExemptEncryption = NO` is set in Info.plist. The app uses standard HTTPS (TLS) provided by the OS and does not implement any custom encryption.

---

## Checklist Before Submitting Archive

- [ ] Build with Release configuration in Xcode
- [ ] Verify version (1.0) and build number (1) in Info.plist are correct
- [ ] Archive → Distribute App → App Store Connect
- [ ] Upload screenshots in App Store Connect (min: 6.5" iPhone)
- [ ] Enter privacy policy URL
- [ ] Enter support URL
- [ ] Set age rating (4+)
- [ ] Set pricing (Free)
- [ ] Submit for review
