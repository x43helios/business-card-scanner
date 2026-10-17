enum AppLanguage { system, english, traditionalChinese }

class AppSettings {
  final AppLanguage language;
  final bool saveCardPhoto;
  final bool cloudOcrConsentAsked;
  final bool cloudOcrConsentGranted;
  final bool localOnlyMode;

  const AppSettings({
    this.language = AppLanguage.system,
    this.saveCardPhoto = false,
    this.cloudOcrConsentAsked = false,
    this.cloudOcrConsentGranted = false,
    this.localOnlyMode = false,
  });

  AppSettings copyWith({
    AppLanguage? language,
    bool? saveCardPhoto,
    bool? cloudOcrConsentAsked,
    bool? cloudOcrConsentGranted,
    bool? localOnlyMode,
  }) {
    return AppSettings(
      language: language ?? this.language,
      saveCardPhoto: saveCardPhoto ?? this.saveCardPhoto,
      cloudOcrConsentAsked: cloudOcrConsentAsked ?? this.cloudOcrConsentAsked,
      cloudOcrConsentGranted:
          cloudOcrConsentGranted ?? this.cloudOcrConsentGranted,
      localOnlyMode: localOnlyMode ?? this.localOnlyMode,
    );
  }
}
