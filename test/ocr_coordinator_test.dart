import 'dart:io';

import 'package:business_card_scanner/models/app_settings.dart';
import 'package:business_card_scanner/models/business_card_fields.dart';
import 'package:business_card_scanner/models/ocr_result.dart';
import 'package:business_card_scanner/services/ocr/ocr_coordinator.dart';
import 'package:business_card_scanner/services/ocr/ocr_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeOcr implements OcrService {
  _FakeOcr(this.result);
  final OcrResult result;

  @override
  Future<OcrResult> recognize(File imageFile) async => result;
}

void main() {
  late File tmp;

  setUp(() async {
    tmp = File('${Directory.systemTemp.path}/ocr_coord_test.jpg');
    await tmp.writeAsBytes([0xFF, 0xD8, 0xFF, 0xD9]);
  });

  tearDown(() async {
    if (await tmp.exists()) await tmp.delete();
  });

  test('returns on-device success without asking cloud', () async {
    var consentAsked = false;
    final coordinator = OcrCoordinator(
      onDevice: _FakeOcr(
        const OcrResult(
          fields: BusinessCardFields(name: 'Ada'),
          engine: OcrEngine.onDevice,
          succeeded: true,
        ),
      ),
      cloud: _FakeOcr(
        OcrResult.failure(OcrEngine.cloud, 'should not call'),
      ),
    );
    final result = await coordinator.recognize(
      imageFile: tmp,
      settings: const AppSettings(),
      persistSettings: (s) async => s,
      askCloudConsent: () async {
        consentAsked = true;
        return true;
      },
    );
    expect(result.succeeded, isTrue);
    expect(result.fields.name, 'Ada');
    expect(consentAsked, isFalse);
  });

  test('local-only mode does not call cloud after on-device failure', () async {
    var consentAsked = false;
    final coordinator = OcrCoordinator(
      onDevice: _FakeOcr(
        OcrResult.failure(OcrEngine.onDevice, 'no text'),
      ),
      cloud: _FakeOcr(
        const OcrResult(
          fields: BusinessCardFields(name: 'Cloud'),
          engine: OcrEngine.cloud,
          succeeded: true,
        ),
      ),
    );
    final result = await coordinator.recognize(
      imageFile: tmp,
      settings: const AppSettings(localOnlyMode: true),
      persistSettings: (s) async => s,
      askCloudConsent: () async {
        consentAsked = true;
        return true;
      },
    );
    expect(result.succeeded, isFalse);
    expect(consentAsked, isFalse);
  });

  test('asks consent then uses cloud when granted', () async {
    AppSettings? persisted;
    final coordinator = OcrCoordinator(
      onDevice: _FakeOcr(
        OcrResult.failure(OcrEngine.onDevice, 'no text'),
      ),
      cloud: _FakeOcr(
        const OcrResult(
          fields: BusinessCardFields(name: 'FromCloud'),
          engine: OcrEngine.cloud,
          succeeded: true,
        ),
      ),
    );
    final result = await coordinator.recognize(
      imageFile: tmp,
      settings: const AppSettings(),
      persistSettings: (s) async {
        persisted = s;
        return s;
      },
      askCloudConsent: () async => true,
    );
    expect(result.fields.name, 'FromCloud');
    expect(persisted?.cloudOcrConsentGranted, isTrue);
    expect(persisted?.localOnlyMode, isFalse);
  });

  test('disagree sets local-only and does not call cloud', () async {
    AppSettings? persisted;
    final coordinator = OcrCoordinator(
      onDevice: _FakeOcr(
        OcrResult.failure(OcrEngine.onDevice, 'no text'),
      ),
      cloud: _FakeOcr(
        const OcrResult(
          fields: BusinessCardFields(name: 'ShouldNot'),
          engine: OcrEngine.cloud,
          succeeded: true,
        ),
      ),
    );
    final result = await coordinator.recognize(
      imageFile: tmp,
      settings: const AppSettings(),
      persistSettings: (s) async {
        persisted = s;
        return s;
      },
      askCloudConsent: () async => false,
    );
    expect(result.succeeded, isFalse);
    expect(persisted?.localOnlyMode, isTrue);
    expect(persisted?.cloudOcrConsentGranted, isFalse);
  });
}
