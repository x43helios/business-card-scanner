import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../../models/ocr_result.dart';
import 'field_parser.dart';
import 'ocr_service.dart';

export 'field_parser.dart';

/// On-device OCR with graceful fallback chain:
/// 1. Sibling `.txt` sidecar (tests / custom parse)
/// 2. Filename containing `demo` / `sample` → built-in sample card
/// 3. Google ML Kit Text Recognition (Android / iOS) — Chinese then Latin
/// 4. Failure → [OcrCoordinator] may prompt for cloud consent
///
/// iOS Apple Vision is not wired on this Linux build host (no Mac/Xcode).
/// Keep [OcrCoordinator] + this interface; swap ML Kit / Vision behind it.
class OnDeviceOcrService implements OcrService {
  @override
  Future<OcrResult> recognize(File imageFile) async {
    final sidecar = File('${imageFile.path}.txt');
    if (await sidecar.exists()) {
      final text = await sidecar.readAsString();
      final fields = FieldParser.parse(text);
      return OcrResult(
        fields: fields,
        rawText: text,
        engine: OcrEngine.onDevice,
        succeeded: !fields.isEmpty,
      );
    }

    final name = imageFile.uri.pathSegments.last.toLowerCase();
    if (name.contains('demo') || name.contains('sample')) {
      return _demoResult();
    }

    if (_mlKitSupported) {
      final ml = await _recognizeWithMlKit(imageFile);
      if (ml != null) return ml;
    }

    return OcrResult.failure(
      OcrEngine.onDevice,
      'On-device OCR found no text. '
      'On Android/iOS, ML Kit is used when available; '
      'use demo OCR or a .txt sidecar on unsupported platforms.',
    );
  }

  static bool get _mlKitSupported {
    if (kIsWeb) return false;
    try {
      return Platform.isAndroid || Platform.isIOS;
    } catch (_) {
      return false;
    }
  }

  /// Returns null when ML Kit is unavailable or yields empty text.
  Future<OcrResult?> _recognizeWithMlKit(File imageFile) async {
    try {
      final input = InputImage.fromFilePath(imageFile.path);
      // Chinese script handles CJK cards common in HK/TW; falls back to Latin.
      var text = await _runScript(input, TextRecognitionScript.chinese);
      if (text.trim().isEmpty) {
        text = await _runScript(input, TextRecognitionScript.latin);
      }
      if (text.trim().isEmpty) return null;

      final fields = FieldParser.parse(text);
      return OcrResult(
        fields: fields,
        rawText: text,
        engine: OcrEngine.onDevice,
        succeeded: !fields.isEmpty,
        errorMessage: fields.isEmpty
            ? 'ML Kit returned text but no card fields could be parsed.'
            : null,
      );
    } catch (e) {
      debugPrint('ML Kit OCR unavailable/failed: $e');
      return null;
    }
  }

  Future<String> _runScript(
    InputImage input,
    TextRecognitionScript script,
  ) async {
    final recognizer = TextRecognizer(script: script);
    try {
      final result = await recognizer.processImage(input);
      return result.text;
    } finally {
      await recognizer.close();
    }
  }

  OcrResult _demoResult() {
    const sample = '''
陳大文
產品經理
Helios Technology Ltd.
香港中環皇后大道中 88 號
Mobile: +852 9123 4567
Email: david.chan@helios.example
Tel: +852 2123 4567
Fax: +852 2123 4568
www.helios.example
''';
    final fields = FieldParser.parse(sample);
    return OcrResult(
      fields: fields,
      rawText: sample,
      engine: OcrEngine.stubDemo,
      succeeded: true,
    );
  }
}
