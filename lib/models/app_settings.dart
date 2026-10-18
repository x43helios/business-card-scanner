enum AppLanguage { system, english, traditionalChinese }

class AppSettings {
  final AppLanguage language;
  final bool saveCardPhoto;
  final bool cloudOcrConsentAsked;
  final bool cloudOcrConsentGranted;
  final bool localOnlyMode;

  /// When true and an API key is available, run AI field extraction after OCR.
  final bool aiFieldExtractionEnabled;

  /// Runtime API key (overrides dart-define CARD_AI_API_KEY when non-empty).
  /// Never logged or committed.
  final String aiApiKey;

  /// Optional overrides; empty → use dart-define defaults.
  final String aiBaseUrl;
  final String aiModel;
  final String aiProvider; // openai | gemini

  const AppSettings({
    this.language = AppLanguage.system,
    this.saveCardPhoto = false,
    this.cloudOcrConsentAsked = false,
    this.cloudOcrConsentGranted = false,
    this.localOnlyMode = false,
    this.aiFieldExtractionEnabled = false,
    this.aiApiKey = '',
    this.aiBaseUrl = '',
    this.aiModel = '',
    this.aiProvider = '',
  });

  AppSettings copyWith({
    AppLanguage? language,
    bool? saveCardPhoto,
    bool? cloudOcrConsentAsked,
    bool? cloudOcrConsentGranted,
    bool? localOnlyMode,
    bool? aiFieldExtractionEnabled,
    String? aiApiKey,
    String? aiBaseUrl,
    String? aiModel,
    String? aiProvider,
  }) {
    return AppSettings(
      language: language ?? this.language,
      saveCardPhoto: saveCardPhoto ?? this.saveCardPhoto,
      cloudOcrConsentAsked: cloudOcrConsentAsked ?? this.cloudOcrConsentAsked,
      cloudOcrConsentGranted:
          cloudOcrConsentGranted ?? this.cloudOcrConsentGranted,
      localOnlyMode: localOnlyMode ?? this.localOnlyMode,
      aiFieldExtractionEnabled:
          aiFieldExtractionEnabled ?? this.aiFieldExtractionEnabled,
      aiApiKey: aiApiKey ?? this.aiApiKey,
      aiBaseUrl: aiBaseUrl ?? this.aiBaseUrl,
      aiModel: aiModel ?? this.aiModel,
      aiProvider: aiProvider ?? this.aiProvider,
    );
  }
}
