import 'dart:io';

import '../../models/ocr_result.dart';
import 'field_parser.dart';
import 'ocr_service.dart';

/// Cloud OCR stub — no API keys. Returns a soft failure unless a demo sidecar
/// is present. Wire a real provider only after user consent + your own backend.
class CloudOcrService implements OcrService {
  @override
  Future<OcrResult> recognize(File imageFile) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));

    final sidecar = File('${imageFile.path}.cloud.txt');
    if (await sidecar.exists()) {
      final text = await sidecar.readAsString();
      final fields = FieldParser.parse(text);
      return OcrResult(
        fields: fields,
        rawText: text,
        engine: OcrEngine.cloud,
        succeeded: !fields.isEmpty,
      );
    }

    // No keys / no network call in MVP.
    return OcrResult.failure(
      OcrEngine.cloud,
      'Cloud OCR is not configured in this MVP (no API keys). '
      'Consent was recorded; plug in your provider behind this service.',
    );
  }
}
