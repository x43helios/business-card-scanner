import '../../models/business_card_fields.dart';

/// Shared regex / heuristic field extractor used by OCR engines.
///
/// Tuned for Hong Kong bilingual (繁/簡 + English) cards:
/// - WhatsApp / 手機 labels → personalPhone
/// - HK 8-digit mobiles with spaces (e.g. `5996 1224`)
/// - Company keywords (診所 / Clinic / Ltd …)
/// - Name: prefer CJK person name; if English personal name also present,
///   combine as `中文名 / English Name` (consistent bilingual scheme).
class FieldParser {
  static final _emailRe = RegExp(
    r'[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}',
    caseSensitive: false,
  );
  static final _urlRe = RegExp(
    r'(?:https?:\/\/)?(?:www\.)?[A-Z0-9.-]+\.[A-Z]{2,}(?:\/\S*)?',
    caseSensitive: false,
  );
  /// International (+852 …) or HK local 8-digit with optional space/hyphen.
  static final _phoneRe = RegExp(
    r'(?:\+?\d[\d\s\-()]{7,}\d)|(?:\b[2-9]\d{3}[\s\-]?\d{4}\b)',
  );
  static final _mobileLabel = RegExp(
    r'(mobile|手機|手提|cell|whats?app|\bwa\b|m[:：])',
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
  static final _companyKw = RegExp(
    r'(診所|中心|醫院|有限公司|公司|Ltd\.?|Limited|Clinic|Company|Medical|Corporation|Inc\.?)',
    caseSensitive: false,
  );
  static final _titleKw = RegExp(
    r'(註冊|醫師|醫生|經理|總監|主任|工程師|顧問|Director|Manager|Officer|Engineer|'
    r'R\.?\s*C\.?\s*M\.?\s*P\.?|Ph\.?\s*D\.?|MBA|CEO|CTO|CFO|MD)',
    caseSensitive: false,
  );
  static final _addressKw = RegExp(
    r'(號|道|街|樓|室|座|大廈|中心|Room|Floor|Flat|Building|Street|Road|'
    r'Avenue|Hong Kong|香港|九龍|新界|Kowloon)',
    caseSensitive: false,
  );
  static final _degreeKw = RegExp(
    r'(大學|學士|碩士|博士|Bachelor|Master|University|Degree|學院)',
    caseSensitive: false,
  );
  /// 2–4 CJK chars typical of a Chinese personal name (not company).
  static final _cjkPersonName = RegExp(r'^[\u4e00-\u9fff]{2,4}$');
  /// English personal name: 2–4 capitalized words, no company keywords.
  static final _enPersonName = RegExp(
    r"^[A-Z][a-z]+(?:\s+[A-Z][a-z.'\-]+){0,3}$",
  );
  /// Domains often appearing as watermark / directory noise on HK cards.
  static const _watermarkDomains = {
    'chinesedoctor.com.hk',
    'chinesedoctor.com',
    'yellowpages.com.hk',
    'yp.com.hk',
  };

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
    final phones =
        _phoneRe.allMatches(raw).map((m) => m.group(0)!.trim()).toList();
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
    companyWebsite = _pickWebsite(urls);

    // Contact / noise lines to skip when classifying name/title/company.
    // Do NOT skip merely because a line contains digits (註冊編號, room no.).
    final skip = RegExp(
      r'(mobile|tel|fax|email|e-mail|whats?app|\bwa\b|www\.|https?://|'
      r'電話|手機|手提|傳真|電郵|郵件)',
      caseSensitive: false,
    );
    bool looksLikePhoneOnly(String l) {
      final digits = RegExp(r'\d').allMatches(l).length;
      final letters = RegExp(r'[A-Za-z\u4e00-\u9fff]').allMatches(l).length;
      return _phoneRe.hasMatch(l) && digits >= 7 && letters <= 3;
    }
    final contentLines = lines
        .where((l) =>
            !skip.hasMatch(l) &&
            !_emailRe.hasMatch(l) &&
            !_urlRe.hasMatch(l) &&
            !looksLikePhoneOnly(l))
        .toList();

    // --- Company ---
    final companyLines =
        contentLines.where((l) => _companyKw.hasMatch(l)).toList();
    if (companyLines.isNotEmpty) {
      // Prefer Chinese company line when present.
      companyName = companyLines.firstWhere(
        (l) => RegExp(r'[\u4e00-\u9fff]').hasMatch(l),
        orElse: () => companyLines.first,
      );
    }

    // --- Name (CJK preferred; bilingual combine when both present) ---
    // Scheme: `張敏芝` alone, or `張敏芝 / Cathy Cheung` when English personal
    // name is also on the card. Never use company/title lines as name.
    String? cjkName;
    String? enName;
    for (final l in contentLines) {
      if (companyName != null && l == companyName) continue;
      if (_companyKw.hasMatch(l)) continue;
      if (_titleKw.hasMatch(l) && !_cjkPersonName.hasMatch(l)) continue;
      if (_degreeKw.hasMatch(l)) continue;
      if (_addressKw.hasMatch(l) && l.length > 8) continue;
      if (_cjkPersonName.hasMatch(l)) {
        cjkName ??= l;
      } else if (_enPersonName.hasMatch(l) && !_companyKw.hasMatch(l)) {
        // Avoid short titles mistaken as names (CTO, CEO already fail regex).
        enName ??= l;
      }
    }
    if (cjkName != null && enName != null) {
      name = '$cjkName / $enName';
    } else {
      name = cjkName ?? enName;
    }

    // Fallback: first content line that is not company/title/degree/address.
    if (name == null && contentLines.isNotEmpty) {
      for (final l in contentLines) {
        if (companyName != null && l == companyName) continue;
        if (_companyKw.hasMatch(l)) continue;
        if (_degreeKw.hasMatch(l)) continue;
        if (_titleKw.hasMatch(l)) continue;
        name = l;
        break;
      }
      name ??= contentLines.first;
    }

    // --- Title (professional lines; degrees may append) ---
    final titleParts = <String>[];
    for (final l in contentLines) {
      if (name != null && (l == cjkName || l == enName || l == name)) continue;
      if (companyName != null && l == companyName) continue;
      if (_companyKw.hasMatch(l) && !_titleKw.hasMatch(l)) continue;
      if (_titleKw.hasMatch(l) ||
          (_degreeKw.hasMatch(l) && titleParts.isNotEmpty)) {
        titleParts.add(l);
        if (titleParts.length >= 3) break;
      }
    }
    if (titleParts.isEmpty) {
      // Legacy: second content line after name if it looks like a short title.
      for (final l in contentLines) {
        if (name != null && (l == cjkName || l == enName || l == name)) continue;
        if (companyName != null && l == companyName) continue;
        if (_companyKw.hasMatch(l) || _degreeKw.hasMatch(l)) continue;
        if (_addressKw.hasMatch(l) && l.length > 10) continue;
        titleParts.add(l);
        break;
      }
    }
    if (titleParts.isNotEmpty) {
      title = titleParts.join(' · ');
    }

    // Company fallback if keyword miss: third-ish content line (legacy).
    if (companyName == null) {
      for (final l in contentLines) {
        if (name != null && (l == cjkName || l == enName || l == name)) continue;
        if (titleParts.contains(l)) continue;
        if (_degreeKw.hasMatch(l)) continue;
        if (_addressKw.hasMatch(l) && !_companyKw.hasMatch(l)) continue;
        companyName = l;
        break;
      }
    }

    // --- Address (only address-like lines; skip degrees) ---
    final addressParts = <String>[];
    for (final l in contentLines) {
      if (name != null && (l == cjkName || l == enName || l == name)) continue;
      if (companyName != null && l == companyName) continue;
      if (titleParts.contains(l)) continue;
      if (_degreeKw.hasMatch(l)) continue;
      if (_companyKw.hasMatch(l) && !_addressKw.hasMatch(l)) continue;
      if (_addressKw.hasMatch(l)) {
        addressParts.add(l);
      }
    }
    if (addressParts.isNotEmpty) {
      companyAddress = addressParts.join(', ');
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

  /// Prefer non-watermark domains (e.g. gloryin.com over chinesedoctor.com.hk).
  static String? _pickWebsite(List<String> urls) {
    if (urls.isEmpty) return null;
    String domainOf(String u) {
      var s = u.toLowerCase();
      s = s.replaceFirst(RegExp(r'^https?:\/\/'), '');
      s = s.replaceFirst(RegExp(r'^www\.'), '');
      return s.split('/').first;
    }

    for (final u in urls) {
      final d = domainOf(u);
      if (!_watermarkDomains.contains(d) &&
          !_watermarkDomains.any((w) => d.endsWith(w))) {
        return u;
      }
    }
    return urls.first;
  }
}
