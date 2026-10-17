import 'dart:io';

import '../../models/app_settings.dart';
import '../../models/ocr_result.dart';
import 'cloud_ocr_service.dart';
import 'ocr_service.dart';
import 'on_device_ocr_service.dart';

typedef CloudConsentPrompt = Future<bool> Function();

/// Policy: on-device first → optional cloud if on-device fails and user consents.
class OcrCoordinator {
  OcrCoordinator({
    OcrService? onDevice,
    OcrService? cloud,
  })  : _onDevice = onDevice ?? OnDeviceOcrService(),
        _cloud = cloud ?? CloudOcrService();

  final OcrService _onDevice;
  final OcrService _cloud;

  Future<OcrResult> recognize({
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
    // Prefer returning local fields if any, else cloud failure.
    if (local.succeeded && !local.fields.isEmpty) return local;
    return cloud;
  }
}
