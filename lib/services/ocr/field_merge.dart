import '../../models/business_card_fields.dart';

/// Merge AI-structured fields with regex [FieldParser] output.
///
/// - Prefer AI for identity / org / address / free-text when non-empty.
/// - Prefer regex (or fill empty slots) for emails / phones / URLs so a
///   missed contact detail from AI is not dropped.
class FieldMerge {
  static final _emailRe = RegExp(
    r'^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$',
    caseSensitive: false,
  );
  static final _phoneish = RegExp(r'\d{7,}');
  static final _urlish = RegExp(
    r'(www\.|https?:\/\/|[A-Z0-9.-]+\.[A-Z]{2,})',
    caseSensitive: false,
  );

  static BusinessCardFields merge({
    required BusinessCardFields ai,
    required BusinessCardFields regex,
  }) {
    String? preferAi(String? a, String? r) {
      final ax = _nz(a);
      if (ax != null) return ax;
      return _nz(r);
    }

    String? contactSlot(String? aiVal, String? regexVal, {required bool Function(String) valid}) {
      final a = _nz(aiVal);
      final r = _nz(regexVal);
      if (a != null && valid(a)) {
        // Keep AI; if regex has a *different* valid contact and AI slot sibling
        // handling is elsewhere — for same slot, AI wins when valid.
        return a;
      }
      if (r != null && valid(r)) return r;
      return a ?? r;
    }

    bool isEmail(String s) => _emailRe.hasMatch(s.trim());
    bool isPhone(String s) => _phoneish.hasMatch(s);
    bool isUrl(String s) => _urlish.hasMatch(s);

    // Start with AI-preferred semantic fields.
    var out = BusinessCardFields(
      chineseName: preferAi(ai.chineseName, regex.chineseName),
      englishName: preferAi(ai.englishName, regex.englishName),
      titleChinese: preferAi(ai.titleChinese, regex.titleChinese),
      titleEnglish: preferAi(ai.titleEnglish, regex.titleEnglish),
      qualifications: preferAi(ai.qualifications, regex.qualifications),
      education: preferAi(ai.education, regex.education),
      companyNameChinese:
          preferAi(ai.companyNameChinese, regex.companyNameChinese),
      companyNameEnglish:
          preferAi(ai.companyNameEnglish, regex.companyNameEnglish),
      department: preferAi(ai.department, regex.department),
      wechat: preferAi(ai.wechat, regex.wechat),
      lineId: preferAi(ai.lineId, regex.lineId),
      extension: preferAi(ai.extension, regex.extension),
      linkedIn: preferAi(ai.linkedIn, regex.linkedIn),
      socialMedia: preferAi(ai.socialMedia, regex.socialMedia),
      companyAddressChinese:
          preferAi(ai.companyAddressChinese, regex.companyAddressChinese),
      companyAddressEnglish:
          preferAi(ai.companyAddressEnglish, regex.companyAddressEnglish),
      roomFloor: preferAi(ai.roomFloor, regex.roomFloor),
      district: preferAi(ai.district, regex.district),
      postalCode: preferAi(ai.postalCode, regex.postalCode),
      slogan: preferAi(ai.slogan, regex.slogan),
      services: preferAi(ai.services, regex.services),
      businessHours: preferAi(ai.businessHours, regex.businessHours),
      qrInfo: preferAi(ai.qrInfo, regex.qrInfo),
      notes: preferAi(ai.notes, regex.notes),
      // Contact channels — validated merge
      personalPhone: contactSlot(ai.personalPhone, regex.personalPhone, valid: isPhone),
      whatsapp: contactSlot(ai.whatsapp, regex.whatsapp, valid: isPhone),
      companyPhone: contactSlot(ai.companyPhone, regex.companyPhone, valid: isPhone),
      directLine: contactSlot(ai.directLine, regex.directLine, valid: isPhone),
      fax: contactSlot(ai.fax, regex.fax, valid: isPhone),
      personalEmail: contactSlot(ai.personalEmail, regex.personalEmail, valid: isEmail),
      companyEmail: contactSlot(ai.companyEmail, regex.companyEmail, valid: isEmail),
      companyWebsite: contactSlot(ai.companyWebsite, regex.companyWebsite, valid: isUrl),
    );

    // If AI missed a regex email/phone that isn't already placed, fill empty slots.
    out = _fillMissedContacts(out, regex);
    out = _scrubDegreeLikeAddresses(out);
    return out;
  }

  /// Reject education/degree strings that AI (or OCR) put into address slots.
  static BusinessCardFields _scrubDegreeLikeAddresses(BusinessCardFields o) {
    var out = o;
    final zh = _nz(o.companyAddressChinese);
    final en = _nz(o.companyAddressEnglish);
    String? edu = _nz(o.education);

    if (zh != null && _looksLikeDegreeOrEducation(zh)) {
      if (edu == null) {
        edu = zh;
      } else if (!edu.contains(zh)) {
        edu = '$edu · $zh';
      }
      out = out.copyWith(clearCompanyAddressChinese: true, education: edu);
    }
    if (en != null && _looksLikeDegreeOrEducation(en)) {
      final e2 = _nz(out.education) ?? edu;
      if (e2 == null) {
        out = out.copyWith(clearCompanyAddressEnglish: true, education: en);
      } else if (!e2.contains(en)) {
        out = out.copyWith(
          clearCompanyAddressEnglish: true,
          education: '$e2 · $en',
        );
      } else {
        out = out.copyWith(clearCompanyAddressEnglish: true);
      }
    }
    return out;
  }

  static final _degreeLike = RegExp(
    r'(大學|大学|學士|学士|碩士|硕士|博士|'
    r'Bachelor|Master\b|University|Degree|學院|学院|Diploma|研究所)',
    caseSensitive: false,
  );
  static final _streetLike = RegExp(
    r'(?:\d\s*號)|(?:號\s*\d)|道|街|樓|室|座|大廈|'
    r'Room\s*[A-Z0-9]|Floor|Flat\b|Building|Street|Road|Avenue',
    caseSensitive: false,
  );

  static bool _looksLikeDegreeOrEducation(String s) {
    if (!_degreeLike.hasMatch(s)) return false;
    // Real addresses almost never contain degree words; if they somehow do
    // and also have strong street tokens, keep them.
    if (_streetLike.hasMatch(s) && RegExp(r'\d').hasMatch(s)) return false;
    return true;
  }

  static BusinessCardFields _fillMissedContacts(
    BusinessCardFields out,
    BusinessCardFields regex,
  ) {
    var o = out;
    if (_nz(o.personalEmail) == null && _nz(regex.personalEmail) != null) {
      o = o.copyWith(personalEmail: regex.personalEmail);
    }
    if (_nz(o.companyEmail) == null && _nz(regex.companyEmail) != null) {
      o = o.copyWith(companyEmail: regex.companyEmail);
    }
    if (_nz(o.personalPhone) == null && _nz(regex.personalPhone) != null) {
      o = o.copyWith(personalPhone: regex.personalPhone);
    }
    if (_nz(o.whatsapp) == null && _nz(regex.whatsapp) != null) {
      o = o.copyWith(whatsapp: regex.whatsapp);
    }
    if (_nz(o.companyPhone) == null && _nz(regex.companyPhone) != null) {
      o = o.copyWith(companyPhone: regex.companyPhone);
    }
    if (_nz(o.fax) == null && _nz(regex.fax) != null) {
      o = o.copyWith(fax: regex.fax);
    }
    if (_nz(o.companyWebsite) == null && _nz(regex.companyWebsite) != null) {
      o = o.copyWith(companyWebsite: regex.companyWebsite);
    }
    // Regex found personal email that AI put nowhere — already handled.
    // If AI has personalEmail but regex has a *different* email and companyEmail empty:
    final aiPe = _nz(out.personalEmail);
    final rePe = _nz(regex.personalEmail);
    final reCe = _nz(regex.companyEmail);
    if (aiPe != null &&
        rePe != null &&
        aiPe.toLowerCase() != rePe.toLowerCase() &&
        _nz(o.companyEmail) == null) {
      o = o.copyWith(companyEmail: rePe);
    } else if (aiPe != null &&
        reCe != null &&
        aiPe.toLowerCase() != reCe.toLowerCase() &&
        _nz(o.companyEmail) == null) {
      o = o.copyWith(companyEmail: reCe);
    }
    return o;
  }

  static String? _nz(String? s) {
    final t = s?.trim();
    return (t == null || t.isEmpty) ? null : t;
  }

  /// Keys where non-empty AI values match the final merged slot (trim-normalized).
  ///
  /// Compares [BusinessCardFields.toMap] keys except legacy bridges
  /// (`name`, `title`, `companyName`, `companyAddress`).
  /// Scrubbed-away AI address keys will not appear (correct); education only
  /// appears if the final education value equals the AI education value.
  static Set<String> aiContributedKeys({
    required BusinessCardFields ai,
    required BusinessCardFields merged,
  }) {
    const legacy = {'name', 'title', 'companyName', 'companyAddress'};
    final aiMap = ai.toMap();
    final mergedMap = merged.toMap();
    final out = <String>{};
    for (final e in aiMap.entries) {
      if (legacy.contains(e.key)) continue;
      final a = _nz(e.value);
      final m = _nz(mergedMap[e.key]);
      if (a == null || m == null) continue;
      if (a == m) out.add(e.key);
    }
    return out;
  }
}
