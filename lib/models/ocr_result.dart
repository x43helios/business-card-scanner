import 'business_card_fields.dart';

enum OcrEngine { onDevice, cloud, stubDemo }

class OcrResult {
  final BusinessCardFields fields;
  final String rawText;
  final OcrEngine engine;
  final bool succeeded;
  final String? errorMessage;

  /// Field keys (from [BusinessCardFields.toMap], non-legacy) that the LLM
  /// contributed to in the final merged result. Empty when AI was not used.
  final Set<String> aiContributedFields;

  const OcrResult({
    required this.fields,
    this.rawText = '',
    required this.engine,
    this.succeeded = true,
    this.errorMessage,
    this.aiContributedFields = const {},
  });

  factory OcrResult.failure(OcrEngine engine, String message) => OcrResult(
        fields: const BusinessCardFields(),
        engine: engine,
        succeeded: false,
        errorMessage: message,
        aiContributedFields: const {},
      );

  OcrResult copyWith({
    BusinessCardFields? fields,
    String? rawText,
    OcrEngine? engine,
    bool? succeeded,
    String? errorMessage,
    Set<String>? aiContributedFields,
  }) {
    return OcrResult(
      fields: fields ?? this.fields,
      rawText: rawText ?? this.rawText,
      engine: engine ?? this.engine,
      succeeded: succeeded ?? this.succeeded,
      errorMessage: errorMessage ?? this.errorMessage,
      aiContributedFields: aiContributedFields ?? this.aiContributedFields,
    );
  }
}
