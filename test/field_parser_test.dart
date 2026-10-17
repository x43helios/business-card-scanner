import 'package:business_card_scanner/services/ocr/on_device_ocr_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FieldParser extracts common card fields', () {
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
    expect(f.personalEmail, 'david.chan@helios.example');
    expect(f.personalPhone, isNotNull);
    expect(f.companyWebsite, contains('helios'));
  });
}
