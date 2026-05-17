# Privacy Policy — VinylCollector

_Last updated: May 2026_

## Overview

VinylCollector is a personal iOS app for cataloguing your vinyl record collection. This policy describes what data the app accesses and how it is handled.

---

## Data We Collect

**We do not collect any personal data.** VinylCollector does not transmit any user data to the developer or to any analytics service.

---

## Data Stored on Your Device

The following data is stored **locally on your device only**:

- **Record collection** — artist, album title, year, genre, condition, notes, and estimated value for each record in your collection, stored via Apple's SwiftData framework and optionally synced to your personal iCloud account.
- **Photos** — photos you take or import of your records, stored in the app's local storage and optionally synced to iCloud.
- **API keys** — your Anthropic API key and Discogs token, stored in your device's local settings (UserDefaults). These keys are only used to make requests directly from your device to those services and are never transmitted to the developer.

---

## Third-Party Services

VinylCollector makes requests to the following third-party services **on your behalf**:

| Service | Purpose | Their Privacy Policy |
|---|---|---|
| **Discogs** (discogs.com) | Look up record metadata and artwork | https://www.discogs.com/privacy |
| **Anthropic** (anthropic.com) | AI-assisted record identification from photos | https://www.anthropic.com/privacy |

When you use AI identification, a photo of your record is sent directly from your device to Anthropic's API using your own API key. Anthropic's privacy policy governs how they handle that data.

When you search Discogs, your search query or barcode is sent directly from your device to Discogs using your own token.

---

## iCloud Sync

If you are signed into iCloud, your collection data and record photos may be synced to your personal iCloud account via CloudKit. This data is stored in your private iCloud database and is not accessible to the developer.

---

## Camera and Photo Library

VinylCollector requests access to your camera and photo library solely to allow you to photograph records and import existing photos. These images are stored locally on your device and optionally in your personal iCloud account. They are never uploaded to the developer.

---

## Children's Privacy

VinylCollector does not knowingly collect any information from children under 13.

---

## Changes to This Policy

If this policy changes, the updated version will be posted at this same URL with an updated date.

---

## Contact

If you have questions about this privacy policy, contact: jdonner@dontpaniclabs.com
