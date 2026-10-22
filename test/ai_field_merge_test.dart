import 'package:business_card_scanner/models/app_settings.dart';
import 'package:business_card_scanner/models/business_card_fields.dart';
import 'package:business_card_scanner/models/ocr_result.dart';
import 'package:business_card_scanner/services/ocr/ai_field_extractor.dart';
import 'package:business_card_scanner/services/ocr/field_merge.dart';
import 'package:business_card_scanner/services/ocr/field_parser.dart';
import 'package:business_card_scanner/services/ocr/ocr_coordinator.dart';
import 'package:business_card_scanner/services/ocr/ocr_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:io';

const gloryRaw = '''
港恩中醫診所
GLORY-IN CHINESE MEDICAL CLINIC
張敏芝
Cathy Cheung
註冊中醫師 R.C.M.P.(註冊編號 : 007014)
香港浸會大學中醫學碩士(內科專業)
香港中文大學中醫學學士
Whatsapp : 5996 1224
E-mail : cathymanchi@gloryin.com
www.chinesedoctor.com.hk
www.gloryin.com
''';

BusinessCardFields gloryAiFields() => const BusinessCardFields(
      chineseName: '張敏芝',
      englishName: 'Cathy Cheung',
      companyNameChinese: '港恩中醫診所',
      companyNameEnglish: 'GLORY-IN CHINESE MEDICAL CLINIC',
      qualifications: '註冊中醫師 R.C.M.P.(註冊編號 : 007014)',
      education: '香港浸會大學中醫學碩士(內科專業) · 香港中文大學中醫學學士',
      whatsapp: '5996 1224',
      personalPhone: '5996 1224',
      personalEmail: 'cathymanchi@gloryin.com',
      companyWebsite: 'www.gloryin.com',
    );

class _FakeOcr implements OcrService {
  _FakeOcr(this.result);
  final OcrResult result;
  @override
  Future<OcrResult> recognize(File imageFile) async => result;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('parseAiJson strips fences and maps fields', () {
    const raw = '''
```json
{"chineseName":"張敏芝","englishName":"Cathy Cheung","companyWebsite":"www.gloryin.com"}
```
''';
    final f = parseAiJson(raw);
    expect(f, isNotNull);
    expect(f!.chineseName, '張敏芝');
    expect(f.englishName, 'Cathy Cheung');
    expect(f.companyWebsite, contains('gloryin'));
  });

  test('FieldMerge prefers AI names/company and keeps regex contacts', () {
    final regex = FieldParser.parse(gloryRaw);
    // AI misses email; has strong names
    const ai = BusinessCardFields(
      chineseName: '張敏芝',
      englishName: 'Cathy Cheung',
      companyNameChinese: '港恩中醫診所',
      companyNameEnglish: 'GLORY-IN CHINESE MEDICAL CLINIC',
      qualifications: '註冊中醫師 R.C.M.P.',
      education: '香港浸會大學中醫學碩士',
      companyWebsite: 'www.gloryin.com',
    );
    final m = FieldMerge.merge(ai: ai, regex: regex);
    expect(m.chineseName, '張敏芝');
    expect(m.englishName, 'Cathy Cheung');
    expect(m.companyNameChinese, contains('港恩'));
    expect(m.companyNameEnglish!.toUpperCase(), contains('GLORY'));
    expect(m.personalEmail, contains('cathymanchi@gloryin.com'));
    expect(m.whatsapp ?? m.personalPhone, contains('5996'));
    expect(m.companyWebsite, contains('gloryin.com'));
    expect(m.qualifications, contains('註冊中醫師'));
  });

  test('Fake AI + regex gold text yields strong Glory-In fields', () {
    final regex = FieldParser.parse(gloryRaw);
    final ai = gloryAiFields();
    final m = FieldMerge.merge(ai: ai, regex: regex);
    expect(m.chineseName, '張敏芝');
    expect(m.englishName, 'Cathy Cheung');
    expect(m.companyNameChinese, contains('港恩'));
    expect(m.companyNameEnglish!.toUpperCase(), contains('GLORY-IN'));
    expect(m.whatsapp, contains('5996'));
    expect(m.personalEmail, 'cathymanchi@gloryin.com');
    expect(m.companyWebsite, 'www.gloryin.com');
  });

  test('AI failure soft-falls to regex-only via coordinator', () async {
    final tmp = File('${Directory.systemTemp.path}/ai_fail_ocr.jpg');
    await tmp.writeAsBytes([0xFF, 0xD8, 0xFF, 0xD9]);
    final regexFields = FieldParser.parse(gloryRaw);
    final coordinator = OcrCoordinator(
      onDevice: _FakeOcr(
        OcrResult(
          fields: regexFields,
          rawText: gloryRaw,
          engine: OcrEngine.onDevice,
          succeeded: true,
        ),
      ),
      cloud: _FakeOcr(OcrResult.failure(OcrEngine.cloud, 'no')),
      aiExtractor: FakeAiFieldExtractor(error: Exception('network down')),
    );
    final result = await coordinator.recognize(
      imageFile: tmp,
      settings: const AppSettings(
        aiFieldExtractionEnabled: true,
        aiApiKey: 'test-key-not-real',
      ),
      persistSettings: (s) async => s,
      askCloudConsent: () async => false,
    );
    expect(result.succeeded, isTrue);
    expect(result.fields.chineseName, '張敏芝');
    expect(result.fields.personalEmail, contains('cathymanchi'));
    await tmp.delete();
  });

  test('AI success merges through coordinator', () async {
    final tmp = File('${Directory.systemTemp.path}/ai_ok_ocr.jpg');
    await tmp.writeAsBytes([0xFF, 0xD8, 0xFF, 0xD9]);
    final regexFields = FieldParser.parse(gloryRaw);
    final coordinator = OcrCoordinator(
      onDevice: _FakeOcr(
        OcrResult(
          fields: regexFields,
          rawText: gloryRaw,
          engine: OcrEngine.onDevice,
          succeeded: true,
        ),
      ),
      cloud: _FakeOcr(OcrResult.failure(OcrEngine.cloud, 'no')),
      aiExtractor: FakeAiFieldExtractor(result: gloryAiFields()),
    );
    final result = await coordinator.recognize(
      imageFile: tmp,
      settings: const AppSettings(
        aiFieldExtractionEnabled: true,
        aiApiKey: 'test-key',
      ),
      persistSettings: (s) async => s,
      askCloudConsent: () async => false,
    );
    expect(result.fields.chineseName, '張敏芝');
    expect(result.fields.englishName, 'Cathy Cheung');
    expect(result.fields.companyNameEnglish!.toUpperCase(), contains('GLORY'));
    expect(result.fields.companyWebsite, contains('gloryin.com'));
    await tmp.delete();
  });

  test('FieldMerge scrubs degree-like AI address into education', () {
    final regex = FieldParser.parse(gloryRaw);
    const ai = BusinessCardFields(
      chineseName: '張敏芝',
      englishName: 'Cathy Cheung',
      education: null,
      companyAddressChinese: '香港浸會大學中醫學碩士(內科專業)',
      personalEmail: 'cathymanchi@gloryin.com',
    );
    final m = FieldMerge.merge(ai: ai, regex: regex);
    expect(m.companyAddressChinese, isNull,
        reason: 'degree must not stay in address');
    expect(m.education, contains('浸會'));
    expect(m.education, contains('碩士'));
  });
}
