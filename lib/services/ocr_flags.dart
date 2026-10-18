/// Compile-time OCR safety switches.
///
/// Build with:
///   flutter build apk --dart-define=ENABLE_ML_KIT=false
/// to skip native ML Kit entirely (pick → preparing → empty review).
///
/// Chinese script is **on by default** (HK 繁/簡/英 cards). Disable only if a
/// device JNI-crashes on the Chinese pack:
///   --dart-define=ENABLE_ML_KIT_CHINESE=false
/// [_runScriptSafe] still soft-fails Chinese → Latin-only without crashing.
const bool kEnableMlKit =
    bool.fromEnvironment('ENABLE_ML_KIT', defaultValue: true);

const bool kEnableMlKitChinese =
    bool.fromEnvironment('ENABLE_ML_KIT_CHINESE', defaultValue: true);
