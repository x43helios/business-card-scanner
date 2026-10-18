import '../../models/business_card_fields.dart';

/// Shared regex / heuristic field extractor used by OCR engines.
///
/// Tuned for Hong Kong bilingual (繁/簡 + English) cards. Fills expanded
/// fields (chineseName, whatsapp, qualifications, education, …) while
/// legacy getters on [BusinessCardFields] remain coherent.
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
    r'(?:\+?\d[\d\s\-()]{7,}\d)|(?:\b[2-9]\d{3}[\s\-]?\d{4}\b)',
  );
  static final _whatsappLabel = RegExp(
    r'(whats?app|\bwa\b)',
    caseSensitive: false,
  );
  static final _mobileLabel = RegExp(
    r'(mobile|手機|手提|cell|m[:：])',
    caseSensitive: false,
  );
  static final _wechatLabel = RegExp(
    r'(wechat|微信|weixin)',
    caseSensitive: false,
  );
  static final _lineLabel = RegExp(
    r'(^|\s)(line|line\s*id)[:：\s]',
    caseSensitive: false,
  );
  static final _telLabel = RegExp(
    r'(tel|電話|office|公司電話|t[:：])',
    caseSensitive: false,
  );
  static final _directLabel = RegExp(
    r'(direct|直線|直撥)',
    caseSensitive: false,
  );
  static final _extLabel = RegExp(
    r'(ext\.?|extension|分機)',
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
  static final _deptLabel = RegExp(
    r'(department|dept\.?|部門|組)',
    caseSensitive: false,
  );
  static final _linkedinRe = RegExp(
    r'(?:https?:\/\/)?(?:www\.)?linkedin\.com\/\S+',
    caseSensitive: false,
  );
  static final _companyKw = RegExp(
    r'(診所|中心|醫院|有限公司|公司|Ltd\.?|Limited|Clinic|Company|Medical|Corporation|Inc\.?|Centre|Center)',
    caseSensitive: false,
  );
  static final _jobTitleKw = RegExp(
    r'(經理|總監|主任|工程師|顧問|助理|專員|代表|秘書|'
    r'Director|Manager|Officer|Engineer|Consultant|Assistant|Specialist|'
    r'CEO|CTO|CFO|COO|VP|President|Partner)',
    caseSensitive: false,
  );
  static final _qualKw = RegExp(
    r'(註冊|醫師|醫生|律師|會計師|測量師|R\.?\s*C\.?\s*M\.?\s*P\.?|'
    r'Ph\.?\s*D\.?|MBA|CPA|CFA|MRCP|FRCS|註冊編號)',
    caseSensitive: false,
  );
  static final _addressKw = RegExp(
    r'(號|道|街|樓|室|座|大廈|中心|Room|Floor|Flat|Building|Street|Road|'
    r'Avenue|Hong Kong|香港|九龍|新界|Kowloon)',
    caseSensitive: false,
  );
  static final _degreeKw = RegExp(
    r'(大學|學士|碩士|博士|Bachelor|Master|University|Degree|學院|Diploma)',
    caseSensitive: false,
  );
  static final _roomFloorRe = RegExp(
    r'(Room|Flat|Floor|室|樓|座)\s*[A-Z0-9\-]+',
    caseSensitive: false,
  );
  static final _districtKw = RegExp(
    r'(中環|灣仔|銅鑼灣|尖沙咀|旺角|觀塘|沙田|荃灣|屯門|元朗|'
    r'Central|Wanchai|Wan Chai|Tsim Sha Tsui|Mong Kok|Kwun Tong|'
    r'Sha Tin|Tsuen Wan|Hong Kong|九龍|新界|Kowloon)',
    caseSensitive: false,
  );
  static final _postalRe = RegExp(r'\b\d{5}(?:-\d{4})?\b');
  static final _hoursLabel = RegExp(
    r'(hours|營業時間|辦公時間|opening)',
    caseSensitive: false,
  );
  static final _servicesLabel = RegExp(
    r'(services|服務|專科|範圍)',
    caseSensitive: false,
  );
  static final _cjkPersonName = RegExp(r'^[\u4e00-\u9fff]{2,4}$');
  static final _enPersonName = RegExp(
    r"^[A-Z][a-z]+(?:\s+[A-Z][a-z.'\-]+){0,3}$",
  );
  static final _cjkRe = RegExp(r'[\u4e00-\u9fff]');
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

    String? chineseName;
    String? englishName;
    String? titleChinese;
    String? titleEnglish;
    String? qualifications;
    String? education;
    String? companyNameChinese;
    String? companyNameEnglish;
    String? department;
    String? personalPhone;
    String? whatsapp;
    String? wechat;
    String? lineId;
    String? companyPhone;
    String? directLine;
    String? extension;
    String? fax;
    String? personalEmail;
    String? companyEmail;
    String? companyWebsite;
    String? linkedIn;
    String? socialMedia;
    String? companyAddressChinese;
    String? companyAddressEnglish;
    String? roomFloor;
    String? district;
    String? postalCode;
    String? slogan;
    String? services;
    String? businessHours;
    String? qrInfo;
    String? notes;

    final emails = _emailRe.allMatches(raw).map((m) => m.group(0)!).toList();
    final phones =
        _phoneRe.allMatches(raw).map((m) => m.group(0)!.trim()).toList();
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

    linkedIn = _linkedinRe.firstMatch(raw)?.group(0);

    for (final line in lines) {
      if (_whatsappLabel.hasMatch(line)) {
        final m = _phoneRe.firstMatch(line);
        if (m != null) {
          whatsapp ??= m.group(0)!.trim();
          personalPhone ??= whatsapp;
        }
        continue;
      }
      if (_wechatLabel.hasMatch(line)) {
        wechat ??= _extractAfterLabel(line, _wechatLabel);
        continue;
      }
      if (_lineLabel.hasMatch(line)) {
        lineId ??= _extractAfterLabel(line, _lineLabel);
        continue;
      }
      if (_faxLabel.hasMatch(line)) {
        final m = _phoneRe.firstMatch(line);
        if (m != null) fax ??= m.group(0)!.trim();
        continue;
      }
      if (_extLabel.hasMatch(line)) {
        final m = RegExp(r'[\d\-]+').firstMatch(
          line.replaceFirst(_extLabel, ''),
        );
        if (m != null) extension ??= m.group(0);
        continue;
      }
      if (_directLabel.hasMatch(line)) {
        final m = _phoneRe.firstMatch(line);
        if (m != null) directLine ??= m.group(0)!.trim();
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
      if (_deptLabel.hasMatch(line)) {
        department ??= _extractAfterLabel(line, _deptLabel);
        continue;
      }
      if (_hoursLabel.hasMatch(line)) {
        businessHours ??= line;
        continue;
      }
      if (_servicesLabel.hasMatch(line) && line.length < 80) {
        services ??= _extractAfterLabel(line, _servicesLabel) ?? line;
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

    // QR-ish: leftover URL that isn't the main website / LinkedIn
    for (final u in urls) {
      final low = u.toLowerCase();
      if (companyWebsite != null &&
          low.contains(companyWebsite.toLowerCase().replaceFirst('www.', ''))) {
        continue;
      }
      if (linkedIn != null && low.contains('linkedin')) continue;
      if (low.contains('qr') || low.contains('linktr') || low.contains('bit.ly')) {
        qrInfo ??= u;
      }
    }

    final skip = RegExp(
      r'(mobile|tel|fax|email|e-mail|whats?app|\bwa\b|www\.|https?://|'
      r'電話|手機|手提|傳真|電郵|郵件|wechat|微信|linkedin|department|dept|部門|'
      r'direct|直線|ext\.?|分機)',
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

    bool isEnglishCompanyLine(String l) {
      if (_cjkRe.hasMatch(l)) return false;
      if (!_companyKw.hasMatch(l)) return false;
      final letters = RegExp(r'[A-Za-z]').allMatches(l).length;
      if (letters < 4) return false;
      final upper = RegExp(r'[A-Z]').allMatches(l).length;
      final isMostlyUpper = upper >= letters * 0.7;
      final isTitleish = RegExp(
        r"^[A-Z][A-Za-z0-9.'\-&]*(?:\s+[A-Z][A-Za-z0-9.'\-&]*)+$",
      ).hasMatch(l);
      return isMostlyUpper || isTitleish;
    }

    for (var i = 0; i < contentLines.length; i++) {
      final l = contentLines[i];
      if (!_companyKw.hasMatch(l) && companyNameChinese == null) continue;
      if (_cjkRe.hasMatch(l) && _companyKw.hasMatch(l)) {
        companyNameChinese ??= l;
        if (i + 1 < contentLines.length) {
          final next = contentLines[i + 1];
          if (isEnglishCompanyLine(next) ||
              (!_cjkRe.hasMatch(next) &&
                  _companyKw.hasMatch(next) &&
                  RegExp(r'[A-Za-z]').hasMatch(next))) {
            companyNameEnglish ??= next;
          }
        }
      } else if (isEnglishCompanyLine(l) ||
          (!_cjkRe.hasMatch(l) && _companyKw.hasMatch(l))) {
        companyNameEnglish ??= l;
      }
    }

    bool isCompanyLine(String l) =>
        l == companyNameChinese || l == companyNameEnglish;

    for (final l in contentLines) {
      if (isCompanyLine(l)) continue;
      if (_companyKw.hasMatch(l)) continue;
      if (_qualKw.hasMatch(l) && !_cjkPersonName.hasMatch(l)) continue;
      if (_jobTitleKw.hasMatch(l) && !_cjkPersonName.hasMatch(l)) continue;
      if (_degreeKw.hasMatch(l)) continue;
      if (_addressKw.hasMatch(l) && l.length > 8) continue;
      if (_cjkPersonName.hasMatch(l)) {
        chineseName ??= l;
      } else if (_enPersonName.hasMatch(l) && !_companyKw.hasMatch(l)) {
        englishName ??= l;
      }
    }

    if (chineseName == null && englishName == null && contentLines.isNotEmpty) {
      for (final l in contentLines) {
        if (isCompanyLine(l)) continue;
        if (_companyKw.hasMatch(l)) continue;
        if (_degreeKw.hasMatch(l)) continue;
        if (_qualKw.hasMatch(l) || _jobTitleKw.hasMatch(l)) continue;
        if (_cjkRe.hasMatch(l)) {
          chineseName = l;
        } else {
          englishName = l;
        }
        break;
      }
    }

    final qualParts = <String>[];
    final eduParts = <String>[];
    final jobZh = <String>[];
    final jobEn = <String>[];

    for (final l in contentLines) {
      if (l == chineseName || l == englishName) continue;
      if (isCompanyLine(l)) continue;
      if (_companyKw.hasMatch(l) && !_qualKw.hasMatch(l)) continue;

      final isDegree = _degreeKw.hasMatch(l);
      final isQual = _qualKw.hasMatch(l);
      final isJob = _jobTitleKw.hasMatch(l);

      if (isDegree) {
        eduParts.add(l);
        continue;
      }
      if (isQual) {
        qualParts.add(l);
        continue;
      }
      if (isJob) {
        if (_cjkRe.hasMatch(l)) {
          jobZh.add(l);
        } else {
          jobEn.add(l);
        }
        continue;
      }
    }

    // Legacy short title fallback (e.g. 產品經理, CTO) when no job kw matched
    // but a short non-company line sits after the name.
    if (jobZh.isEmpty && jobEn.isEmpty && qualParts.isEmpty) {
      for (final l in contentLines) {
        if (l == chineseName || l == englishName) continue;
        if (isCompanyLine(l)) continue;
        if (_companyKw.hasMatch(l) || _degreeKw.hasMatch(l)) continue;
        if (_addressKw.hasMatch(l) && l.length > 10) continue;
        if (_cjkRe.hasMatch(l)) {
          jobZh.add(l);
        } else {
          jobEn.add(l);
        }
        break;
      }
    }

    if (qualParts.isNotEmpty) qualifications = qualParts.join(' · ');
    if (eduParts.isNotEmpty) education = eduParts.join(' · ');
    if (jobZh.isNotEmpty) titleChinese = jobZh.first;
    if (jobEn.isNotEmpty) titleEnglish = jobEn.first;

    // Company fallback
    if (companyNameChinese == null && companyNameEnglish == null) {
      for (final l in contentLines) {
        if (l == chineseName || l == englishName) continue;
        if (qualParts.contains(l) || eduParts.contains(l)) continue;
        if (l == titleChinese || l == titleEnglish) continue;
        if (_degreeKw.hasMatch(l)) continue;
        if (_addressKw.hasMatch(l) && !_companyKw.hasMatch(l)) continue;
        if (_cjkRe.hasMatch(l)) {
          companyNameChinese = l;
        } else {
          companyNameEnglish = l;
        }
        break;
      }
    }

    // Address
    final addrZh = <String>[];
    final addrEn = <String>[];
    for (final l in contentLines) {
      if (l == chineseName || l == englishName) continue;
      if (isCompanyLine(l)) continue;
      if (qualParts.contains(l) || eduParts.contains(l)) continue;
      if (l == titleChinese || l == titleEnglish) continue;
      if (_degreeKw.hasMatch(l)) continue;
      if (_companyKw.hasMatch(l) && !_addressKw.hasMatch(l)) continue;
      if (_addressKw.hasMatch(l)) {
        if (_cjkRe.hasMatch(l)) {
          addrZh.add(l);
        } else {
          addrEn.add(l);
        }
        final rf = _roomFloorRe.firstMatch(l);
        if (rf != null) roomFloor ??= rf.group(0);
        if (_districtKw.hasMatch(l)) {
          district ??= _districtKw.firstMatch(l)?.group(0);
        }
        final pc = _postalRe.firstMatch(l);
        if (pc != null) postalCode ??= pc.group(0);
      }
    }
    if (addrZh.isNotEmpty) companyAddressChinese = addrZh.join(', ');
    if (addrEn.isNotEmpty) companyAddressEnglish = addrEn.join(', ');

    // Light slogan: short quoted or trailing tagline not otherwise classified
    for (final l in lines) {
      if (l.startsWith('"') || l.startsWith('「') || l.startsWith('『')) {
        slogan ??= l.replaceAll(RegExp(r'^["「『]|["」』]$'), '');
      }
    }

    return BusinessCardFields(
      chineseName: chineseName,
      englishName: englishName,
      titleChinese: titleChinese,
      titleEnglish: titleEnglish,
      qualifications: qualifications,
      education: education,
      companyNameChinese: companyNameChinese,
      companyNameEnglish: companyNameEnglish,
      department: department,
      personalPhone: personalPhone,
      whatsapp: whatsapp,
      wechat: wechat,
      lineId: lineId,
      companyPhone: companyPhone,
      directLine: directLine,
      extension: extension,
      fax: fax,
      personalEmail: personalEmail,
      companyEmail: companyEmail,
      companyWebsite: companyWebsite,
      linkedIn: linkedIn,
      socialMedia: socialMedia,
      companyAddressChinese: companyAddressChinese,
      companyAddressEnglish: companyAddressEnglish,
      roomFloor: roomFloor,
      district: district,
      postalCode: postalCode,
      slogan: slogan,
      services: services,
      businessHours: businessHours,
      qrInfo: qrInfo,
      notes: notes,
    );
  }

  static String? _extractAfterLabel(String line, RegExp label) {
    final cleaned = line.replaceFirst(label, '').replaceFirst(RegExp(r'^[:：\s]+'), '').trim();
    return cleaned.isEmpty ? null : cleaned;
  }

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
      if (d.contains('linkedin')) continue;
      if (!_watermarkDomains.contains(d) &&
          !_watermarkDomains.any((w) => d.endsWith(w))) {
        return u;
      }
    }
    return urls.firstWhere(
      (u) => !u.toLowerCase().contains('linkedin'),
      orElse: () => urls.first,
    );
  }
}
