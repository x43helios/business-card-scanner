# 名片掃描 / Business Card Scanner

本地優先（local-first）的 Flutter MVP：拍攝／選取名片 → OCR → 檢視編輯欄位 → 儲存聯絡人（一聯絡人可多張名片）。

Local-first Flutter MVP: capture/pick a business card → OCR → review/edit fields → save. One Contact can hold many Cards.

**Repo:** https://github.com/x43helios/business-card-scanner-ios  
**Bundle ID (iOS):** `com.x43helios.businesscardscanner`  
**Application ID (Android):** `com.x43helios.business_card_scanner`  
**Display name:** 名片掃描

## Crash-hardening (v0.1.2)

Post-`image_picker` flow is deferred off the pick callback:

1. **Preparing…** route (copy + validate magic bytes + downscale) before any OCR
2. **Recognizing…** only after extra frame delay — never on the same stack as the picker result
3. ML Kit Latin + Chinese (Chinese default ON; disable with `--dart-define=ENABLE_ML_KIT_CHINESE=false`)
4. Full ML Kit bypass: `--dart-define=ENABLE_ML_KIT=false` → empty review fields
5. Errors append to app documents `crash_log.txt`

## Flutter version

Developed with:

- Flutter **3.35.5** (stable)
- Dart **3.9.2**

```bash
flutter --version
```

## MVP scope

| Feature | Status |
|--------|--------|
| Contact list + search + user-defined tag chips | ✅ |
| Scan: camera / gallery → OCR → review → save | ✅ |
| Merge dialog (name/company/phone/email heuristic) | ✅ |
| Contact detail + multi-card list + optional image | ✅ |
| Settings: language (EN / 繁中), save photo (default OFF), cloud OCR consent | ✅ |
| Export: vCard, CSV, PDF | ✅ |
| On-device OCR → cloud fallback + consent gate | ✅ |
| Android on-device OCR via Google ML Kit | ✅ (with demo/sidecar fallback) |
| iOS on-device OCR (ML Kit) | ⚠️ Podfile ready; build/run needs Mac/Xcode |
| Google / iCloud sync | ❌ placeholder only |
| Monetization | ❌ out of scope |

### OCR fields

name, title/position, company name, company address, personal phone, personal email, company phone, company email, fax, company website

### OCR policy

1. Try **on-device** first (`OnDeviceOcrService`):
   - Sibling `.txt` sidecar next to the image (same path + `.txt`)
   - Filename containing `demo` / `sample` → built-in sample card
   - **Android / iOS:** Google ML Kit Text Recognition (Chinese script, then Latin)
   - Otherwise fail so the coordinator may offer cloud
2. If on-device fails and user is not in local-only mode, prompt for **cloud OCR consent** (once).
3. Disagree → local-only thereafter; Agree → `CloudOcrService` stub (no API keys, no upload in MVP).

**Demo OCR on any platform:** use the in-app “Run demo OCR” button, or pick an image whose filename contains `demo` / `sample`. Optionally place a sidecar `image.jpg.txt` next to an image for custom parse text.

## How to run

```bash
git clone https://github.com/x43helios/business-card-scanner-ios.git
cd business-card-scanner-ios
flutter pub get
```

### Android

```bash
flutter run -d android
# or install a built APK:
flutter build apk --debug
# / release (signed with debug keystore by default):
flutter build apk --release
```

Install on a phone:

```bash
adb install -r build/app/outputs/flutter-apk/app-debug.apk
# or
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

Or copy the APK to the phone and open it (enable “Install unknown apps” if needed).

### iOS (requires macOS + Xcode)

**Simulator / IPA builds need a Mac.** Linux hosts cannot run Xcode, `pod install`, or the iOS Simulator.

```bash
flutter pub get
cd ios && pod install && cd ..
open ios/Runner.xcworkspace   # not .xcodeproj
# or:
flutter run -d ios
```

- Bundle ID: `com.x43helios.businesscardscanner`
- Deployment target: **iOS 15.5** (Google ML Kit)
- Camera / photo usage strings: `ios/Runner/Info.plist` (preserved)
- Podfile: Chinese ML Kit + `permission_handler` camera/photos macros
- Longer setup: [`ios/README.md`](ios/README.md)
- Feature parity checklist: [`docs/ios-test-checklist.md`](docs/ios-test-checklist.md)

On-device OCR on iOS uses the same Google ML Kit plugin as Android (Latin + Chinese). Demo OCR works without a camera.

### Linux desktop (limited)

```bash
flutter run -d linux   # if desktop enabled
# Prefer “Run demo OCR” — ML Kit is Android/iOS only.
```

## Project structure

```
lib/
  models/          # Contact, CardRecord, BusinessCardFields, settings, OCR result
  db/              # SQLite via sqflite
  services/
    ocr/           # OcrService, FieldParser, OnDevice (ML Kit), Cloud stub, OcrCoordinator
    export_service.dart
    contact_matcher.dart
    settings_service.dart
  providers/       # Provider (ChangeNotifier)
  screens/         # Home, scan flow, detail, settings
  widgets/
  l10n/            # EN + Traditional Chinese
```

## OCR next steps (Mac / production)

1. **iOS:** Apple Vision `VNRecognizeTextRequest` via MethodChannel  
   e.g. `com.x43helios.businesscardscanner/ocr`
2. Keep `OcrCoordinator` policy unchanged; only swap the platform path inside `OnDeviceOcrService`.
3. For cloud: call your backend from `CloudOcrService` after consent — **do not embed API keys in the client**.

## Stack

- Flutter + Dart, state: **Provider**
- Local DB: **sqflite**
- Camera/gallery: **image_picker**
- On-device OCR (Android/iOS): **google_mlkit_text_recognition**
- PDF: **pdf**; CSV/vCard: pure Dart
- Share exports: **share_plus**

## Crash fix (v1.0.1)

Photo take/upload no longer hard-crashes the app:

- Runtime camera / photos permission requests before pick
- `retrieveLostData()` after Android kills MainActivity during camera/gallery
- Image copied + validated before ML Kit
- OCR / processing wrapped so failures open manual review or a snackbar
- ProGuard keep rules for ML Kit in release builds

## License


Private repository — all rights reserved by the owner.
