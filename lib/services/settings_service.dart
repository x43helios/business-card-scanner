import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';

class SettingsService {
  static const _kLanguage = 'language';
  static const _kSavePhoto = 'save_card_photo';
  static const _kConsentAsked = 'cloud_ocr_consent_asked';
  static const _kConsentGranted = 'cloud_ocr_consent_granted';
  static const _kLocalOnly = 'local_only_mode';

  Future<AppSettings> load() async {
    final p = await SharedPreferences.getInstance();
    final langIndex = p.getInt(_kLanguage) ?? 0;
    final language = AppLanguage.values[
        langIndex.clamp(0, AppLanguage.values.length - 1)];
    return AppSettings(
      language: language,
      saveCardPhoto: p.getBool(_kSavePhoto) ?? false,
      cloudOcrConsentAsked: p.getBool(_kConsentAsked) ?? false,
      cloudOcrConsentGranted: p.getBool(_kConsentGranted) ?? false,
      localOnlyMode: p.getBool(_kLocalOnly) ?? false,
    );
  }

  Future<AppSettings> save(AppSettings s) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kLanguage, s.language.index);
    await p.setBool(_kSavePhoto, s.saveCardPhoto);
    await p.setBool(_kConsentAsked, s.cloudOcrConsentAsked);
    await p.setBool(_kConsentGranted, s.cloudOcrConsentGranted);
    await p.setBool(_kLocalOnly, s.localOnlyMode);
    return s;
  }
}
