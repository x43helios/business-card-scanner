# 名片掃描 / Business Card Scanner

本地優先（local-first）的 Flutter MVP：拍攝／選取名片 → OCR → 檢視編輯欄位 → 儲存聯絡人（一聯絡人可多張名片）。

Local-first Flutter MVP: capture/pick a business card → OCR → review/edit fields → save. One Contact can hold many Cards.

**Repo:** https://github.com/x43helios/business-card-scanner-ios  
**Bundle ID (iOS):** `com.x43helios.businesscardscanner`  
**Application ID (Android):** `com.x43helios.business_card_scanner`  
**Display name:** 名片掃描

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
| iOS Apple Vision | ⚠️ stub interface only (needs Mac/Xcode) |
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

```bash
cd ios
pod install   # if needed
cd ..
open ios/Runner.xcworkspace
# or:
flutter run -d ios
```

Camera / photo library usage strings are in `ios/Runner/Info.plist`.

Apple Vision is **not** wired yet (no Mac on the CI/build host). Keep `OcrCoordinator` + `OnDeviceOcrService`; replace the ML Kit call site with a Vision MethodChannel on a Mac when ready. Demo OCR still works on iOS Simulator.

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

## License

Private repository — all rights reserved by the owner.
