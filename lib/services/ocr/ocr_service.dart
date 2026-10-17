import 'dart:io';

import '../../models/ocr_result.dart';

/// Abstract OCR engine.
///
/// Android: [OnDeviceOcrService] uses Google ML Kit Text Recognition when
/// available, with demo/sidecar fallbacks.
/// iOS: Apple Vision can be wired via MethodChannel behind the same interface
/// (requires macOS + Xcode — not available on this Linux build host).
abstract class OcrService {
  Future<OcrResult> recognize(File imageFile);
}
