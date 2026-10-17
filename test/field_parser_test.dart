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
}
