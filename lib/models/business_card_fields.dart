/// Shared OCR / card field set for a single business card face.
///
/// New bilingual / expanded fields are stored explicitly. Legacy keys
/// ([name], [title], [companyName], [companyAddress]) are **computed getters**
/// for search, matcher, list display, and DB bridge columns.
class BusinessCardFields {
  // --- Identity ---
  final String? chineseName;
  final String? englishName;
  final String? titleChinese;
  final String? titleEnglish;
  final String? qualifications;
  final String? education;

  // --- Organization ---
  final String? companyNameChinese;
  final String? companyNameEnglish;
  final String? department;

  // --- Contact ---
  final String? personalPhone;
  final String? whatsapp;
  final String? wechat;
  final String? lineId;
  final String? companyPhone;
  final String? directLine;
  final String? extension;
  final String? fax;
  final String? personalEmail;
  final String? companyEmail;
  final String? companyWebsite;
  final String? linkedIn;
  final String? socialMedia;

  // --- Address ---
  final String? companyAddressChinese;
  final String? companyAddressEnglish;
  final String? roomFloor;
  final String? district;
  final String? postalCode;

  // --- Other ---
  final String? slogan;
  final String? services;
  final String? businessHours;
  final String? qrInfo;
  final String? notes;

  const BusinessCardFields({
    this.chineseName,
    this.englishName,
    this.titleChinese,
    this.titleEnglish,
    this.qualifications,
    this.education,
    this.companyNameChinese,
    this.companyNameEnglish,
    this.department,
    this.personalPhone,
    this.whatsapp,
    this.wechat,
    this.lineId,
    this.companyPhone,
    this.directLine,
    this.extension,
    this.fax,
    this.personalEmail,
    this.companyEmail,
    this.companyWebsite,
    this.linkedIn,
    this.socialMedia,
    this.companyAddressChinese,
    this.companyAddressEnglish,
    this.roomFloor,
    this.district,
    this.postalCode,
    this.slogan,
    this.services,
    this.businessHours,
    this.qrInfo,
    this.notes,
  });

  /// Join non-empty parts with ` / ` (Chinese-first convention when both set).
  static String? joinBilingual(String? a, String? b) {
    final x = a?.trim();
    final y = b?.trim();
    final hasX = x != null && x.isNotEmpty;
    final hasY = y != null && y.isNotEmpty;
    if (hasX && hasY) return '$x / $y';
    if (hasX) return x;
    if (hasY) return y;
    return null;
  }

  static String? _nz(String? s) {
    final t = s?.trim();
    return (t == null || t.isEmpty) ? null : t;
  }

  // --- Legacy computed getters ---

  /// `chineseName / englishName` (whichever present).
  String? get name => joinBilingual(chineseName, englishName);

  /// Job title: `titleChinese / titleEnglish`, else [qualifications] for display.
  String? get title {
    final t = joinBilingual(titleChinese, titleEnglish);
    if (t != null) return t;
    return _nz(qualifications);
  }

  /// `companyNameChinese / companyNameEnglish`.
  String? get companyName =>
      joinBilingual(companyNameChinese, companyNameEnglish);

  /// Joined address lines (ZH, EN, room/floor, district, postal).
  String? get companyAddress {
    final parts = <String>[
      if (_nz(companyAddressChinese) != null) companyAddressChinese!.trim(),
      if (_nz(companyAddressEnglish) != null) companyAddressEnglish!.trim(),
      if (_nz(roomFloor) != null) roomFloor!.trim(),
      if (_nz(district) != null) district!.trim(),
      if (_nz(postalCode) != null) postalCode!.trim(),
    ];
    if (parts.isEmpty) return null;
    return parts.join(', ');
  }

  BusinessCardFields copyWith({
    String? chineseName,
    String? englishName,
    String? titleChinese,
    String? titleEnglish,
    String? qualifications,
    String? education,
    String? companyNameChinese,
    String? companyNameEnglish,
    String? department,
    String? personalPhone,
    String? whatsapp,
    String? wechat,
    String? lineId,
    String? companyPhone,
    String? directLine,
    String? extension,
    String? fax,
    String? personalEmail,
    String? companyEmail,
    String? companyWebsite,
    String? linkedIn,
    String? socialMedia,
    String? companyAddressChinese,
    String? companyAddressEnglish,
    String? roomFloor,
    String? district,
    String? postalCode,
    String? slogan,
    String? services,
    String? businessHours,
    String? qrInfo,
    String? notes,
    bool clearChineseName = false,
    bool clearEnglishName = false,
    bool clearTitleChinese = false,
    bool clearTitleEnglish = false,
    bool clearQualifications = false,
    bool clearEducation = false,
    bool clearCompanyNameChinese = false,
    bool clearCompanyNameEnglish = false,
    bool clearDepartment = false,
    bool clearPersonalPhone = false,
    bool clearWhatsapp = false,
    bool clearWechat = false,
    bool clearLineId = false,
    bool clearCompanyPhone = false,
    bool clearDirectLine = false,
    bool clearExtension = false,
    bool clearFax = false,
    bool clearPersonalEmail = false,
    bool clearCompanyEmail = false,
    bool clearCompanyWebsite = false,
    bool clearLinkedIn = false,
    bool clearSocialMedia = false,
    bool clearCompanyAddressChinese = false,
    bool clearCompanyAddressEnglish = false,
    bool clearRoomFloor = false,
    bool clearDistrict = false,
    bool clearPostalCode = false,
    bool clearSlogan = false,
    bool clearServices = false,
    bool clearBusinessHours = false,
    bool clearQrInfo = false,
    bool clearNotes = false,
  }) {
    return BusinessCardFields(
      chineseName: clearChineseName ? null : (chineseName ?? this.chineseName),
      englishName: clearEnglishName ? null : (englishName ?? this.englishName),
      titleChinese:
          clearTitleChinese ? null : (titleChinese ?? this.titleChinese),
      titleEnglish:
          clearTitleEnglish ? null : (titleEnglish ?? this.titleEnglish),
      qualifications: clearQualifications
          ? null
          : (qualifications ?? this.qualifications),
      education: clearEducation ? null : (education ?? this.education),
      companyNameChinese: clearCompanyNameChinese
          ? null
          : (companyNameChinese ?? this.companyNameChinese),
      companyNameEnglish: clearCompanyNameEnglish
          ? null
          : (companyNameEnglish ?? this.companyNameEnglish),
      department: clearDepartment ? null : (department ?? this.department),
      personalPhone:
          clearPersonalPhone ? null : (personalPhone ?? this.personalPhone),
      whatsapp: clearWhatsapp ? null : (whatsapp ?? this.whatsapp),
      wechat: clearWechat ? null : (wechat ?? this.wechat),
      lineId: clearLineId ? null : (lineId ?? this.lineId),
      companyPhone:
          clearCompanyPhone ? null : (companyPhone ?? this.companyPhone),
      directLine: clearDirectLine ? null : (directLine ?? this.directLine),
      extension: clearExtension ? null : (extension ?? this.extension),
      fax: clearFax ? null : (fax ?? this.fax),
      personalEmail:
          clearPersonalEmail ? null : (personalEmail ?? this.personalEmail),
      companyEmail:
          clearCompanyEmail ? null : (companyEmail ?? this.companyEmail),
      companyWebsite:
          clearCompanyWebsite ? null : (companyWebsite ?? this.companyWebsite),
      linkedIn: clearLinkedIn ? null : (linkedIn ?? this.linkedIn),
      socialMedia: clearSocialMedia ? null : (socialMedia ?? this.socialMedia),
      companyAddressChinese: clearCompanyAddressChinese
          ? null
          : (companyAddressChinese ?? this.companyAddressChinese),
      companyAddressEnglish: clearCompanyAddressEnglish
          ? null
          : (companyAddressEnglish ?? this.companyAddressEnglish),
      roomFloor: clearRoomFloor ? null : (roomFloor ?? this.roomFloor),
      district: clearDistrict ? null : (district ?? this.district),
      postalCode: clearPostalCode ? null : (postalCode ?? this.postalCode),
      slogan: clearSlogan ? null : (slogan ?? this.slogan),
      services: clearServices ? null : (services ?? this.services),
      businessHours:
          clearBusinessHours ? null : (businessHours ?? this.businessHours),
      qrInfo: clearQrInfo ? null : (qrInfo ?? this.qrInfo),
      notes: clearNotes ? null : (notes ?? this.notes),
    );
  }

  /// All stored (non-legacy) field values for search / emptiness.
  List<String?> get _storedValues => [
        chineseName,
        englishName,
        titleChinese,
        titleEnglish,
        qualifications,
        education,
        companyNameChinese,
        companyNameEnglish,
        department,
        personalPhone,
        whatsapp,
        wechat,
        lineId,
        companyPhone,
        directLine,
        extension,
        fax,
        personalEmail,
        companyEmail,
        companyWebsite,
        linkedIn,
        socialMedia,
        companyAddressChinese,
        companyAddressEnglish,
        roomFloor,
        district,
        postalCode,
        slogan,
        services,
        businessHours,
        qrInfo,
        notes,
      ];

  Map<String, String?> toMap() => {
        // New fields
        'chineseName': chineseName,
        'englishName': englishName,
        'titleChinese': titleChinese,
        'titleEnglish': titleEnglish,
        'qualifications': qualifications,
        'education': education,
        'companyNameChinese': companyNameChinese,
        'companyNameEnglish': companyNameEnglish,
        'department': department,
        'personalPhone': personalPhone,
        'whatsapp': whatsapp,
        'wechat': wechat,
        'lineId': lineId,
        'companyPhone': companyPhone,
        'directLine': directLine,
        'extension': extension,
        'fax': fax,
        'personalEmail': personalEmail,
        'companyEmail': companyEmail,
        'companyWebsite': companyWebsite,
        'linkedIn': linkedIn,
        'socialMedia': socialMedia,
        'companyAddressChinese': companyAddressChinese,
        'companyAddressEnglish': companyAddressEnglish,
        'roomFloor': roomFloor,
        'district': district,
        'postalCode': postalCode,
        'slogan': slogan,
        'services': services,
        'businessHours': businessHours,
        'qrInfo': qrInfo,
        'notes': notes,
        // Legacy bridge
        'name': name,
        'title': title,
        'companyName': companyName,
        'companyAddress': companyAddress,
      };

  factory BusinessCardFields.fromMap(Map<String, dynamic> map) {
    String? s(String key) {
      final v = map[key];
      if (v == null) return null;
      final t = v.toString().trim();
      return t.isEmpty ? null : t;
    }

    // Prefer explicit bilingual keys; fall back to splitting legacy name/company.
    var chineseName = s('chineseName') ?? s('chinese_name');
    var englishName = s('englishName') ?? s('english_name');
    if (chineseName == null && englishName == null) {
      final legacy = s('name');
      if (legacy != null) {
        final split = _splitBilingual(legacy);
        chineseName = split.$1;
        englishName = split.$2;
      }
    }

    var companyNameChinese =
        s('companyNameChinese') ?? s('company_name_chinese');
    var companyNameEnglish =
        s('companyNameEnglish') ?? s('company_name_english');
    if (companyNameChinese == null && companyNameEnglish == null) {
      final legacy = s('companyName') ?? s('company_name');
      if (legacy != null) {
        final split = _splitBilingual(legacy);
        companyNameChinese = split.$1;
        companyNameEnglish = split.$2;
      }
    }

    var titleChinese = s('titleChinese') ?? s('title_chinese');
    var titleEnglish = s('titleEnglish') ?? s('title_english');
    if (titleChinese == null && titleEnglish == null) {
      final legacy = s('title');
      if (legacy != null) {
        final split = _splitBilingual(legacy);
        titleChinese = split.$1;
        titleEnglish = split.$2;
      }
    }

    var companyAddressChinese =
        s('companyAddressChinese') ?? s('company_address_chinese');
    var companyAddressEnglish =
        s('companyAddressEnglish') ?? s('company_address_english');
    if (companyAddressChinese == null && companyAddressEnglish == null) {
      final legacy = s('companyAddress') ?? s('company_address');
      if (legacy != null) {
        final split = _splitBilingual(legacy);
        companyAddressChinese = split.$1;
        companyAddressEnglish = split.$2;
      }
    }

    return BusinessCardFields(
      chineseName: chineseName,
      englishName: englishName,
      titleChinese: titleChinese,
      titleEnglish: titleEnglish,
      qualifications: s('qualifications'),
      education: s('education'),
      companyNameChinese: companyNameChinese,
      companyNameEnglish: companyNameEnglish,
      department: s('department'),
      personalPhone: s('personalPhone') ?? s('personal_phone'),
      whatsapp: s('whatsapp'),
      wechat: s('wechat'),
      lineId: s('lineId') ?? s('line_id'),
      companyPhone: s('companyPhone') ?? s('company_phone'),
      directLine: s('directLine') ?? s('direct_line'),
      extension: s('extension'),
      fax: s('fax'),
      personalEmail: s('personalEmail') ?? s('personal_email'),
      companyEmail: s('companyEmail') ?? s('company_email'),
      companyWebsite: s('companyWebsite') ?? s('company_website'),
      linkedIn: s('linkedIn') ?? s('linkedin'),
      socialMedia: s('socialMedia') ?? s('social_media'),
      companyAddressChinese: companyAddressChinese,
      companyAddressEnglish: companyAddressEnglish,
      roomFloor: s('roomFloor') ?? s('room_floor'),
      district: s('district'),
      postalCode: s('postalCode') ?? s('postal_code'),
      slogan: s('slogan'),
      services: s('services'),
      businessHours: s('businessHours') ?? s('business_hours'),
      qrInfo: s('qrInfo') ?? s('qr_info'),
      notes: s('notes'),
    );
  }

  /// Split `中文 / English` or assign whole string to CJK vs Latin bucket.
  static (String?, String?) _splitBilingual(String raw) {
    final parts = raw.split(RegExp(r'\s*/\s*'));
    if (parts.length >= 2) {
      final a = parts[0].trim();
      final b = parts.sublist(1).join(' / ').trim();
      final aCjk = RegExp(r'[\u4e00-\u9fff]').hasMatch(a);
      final bCjk = RegExp(r'[\u4e00-\u9fff]').hasMatch(b);
      if (aCjk && !bCjk) return (a, b);
      if (!aCjk && bCjk) return (b, a);
      return (a.isEmpty ? null : a, b.isEmpty ? null : b);
    }
    final t = raw.trim();
    if (t.isEmpty) return (null, null);
    if (RegExp(r'[\u4e00-\u9fff]').hasMatch(t)) return (t, null);
    return (null, t);
  }

  bool get isEmpty => _storedValues.every((v) => v == null || v.trim().isEmpty);

  /// Prefer personal, fall back to company / WhatsApp for contact-level display.
  String? get displayPhone {
    if (_nz(personalPhone) != null) return personalPhone;
    if (_nz(whatsapp) != null) return whatsapp;
    return companyPhone;
  }

  String? get displayEmail =>
      _nz(personalEmail) != null ? personalEmail : companyEmail;

  /// Flat list of all non-empty searchable strings.
  List<String> get searchableParts => _storedValues
      .whereType<String>()
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
}
