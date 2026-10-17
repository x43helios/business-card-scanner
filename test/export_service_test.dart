import 'dart:io';

import 'package:business_card_scanner/models/contact.dart';
import 'package:business_card_scanner/services/export_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('vCard, CSV and PDF export produce non-empty files', () async {
    final now = DateTime(2026, 10, 18);
    final contacts = [
      Contact(
        id: 'c1',
        name: '陳大文',
        title: 'PM',
        companyName: 'Helios',
        personalEmail: 'david@helios.example',
        personalPhone: '+85291234567',
        tags: const ['client'],
        createdAt: now,
        updatedAt: now,
      ),
    ];
    final out = await Directory.systemTemp.createTemp('bcs_export_');
    final svc = ExportService();
    final vcf = await svc.exportContacts(
      contacts,
      ExportFormat.vcard,
      outputDir: out,
    );
    final csv = await svc.exportContacts(
      contacts,
      ExportFormat.csv,
      outputDir: out,
    );
    final pdf = await svc.exportContacts(
      contacts,
      ExportFormat.pdf,
      outputDir: out,
    );

    expect(await vcf.exists(), isTrue);
    expect(await csv.exists(), isTrue);
    expect(await pdf.exists(), isTrue);

    final vcfText = await vcf.readAsString();
    expect(vcfText, contains('BEGIN:VCARD'));
    expect(vcfText, contains('陳大文'));

    final csvText = await csv.readAsString();
    expect(csvText, contains('name,title,company_name'));
    expect(csvText, contains('Helios'));

    expect(await pdf.length(), greaterThan(100));

    await out.delete(recursive: true);
  });
}
