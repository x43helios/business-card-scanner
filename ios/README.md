# iOS build notes

**Simulator builds and IPA/TestFlight require a Mac with Xcode.** This Linux CI/dev box cannot run `pod install`, `flutter build ios`, or the iOS Simulator.

## Prerequisites (Mac)

- macOS + Xcode (15+ recommended)
- CocoaPods (`sudo gem install cocoapods` or Homebrew)
- Flutter 3.35+ on PATH
- Apple ID (free for Simulator; paid Apple Developer for device/TestFlight)

## First-time setup

```bash
# From repo root
flutter pub get
cd ios
pod install
cd ..
open ios/Runner.xcworkspace   # use .xcworkspace, not .xcodeproj
```

In Xcode:

1. Select the **Runner** target → **Signing & Capabilities**
2. Team: your Apple ID / development team
3. Bundle ID: `com.x43helios.businesscardscanner` (already set)
4. Deployment target: **iOS 15.5** (required by Google ML Kit)

## Run on Simulator

```bash
flutter devices          # list simulators
flutter run -d ios
# or pick a device in Xcode and Run
```

Optional dart-defines (same as Android):

```bash
flutter run -d ios \
  --dart-define=CARD_AI_API_KEY="$CARD_AI_API_KEY" \
  --dart-define=CARD_AI_PROVIDER=openai \
  --dart-define=CARD_AI_BASE_URL=https://openrouter.ai/api/v1 \
  --dart-define=CARD_AI_MODEL=minimax/minimax-m3.1-flash:free
```

Never commit API keys. Prefer Settings → AI at runtime for day-to-day testing.

## Permissions

`Runner/Info.plist` already includes:

- `NSCameraUsageDescription`
- `NSPhotoLibraryUsageDescription`
- `NSPhotoLibraryAddUsageDescription`
- `CFBundleDisplayName` = Business Card Scanner

`Podfile` enables `permission_handler` macros for camera / photos only, and pulls `GoogleMLKit/TextRecognitionChinese` for HK bilingual OCR.

## IPA / TestFlight (later)

```bash
flutter build ipa
# Archive via Xcode → Distribute App → TestFlight
```

Needs a paid Apple Developer Program membership and valid signing certificates.

## Checklist

See [`../docs/ios-test-checklist.md`](../docs/ios-test-checklist.md) for feature parity testing vs Android.
