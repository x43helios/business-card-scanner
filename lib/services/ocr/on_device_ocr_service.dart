import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../../models/ocr_result.dart';
import '../crash_log.dart';
import '../ocr_flags.dart';
import 'field_parser.dart';
import 'ocr_service.dart';

export 'field_parser.dart';

/// On-device OCR with graceful fallback chain:
/// 1. Sibling `.txt` sidecar (tests / custom parse)
/// 2. Filename containing `demo` / `sample` → built-in sample card
/// 3. Google ML Kit Text Recognition (Android / iOS) — Latin, optional Chinese
/// 4. Failure → [OcrCoordinator] may prompt for cloud consent
///
/// iOS Apple Vision is not wired on this Linux build host (no Mac/Xcode).
class OnDeviceOcrService implements OcrService {
  @override
  Future<OcrResult> recognize(File imageFile) async {
    try {
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

      if (!kEnableMlKit) {
        await CrashLog.log('OnDeviceOcr: ML Kit disabled by flag');
        return OcrResult.failure(
          OcrEngine.onDevice,
          'ML Kit disabled (ENABLE_ML_KIT=false).',
        );
      }

      if (!await _isUsableImage(imageFile)) {
        return OcrResult.failure(
          OcrEngine.onDevice,
          'Image file is missing, empty, or not a supported format.',
        );
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
    } catch (e, st) {
      await CrashLog.log('OnDeviceOcrService.recognize failed', e, st);
      return OcrResult.failure(
        OcrEngine.onDevice,
        'On-device OCR error: $e',
      );
    }
  }

  static Future<bool> _isUsableImage(File imageFile) async {
    try {
      if (!await imageFile.exists()) return false;
      final len = await imageFile.length();
      if (len < 32) return false;
      final header = await imageFile.openRead(0, 12).first;
      if (header.length < 3) return false;
      final jpeg = header[0] == 0xFF && header[1] == 0xD8 && header[2] == 0xFF;
      final png = header.length >= 4 &&
          header[0] == 0x89 &&
          header[1] == 0x50 &&
          header[2] == 0x4E &&
          header[3] == 0x47;
      final gif = header.length >= 4 &&
          header[0] == 0x47 &&
          header[1] == 0x49 &&
          header[2] == 0x46;
      final webp = header.length >= 12 &&
          header[0] == 0x52 &&
          header[1] == 0x49 &&
          header[2] == 0x46 &&
          header[3] == 0x46 &&
          header[8] == 0x57 &&
          header[9] == 0x45 &&
          header[10] == 0x42 &&
          header[11] == 0x50;
      return jpeg || png || gif || webp;
    } catch (_) {
      return false;
    }
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
  /// Never lets Dart exceptions escape — native SIGSEGV cannot be caught.
  Future<OcrResult?> _recognizeWithMlKit(File imageFile) async {
    try {
      final path = imageFile.path;
      if (path.isEmpty) return null;

      await CrashLog.log('ML Kit: InputImage.fromFilePath');
      final InputImage input;
      try {
        input = InputImage.fromFilePath(path);
      } catch (e, st) {
        await CrashLog.log('ML Kit InputImage.fromFilePath failed', e, st);
        return null;
      }

      // Latin first — Chinese script pack has JNI-crashed some devices.
      await CrashLog.log('ML Kit: latin processImage');
      final latin = await _runScriptSafe(input, TextRecognitionScript.latin);

      var chinese = '';
      if (kEnableMlKitChinese) {
        await CrashLog.log('ML Kit: chinese processImage');
        chinese = await _runScriptSafe(input, TextRecognitionScript.chinese);
      } else {
        await CrashLog.log('ML Kit: chinese skipped (ENABLE_ML_KIT_CHINESE=false)');
      }

      var text = chinese.trim().length >= latin.trim().length ? chinese : latin;
      if (text.trim().isEmpty) {
        text = latin.trim().isNotEmpty ? latin : chinese;
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
    } catch (e, st) {
      await CrashLog.log('ML Kit OCR unavailable/failed', e, st);
      return null;
    }
  }

  Future<String> _runScriptSafe(
    InputImage input,
    TextRecognitionScript script,
  ) async {
    try {
      return await _runScript(input, script);
    } catch (e, st) {
      await CrashLog.log('ML Kit script $script failed', e, st);
      return '';
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
      try {
        await recognizer.close();
      } catch (e) {
        debugPrint('TextRecognizer.close failed: $e');
      }
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
