/// Compile-time OCR safety switches.
///
/// Build with:
///   flutter build apk --dart-define=ENABLE_ML_KIT=false
/// to skip native ML Kit entirely (pick → preparing → empty review).
///
/// Chinese script pack has crashed some devices via JNI; keep it off unless
/// explicitly enabled:
///   --dart-define=ENABLE_ML_KIT_CHINESE=true
const bool kEnableMlKit =
    bool.fromEnvironment('ENABLE_ML_KIT', defaultValue: true);

const bool kEnableMlKitChinese =
    bool.fromEnvironment('ENABLE_ML_KIT_CHINESE', defaultValue: false);
