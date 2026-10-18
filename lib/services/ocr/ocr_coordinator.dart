import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../models/app_settings.dart';
import '../../models/ocr_result.dart';
import '../crash_log.dart';
import 'ai_field_extractor.dart';
import 'cloud_ocr_service.dart';
import 'field_merge.dart';
import 'ocr_service.dart';
import 'on_device_ocr_service.dart';

typedef CloudConsentPrompt = Future<bool> Function();

/// Policy: on-device first → optional cloud → optional AI field extraction merge.
class OcrCoordinator {
  OcrCoordinator({
    OcrService? onDevice,
    OcrService? cloud,
    AiFieldExtractor? aiExtractor,
  })  : _onDevice = onDevice ?? OnDeviceOcrService(),
        _cloud = cloud ?? CloudOcrService(),
        _ai = aiExtractor ?? HttpAiFieldExtractor();

  final OcrService _onDevice;
  final OcrService _cloud;
  final AiFieldExtractor _ai;

  Future<OcrResult> recognize({
    required File imageFile,
    required AppSettings settings,
    required Future<AppSettings> Function(AppSettings) persistSettings,
    required CloudConsentPrompt askCloudConsent,
  }) async {
    try {
      final base = await _recognizeInner(
        imageFile: imageFile,
        settings: settings,
        persistSettings: persistSettings,
        askCloudConsent: askCloudConsent,
      );
      return await _maybeAiEnrich(base, settings);
    } catch (e, st) {
      debugPrint('OcrCoordinator.recognize failed: $e\n$st');
      return OcrResult.failure(OcrEngine.onDevice, 'OCR failed: $e');
    }
  }

  Future<OcrResult> _recognizeInner({
    required File imageFile,
    required AppSettings settings,
    required Future<AppSettings> Function(AppSettings) persistSettings,
    required CloudConsentPrompt askCloudConsent,
  }) async {
    final local = await _onDevice.recognize(imageFile);
    if (local.succeeded && !local.fields.isEmpty) {
      return local;
    }

    if (settings.localOnlyMode) {
      return local.succeeded
          ? local
          : OcrResult.failure(
              OcrEngine.onDevice,
              local.errorMessage ?? 'Local-only mode: on-device OCR failed.',
            );
    }

    var s = settings;
    if (!s.cloudOcrConsentAsked) {
      final granted = await askCloudConsent();
      s = s.copyWith(
        cloudOcrConsentAsked: true,
        cloudOcrConsentGranted: granted,
        localOnlyMode: !granted,
      );
      s = await persistSettings(s);
    }

    if (!s.cloudOcrConsentGranted) {
      return OcrResult.failure(
        OcrEngine.onDevice,
        local.errorMessage ??
            'On-device OCR failed and cloud OCR consent was declined.',
      );
    }

    final cloud = await _cloud.recognize(imageFile);
    if (cloud.succeeded) return cloud;
    if (local.succeeded && !local.fields.isEmpty) return local;
    return cloud;
  }

  /// After OCR: if AI enabled + rawText, extract JSON fields and merge with regex.
  Future<OcrResult> _maybeAiEnrich(OcrResult base, AppSettings settings) async {
    final raw = base.rawText.trim();
    if (raw.isEmpty) return base;

    final cfg = AiExtractConfig.resolve(
      enabled: settings.aiFieldExtractionEnabled,
      runtimeApiKey: settings.aiApiKey,
      runtimeBaseUrl: settings.aiBaseUrl,
      runtimeModel: settings.aiModel,
      runtimeProvider: settings.aiProvider,
    );
    if (!cfg.enabled || cfg.apiKey.isEmpty) return base;

    try {
      await CrashLog.log('OcrCoordinator: AI field extraction starting');
      final aiFields = await _ai.extract(raw, config: cfg);
      if (aiFields == null || aiFields.isEmpty) {
        await CrashLog.log('OcrCoordinator: AI returned empty — keeping regex');
        return base;
      }
      final regexFields = FieldParser.parse(raw);
      // AI + regex(raw), then fill any remaining empties from base OCR fields.
      final merged = FieldMerge.merge(ai: aiFields, regex: regexFields);
      final finalFields = FieldMerge.merge(ai: merged, regex: base.fields);
      await CrashLog.log('OcrCoordinator: AI merge done');
      return OcrResult(
        fields: finalFields,
        rawText: base.rawText,
        engine: base.engine,
        succeeded: !finalFields.isEmpty,
        errorMessage: base.errorMessage,
      );
    } catch (e, st) {
      await CrashLog.log('OcrCoordinator AI enrich soft-fail', e, st);
      return base;
    }
  }
}
