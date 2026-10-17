import 'dart:io';

import '../../models/business_card_fields.dart';
import '../../models/ocr_result.dart';
import 'ocr_service.dart';

/// MVP on-device OCR stub.
///
/// Behavior:
/// 1. If a sibling `.txt` sidecar exists next to the image (same basename), parse it.
/// 2. Otherwise attempt lightweight regex extraction from a synthetic demo buffer
///    derived from the filename (useful for automated tests).
/// 3. If nothing parseable is found, return [succeeded]=false so the coordinator
///    may fall back to cloud (when consented).
///
/// Production next step (Mac / Xcode): replace body with Apple Vision
/// `VNRecognizeTextRequest` via MethodChannel `com.x43helios.businesscardscanner/ocr`.
class OnDeviceOcrService implements OcrService {
  @override
  Future<OcrResult> recognize(File imageFile) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));

    final sidecar = File('${imageFile.path}.txt');
    if (await sidecar.exists()) {
      final text = await sidecar.readAsString();
      final fields = FieldParser.parse(text);
      return OcrResult(
        fields: fields,
        rawText: text,
        engine: OcrEngine.onDevice,
        succeeded: !fields.isEmpty,
      );
    }

    // Demo path: filename containing "demo" yields a sample card so the UI
    // flow is walkable without a real Vision plugin on Linux CI / this box.
    final name = imageFile.uri.pathSegments.last.toLowerCase();
    if (name.contains('demo') || name.contains('sample')) {
      const sample = '''
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
      final fields = FieldParser.parse(sample);
      return OcrResult(
        fields: fields,
        rawText: sample,
        engine: OcrEngine.stubDemo,
        succeeded: true,
      );
    }

    // Realistic "no text found" path → coordinator may try cloud.
    return OcrResult.failure(
      OcrEngine.onDevice,
      'On-device OCR found no text. Wire Apple Vision / ML Kit for production.',
    );
  }
}

/// Shared regex / heuristic field extractor used by stub OCR engines.
class FieldParser {
  static final _emailRe = RegExp(
    r'[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}',
    caseSensitive: false,
  );
  static final _urlRe = RegExp(
    r'(?:https?:\/\/)?(?:www\.)?[A-Z0-9.-]+\.[A-Z]{2,}(?:\/\S*)?',
    caseSensitive: false,
  );
  static final _phoneRe = RegExp(
    r'(?:\+?\d[\d\s\-()]{7,}\d)',
  );
  static final _mobileLabel = RegExp(
    r'(mobile|手機|手提|cell|m[:：])',
    caseSensitive: false,
  );
  static final _telLabel = RegExp(
    r'(tel|電話|office|公司電話|t[:：])',
    caseSensitive: false,
  );
  static final _faxLabel = RegExp(
    r'(fax|傳真|f[:：])',
    caseSensitive: false,
  );
  static final _emailLabel = RegExp(
    r'(email|e-mail|電郵|郵件)',
    caseSensitive: false,
  );

  static BusinessCardFields parse(String raw) {
    final lines = raw
        .split(RegExp(r'[\r\n]+'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    String? name;
    String? title;
    String? companyName;
    String? companyAddress;
    String? personalPhone;
    String? personalEmail;
    String? companyPhone;
    String? companyEmail;
    String? fax;
    String? companyWebsite;

    final emails = _emailRe.allMatches(raw).map((m) => m.group(0)!).toList();
    final phones = _phoneRe.allMatches(raw).map((m) => m.group(0)!.trim()).toList();
    // Mask emails so URL regex does not pick "name.tld" from local-parts.
    var masked = raw;
    for (final e in emails) {
      masked = masked.replaceAll(e, ' ' * e.length);
    }
    final urls = _urlRe
        .allMatches(masked)
        .map((m) => m.group(0)!)
        .where((u) =>
            u.contains('.') &&
            (u.toLowerCase().startsWith('www.') ||
                u.toLowerCase().startsWith('http') ||
                u.split('.').last.length >= 2))
        .toList();

    for (final line in lines) {
      if (_faxLabel.hasMatch(line)) {
        final m = _phoneRe.firstMatch(line);
        if (m != null) fax ??= m.group(0)!.trim();
        continue;
      }
      if (_mobileLabel.hasMatch(line)) {
        final m = _phoneRe.firstMatch(line);
        if (m != null) personalPhone ??= m.group(0)!.trim();
        continue;
      }
      if (_telLabel.hasMatch(line)) {
        final m = _phoneRe.firstMatch(line);
        if (m != null) companyPhone ??= m.group(0)!.trim();
        continue;
      }
      if (_emailLabel.hasMatch(line)) {
        final m = _emailRe.firstMatch(line);
        if (m != null) {
          final e = m.group(0)!;
          if (personalEmail == null) {
            personalEmail = e;
          } else {
            companyEmail ??= e;
          }
        }
        continue;
      }
    }

    if (personalEmail == null && emails.isNotEmpty) {
      personalEmail = emails.first;
    }
    if (companyEmail == null && emails.length > 1) {
      companyEmail = emails[1];
    }
    if (personalPhone == null && phones.isNotEmpty) {
      personalPhone = phones.first;
    }
    if (companyPhone == null && phones.length > 1) {
      companyPhone = phones[1];
    }
    if (fax == null && phones.length > 2) {
      fax = phones[2];
    }
    if (urls.isNotEmpty) {
      companyWebsite = urls.first;
    }

    // Heuristic: first non-contact line → name; second → title; third → company
    final skip = RegExp(
      r'(mobile|tel|fax|email|e-mail|www\.|https?://|電話|手機|傳真|電郵|\+?\d)',
      caseSensitive: false,
    );
    final contentLines =
        lines.where((l) => !skip.hasMatch(l) && !_emailRe.hasMatch(l)).toList();
    if (contentLines.isNotEmpty) name = contentLines[0];
    if (contentLines.length > 1) title = contentLines[1];
    if (contentLines.length > 2) companyName = contentLines[2];
    if (contentLines.length > 3) {
      companyAddress = contentLines.sublist(3).join(', ');
    }

    return BusinessCardFields(
      name: name,
      title: title,
      companyName: companyName,
      companyAddress: companyAddress,
      personalPhone: personalPhone,
      personalEmail: personalEmail,
      companyPhone: companyPhone,
      companyEmail: companyEmail,
      fax: fax,
      companyWebsite: companyWebsite,
    );
  }
}
