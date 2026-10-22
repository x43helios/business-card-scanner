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
    expect(f.chineseName, contains('陳'));
    expect(f.title, contains('產品'));
    expect(f.titleChinese, contains('產品'));
    expect(f.companyName, contains('Helios'));
    expect(f.companyNameEnglish, contains('Helios'));
    expect(f.personalEmail, 'david.chan@helios.example');
    expect(f.personalPhone, isNotNull);
    expect(f.companyPhone, isNotNull);
    expect(f.fax, isNotNull);
    expect(f.companyWebsite, contains('helios'));
    expect(f.companyAddressChinese, isNotNull);
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
    expect(f.englishName, 'Jane Smith');
    expect(f.personalEmail, 'jane@acme.example');
    expect(f.companyWebsite, contains('acme.example'));
    expect(f.isEmpty, isFalse);
  });

  test('empty input yields empty fields', () {
    final f = FieldParser.parse('');
    expect(f.isEmpty, isTrue);
  });

  /// Gold OCR raw text for Glory-In clinic card (test fixture JPG only —
  /// never wired into demo/sample OCR).
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
    expect(f.chineseName, '張敏芝');
    expect(f.englishName, 'Cathy Cheung');
    expect(f.name, '張敏芝 / Cathy Cheung');
    expect(f.companyNameChinese, '港恩中醫診所');
    expect(f.companyNameEnglish, 'GLORY-IN CHINESE MEDICAL CLINIC');
    expect(f.companyName, '港恩中醫診所 / GLORY-IN CHINESE MEDICAL CLINIC');
    expect(f.whatsapp, contains('5996'));
    expect(f.personalPhone, contains('5996'));
    expect(f.personalEmail, contains('cathymanchi@gloryin.com'));
    expect(f.companyWebsite, contains('gloryin.com'));
    expect(f.companyWebsite!.toLowerCase(), isNot(contains('chinesedoctor')));
    expect(f.qualifications, isNotNull);
    expect(
      f.qualifications!.contains('註冊中醫師') ||
          f.qualifications!.contains('R.C.M.P'),
      isTrue,
      reason: 'qualifications got: ${f.qualifications}',
    );
    expect(f.education, isNotNull);
    expect(f.education, contains('大學'));
    expect(f.education, contains('碩士'));
    // Education / registration must NEVER land in address fields
    expect(f.companyAddressChinese, isNull,
        reason: 'got addressZh=${f.companyAddressChinese}');
    expect(f.companyAddressEnglish, isNull,
        reason: 'got addressEn=${f.companyAddressEnglish}');
    expect(f.companyAddress, isNull);
  });

  test('FieldParser rejects degree lines even when they contain 香港', () {
    const raw = '''
張三
某某診所
香港浸會大學中醫學碩士(內科專業)
香港九龍尖沙咀彌敦道 100 號 8 樓
''';
    final f = FieldParser.parse(raw);
    expect(f.education, contains('碩士'));
    expect(f.companyAddressChinese, isNotNull);
    expect(f.companyAddressChinese, contains('彌敦道'));
    expect(f.companyAddressChinese, isNot(contains('碩士')));
    expect(f.companyAddressChinese, isNot(contains('浸會')));
  });

  test('FieldParser does not treat 註冊編號 as address', () {
    const raw = '''
李四
註冊中醫師 R.C.M.P.(註冊編號 : 007014)
''';
    final f = FieldParser.parse(raw);
    expect(f.companyAddressChinese, isNull);
    expect(f.companyAddressEnglish, isNull);
    expect(f.qualifications, isNotNull);
  });

  test("FieldParser rejects simplified-Chinese degree as address", () {
    const raw = """
港恩中医诊所
张敏芝
香港浸会大学中医学硕士(内科专业)
""";
    final f = FieldParser.parse(raw);
    expect(f.companyAddressChinese, isNull, reason: "got ${f.companyAddressChinese}");
    expect(f.education, isNotNull);
    expect(f.education, contains("硕士"));
  });
}
