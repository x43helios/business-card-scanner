import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';
import 'ocr/ai_flags.dart';

class SettingsService {
  static const _kLanguage = 'language';
  static const _kSavePhoto = 'save_card_photo';
  static const _kConsentAsked = 'cloud_ocr_consent_asked';
  static const _kConsentGranted = 'cloud_ocr_consent_granted';
  static const _kLocalOnly = 'local_only_mode';
  static const _kAiEnabled = 'ai_field_extraction_enabled';
  static const _kAiEnabledSet = 'ai_field_extraction_enabled_set';
  static const _kAiApiKey = 'ai_api_key';
  static const _kAiBaseUrl = 'ai_base_url';
  static const _kAiModel = 'ai_model';
  static const _kAiProvider = 'ai_provider';

  Future<AppSettings> load() async {
    final p = await SharedPreferences.getInstance();
    final langIndex = p.getInt(_kLanguage) ?? 0;
    final language = AppLanguage.values[
        langIndex.clamp(0, AppLanguage.values.length - 1)];

    final runtimeKey = p.getString(_kAiApiKey) ?? '';
    final effectiveKey =
        runtimeKey.trim().isNotEmpty ? runtimeKey.trim() : kCardAiApiKey;

    // Default AI toggle ON when a key exists, else OFF — unless user set it.
    final bool aiEnabled;
    if (p.getBool(_kAiEnabledSet) == true) {
      aiEnabled = p.getBool(_kAiEnabled) ?? false;
    } else {
      aiEnabled = effectiveKey.isNotEmpty;
    }

    return AppSettings(
      language: language,
      saveCardPhoto: p.getBool(_kSavePhoto) ?? false,
      cloudOcrConsentAsked: p.getBool(_kConsentAsked) ?? false,
      cloudOcrConsentGranted: p.getBool(_kConsentGranted) ?? false,
      localOnlyMode: p.getBool(_kLocalOnly) ?? false,
      aiFieldExtractionEnabled: aiEnabled,
      aiApiKey: runtimeKey,
      aiBaseUrl: p.getString(_kAiBaseUrl) ?? '',
      aiModel: p.getString(_kAiModel) ?? '',
      aiProvider: p.getString(_kAiProvider) ?? '',
    );
  }

  Future<AppSettings> save(AppSettings s) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kLanguage, s.language.index);
    await p.setBool(_kSavePhoto, s.saveCardPhoto);
    await p.setBool(_kConsentAsked, s.cloudOcrConsentAsked);
    await p.setBool(_kConsentGranted, s.cloudOcrConsentGranted);
    await p.setBool(_kLocalOnly, s.localOnlyMode);
    await p.setBool(_kAiEnabled, s.aiFieldExtractionEnabled);
    await p.setBool(_kAiEnabledSet, true);
    await p.setString(_kAiApiKey, s.aiApiKey);
    await p.setString(_kAiBaseUrl, s.aiBaseUrl);
    await p.setString(_kAiModel, s.aiModel);
    await p.setString(_kAiProvider, s.aiProvider);
    return s;
  }
}
