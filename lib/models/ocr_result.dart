import 'business_card_fields.dart';

enum OcrEngine { onDevice, cloud, stubDemo }

class OcrResult {
  final BusinessCardFields fields;
  final String rawText;
  final OcrEngine engine;
  final bool succeeded;
  final String? errorMessage;

  const OcrResult({
    required this.fields,
    this.rawText = '',
    required this.engine,
    this.succeeded = true,
    this.errorMessage,
  });

  factory OcrResult.failure(OcrEngine engine, String message) => OcrResult(
        fields: const BusinessCardFields(),
        engine: engine,
        succeeded: false,
        errorMessage: message,
      );
}
