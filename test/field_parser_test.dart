import 'package:business_card_scanner/services/ocr/field_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FieldParser extracts common bilingual card fields', () {
    const raw = '''
陳大文
產品經理
Helios Technology Ltd.
香港中環皇后大道中 88 號
Mobile: +852 9123 4567
Email: david.chan@helios.example
Tel: +852 2123 4567
Fax: +852 2123 4568
www.helios.example
''';
    final f = FieldParser.parse(raw);
    expect(f.name, contains('陳'));
    expect(f.title, contains('產品'));
    expect(f.companyName, contains('Helios'));
    expect(f.personalEmail, 'david.chan@helios.example');
    expect(f.personalPhone, isNotNull);
    expect(f.companyPhone, isNotNull);
    expect(f.fax, isNotNull);
    expect(f.companyWebsite, contains('helios'));
  });

  test('FieldParser handles English-only card', () {
    const raw = '''
Jane Smith
CTO
Acme Corp
1 Market St, SF
Cell: +1 415 555 0100
jane@acme.example
https://www.acme.example
''';
    final f = FieldParser.parse(raw);
    expect(f.name, 'Jane Smith');
    expect(f.personalEmail, 'jane@acme.example');
    expect(f.companyWebsite, contains('acme.example'));
    expect(f.isEmpty, isFalse);
  });

  test('empty input yields empty fields', () {
    final f = FieldParser.parse('');
    expect(f.isEmpty, isTrue);
  });

  /// Gold OCR raw text simulating successful ML Kit output for the Glory-In
  /// clinic card (test/fixtures/gloryin_cathy_cheung.jpg). This string is the
  /// unit-test fixture — the JPG is for future on-device tests only and must
  /// never be wired into demo/sample OCR (filename has neither keyword).
  test('FieldParser extracts Glory-In HK bilingual clinic card (gold text)', () {
    const raw = '''
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
    final f = FieldParser.parse(raw);
    expect(
      f.name != null &&
          (f.name!.contains('張敏芝') || f.name!.contains('Cathy')),
      isTrue,
      reason: 'name should contain 張敏芝 and/or Cathy, got: ${f.name}',
    );
    expect(
      f.companyName != null &&
          (f.companyName!.contains('港恩') ||
              f.companyName!.toUpperCase().contains('GLORY')),
      isTrue,
      reason: 'company should contain 港恩 or GLORY, got: ${f.companyName}',
    );
    expect(f.personalPhone, contains('5996'));
    expect(f.personalEmail, contains('cathymanchi@gloryin.com'));
    expect(f.companyWebsite, contains('gloryin.com'));
    expect(f.companyWebsite!.toLowerCase(), isNot(contains('chinesedoctor')));
    expect(f.title, isNotNull);
    expect(
      f.title!.contains('註冊中醫師') || f.title!.contains('R.C.M.P'),
      isTrue,
      reason: 'title should include professional line, got: ${f.title}',
    );
  });
}
