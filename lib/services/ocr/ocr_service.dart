import 'dart:io';

import '../../models/ocr_result.dart';

/// Abstract OCR engine. Production iOS should wire Apple Vision via platform
/// channels; Android can use ML Kit. MVP ships a realistic on-device stub.
abstract class OcrService {
  Future<OcrResult> recognize(File imageFile);
}
