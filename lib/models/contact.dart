import 'business_card_fields.dart';
import 'card_record.dart';

class Contact {
  final String id;

  // Identity
  final String? chineseName;
  final String? englishName;
  final String? titleChinese;
  final String? titleEnglish;
  final String? qualifications;
  final String? education;

  // Organization
  final String? companyNameChinese;
  final String? companyNameEnglish;
  final String? department;

  // Contact
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

  // Address
  final String? companyAddressChinese;
  final String? companyAddressEnglish;
  final String? roomFloor;
  final String? district;
  final String? postalCode;

  // Other
  final String? slogan;
  final String? services;
  final String? businessHours;
  final String? qrInfo;
  final String? notes;

  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<CardRecord> cards;

  const Contact({
    required this.id,
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
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
    this.cards = const [],
  });

  // Legacy getters (same scheme as BusinessCardFields)
  String? get name =>
      BusinessCardFields.joinBilingual(chineseName, englishName);
  String? get title {
    final t =
        BusinessCardFields.joinBilingual(titleChinese, titleEnglish);
    if (t != null) return t;
    final q = qualifications?.trim();
    return (q != null && q.isNotEmpty) ? q : null;
  }

  String? get companyName => BusinessCardFields.joinBilingual(
        companyNameChinese,
        companyNameEnglish,
      );

  String? get companyAddress {
    final parts = <String>[
      if (companyAddressChinese != null &&
          companyAddressChinese!.trim().isNotEmpty)
        companyAddressChinese!.trim(),
      if (companyAddressEnglish != null &&
          companyAddressEnglish!.trim().isNotEmpty)
        companyAddressEnglish!.trim(),
      if (roomFloor != null && roomFloor!.trim().isNotEmpty)
        roomFloor!.trim(),
      if (district != null && district!.trim().isNotEmpty) district!.trim(),
      if (postalCode != null && postalCode!.trim().isNotEmpty)
        postalCode!.trim(),
    ];
    return parts.isEmpty ? null : parts.join(', ');
  }

  BusinessCardFields get primaryFields => BusinessCardFields(
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

  String get displayName {
    final n = name;
    if (n != null && n.trim().isNotEmpty) return n.trim();
    final co = companyName;
    if (co != null && co.trim().isNotEmpty) return co.trim();
    return '—';
  }

  String? get subtitle {
    final parts = <String>[];
    final t = title;
    if (t != null && t.trim().isNotEmpty) parts.add(t.trim());
    final co = companyName;
    if (co != null && co.trim().isNotEmpty && co.trim() != displayName) {
      parts.add(co.trim());
    }
    if (parts.isEmpty) return null;
    return parts.join(' · ');
  }

  Contact copyWith({
    String? id,
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
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<CardRecord>? cards,
  }) {
    return Contact(
      id: id ?? this.id,
      chineseName: chineseName ?? this.chineseName,
      englishName: englishName ?? this.englishName,
      titleChinese: titleChinese ?? this.titleChinese,
      titleEnglish: titleEnglish ?? this.titleEnglish,
      qualifications: qualifications ?? this.qualifications,
      education: education ?? this.education,
      companyNameChinese: companyNameChinese ?? this.companyNameChinese,
      companyNameEnglish: companyNameEnglish ?? this.companyNameEnglish,
      department: department ?? this.department,
      personalPhone: personalPhone ?? this.personalPhone,
      whatsapp: whatsapp ?? this.whatsapp,
      wechat: wechat ?? this.wechat,
      lineId: lineId ?? this.lineId,
      companyPhone: companyPhone ?? this.companyPhone,
      directLine: directLine ?? this.directLine,
      extension: extension ?? this.extension,
      fax: fax ?? this.fax,
      personalEmail: personalEmail ?? this.personalEmail,
      companyEmail: companyEmail ?? this.companyEmail,
      companyWebsite: companyWebsite ?? this.companyWebsite,
      linkedIn: linkedIn ?? this.linkedIn,
      socialMedia: socialMedia ?? this.socialMedia,
      companyAddressChinese:
          companyAddressChinese ?? this.companyAddressChinese,
      companyAddressEnglish:
          companyAddressEnglish ?? this.companyAddressEnglish,
      roomFloor: roomFloor ?? this.roomFloor,
      district: district ?? this.district,
      postalCode: postalCode ?? this.postalCode,
      slogan: slogan ?? this.slogan,
      services: services ?? this.services,
      businessHours: businessHours ?? this.businessHours,
      qrInfo: qrInfo ?? this.qrInfo,
      notes: notes ?? this.notes,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      cards: cards ?? this.cards,
    );
  }

  /// Apply all fields from [f] (card wins when set).
  Contact mergeFromCard(BusinessCardFields f, {DateTime? now}) {
    String? pick(String? existing, String? incoming) {
      if (incoming != null && incoming.trim().isNotEmpty) return incoming.trim();
      return existing;
    }

    return copyWith(
      chineseName: pick(chineseName, f.chineseName),
      englishName: pick(englishName, f.englishName),
      titleChinese: pick(titleChinese, f.titleChinese),
      titleEnglish: pick(titleEnglish, f.titleEnglish),
      qualifications: pick(qualifications, f.qualifications),
      education: pick(education, f.education),
      companyNameChinese: pick(companyNameChinese, f.companyNameChinese),
      companyNameEnglish: pick(companyNameEnglish, f.companyNameEnglish),
      department: pick(department, f.department),
      personalPhone: pick(personalPhone, f.personalPhone),
      whatsapp: pick(whatsapp, f.whatsapp),
      wechat: pick(wechat, f.wechat),
      lineId: pick(lineId, f.lineId),
      companyPhone: pick(companyPhone, f.companyPhone),
      directLine: pick(directLine, f.directLine),
      extension: pick(extension, f.extension),
      fax: pick(fax, f.fax),
      personalEmail: pick(personalEmail, f.personalEmail),
      companyEmail: pick(companyEmail, f.companyEmail),
      companyWebsite: pick(companyWebsite, f.companyWebsite),
      linkedIn: pick(linkedIn, f.linkedIn),
      socialMedia: pick(socialMedia, f.socialMedia),
      companyAddressChinese:
          pick(companyAddressChinese, f.companyAddressChinese),
      companyAddressEnglish:
          pick(companyAddressEnglish, f.companyAddressEnglish),
      roomFloor: pick(roomFloor, f.roomFloor),
      district: pick(district, f.district),
      postalCode: pick(postalCode, f.postalCode),
      slogan: pick(slogan, f.slogan),
      services: pick(services, f.services),
      businessHours: pick(businessHours, f.businessHours),
      qrInfo: pick(qrInfo, f.qrInfo),
      notes: pick(notes, f.notes),
      updatedAt: now ?? DateTime.now(),
    );
  }

  factory Contact.fromFields(
    BusinessCardFields f, {
    required String id,
    List<String> tags = const [],
    DateTime? now,
  }) {
    final t = now ?? DateTime.now();
    return Contact(
      id: id,
      chineseName: f.chineseName,
      englishName: f.englishName,
      titleChinese: f.titleChinese,
      titleEnglish: f.titleEnglish,
      qualifications: f.qualifications,
      education: f.education,
      companyNameChinese: f.companyNameChinese,
      companyNameEnglish: f.companyNameEnglish,
      department: f.department,
      personalPhone: f.personalPhone,
      whatsapp: f.whatsapp,
      wechat: f.wechat,
      lineId: f.lineId,
      companyPhone: f.companyPhone,
      directLine: f.directLine,
      extension: f.extension,
      fax: f.fax,
      personalEmail: f.personalEmail,
      companyEmail: f.companyEmail,
      companyWebsite: f.companyWebsite,
      linkedIn: f.linkedIn,
      socialMedia: f.socialMedia,
      companyAddressChinese: f.companyAddressChinese,
      companyAddressEnglish: f.companyAddressEnglish,
      roomFloor: f.roomFloor,
      district: f.district,
      postalCode: f.postalCode,
      slogan: f.slogan,
      services: f.services,
      businessHours: f.businessHours,
      qrInfo: f.qrInfo,
      notes: f.notes,
      tags: tags,
      createdAt: t,
      updatedAt: t,
    );
  }

  /// DB map includes new columns + legacy bridge columns filled from getters.
  Map<String, dynamic> toDbMap() => {
        'id': id,
        // New
        'chinese_name': chineseName,
        'english_name': englishName,
        'title_chinese': titleChinese,
        'title_english': titleEnglish,
        'qualifications': qualifications,
        'education': education,
        'company_name_chinese': companyNameChinese,
        'company_name_english': companyNameEnglish,
        'department': department,
        'whatsapp': whatsapp,
        'wechat': wechat,
        'line_id': lineId,
        'direct_line': directLine,
        'extension': extension,
        'linkedin': linkedIn,
        'social_media': socialMedia,
        'company_address_chinese': companyAddressChinese,
        'company_address_english': companyAddressEnglish,
        'room_floor': roomFloor,
        'district': district,
        'postal_code': postalCode,
        'slogan': slogan,
        'services': services,
        'business_hours': businessHours,
        'qr_info': qrInfo,
        'notes': notes,
        // Shared / legacy bridge
        'name': name,
        'title': title,
        'company_name': companyName,
        'company_address': companyAddress,
        'personal_phone': personalPhone,
        'personal_email': personalEmail,
        'company_phone': companyPhone,
        'company_email': companyEmail,
        'fax': fax,
        'company_website': companyWebsite,
        'tags': tags.join('|'),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory Contact.fromDbMap(
    Map<String, dynamic> map, {
    List<CardRecord> cards = const [],
  }) {
    final tagsRaw = (map['tags'] as String?) ?? '';
    final tags = tagsRaw.isEmpty
        ? <String>[]
        : tagsRaw.split('|').where((t) => t.isNotEmpty).toList();

    // Rehydrate via BusinessCardFields so legacy-only rows still populate.
    final fields = BusinessCardFields.fromMap({
      ...map,
      'chineseName': map['chinese_name'],
      'englishName': map['english_name'],
      'titleChinese': map['title_chinese'],
      'titleEnglish': map['title_english'],
      'companyNameChinese': map['company_name_chinese'],
      'companyNameEnglish': map['company_name_english'],
      'companyAddressChinese': map['company_address_chinese'],
      'companyAddressEnglish': map['company_address_english'],
      'personalPhone': map['personal_phone'],
      'personalEmail': map['personal_email'],
      'companyPhone': map['company_phone'],
      'companyEmail': map['company_email'],
      'companyWebsite': map['company_website'],
      'lineId': map['line_id'],
      'directLine': map['direct_line'],
      'linkedIn': map['linkedin'],
      'socialMedia': map['social_media'],
      'roomFloor': map['room_floor'],
      'postalCode': map['postal_code'],
      'businessHours': map['business_hours'],
      'qrInfo': map['qr_info'],
      'name': map['name'],
      'title': map['title'],
      'companyName': map['company_name'],
      'companyAddress': map['company_address'],
    });

    return Contact(
      id: map['id'] as String,
      chineseName: fields.chineseName,
      englishName: fields.englishName,
      titleChinese: fields.titleChinese,
      titleEnglish: fields.titleEnglish,
      qualifications: fields.qualifications,
      education: fields.education,
      companyNameChinese: fields.companyNameChinese,
      companyNameEnglish: fields.companyNameEnglish,
      department: fields.department,
      personalPhone: fields.personalPhone,
      whatsapp: fields.whatsapp,
      wechat: fields.wechat,
      lineId: fields.lineId,
      companyPhone: fields.companyPhone,
      directLine: fields.directLine,
      extension: fields.extension,
      fax: fields.fax,
      personalEmail: fields.personalEmail,
      companyEmail: fields.companyEmail,
      companyWebsite: fields.companyWebsite,
      linkedIn: fields.linkedIn,
      socialMedia: fields.socialMedia,
      companyAddressChinese: fields.companyAddressChinese,
      companyAddressEnglish: fields.companyAddressEnglish,
      roomFloor: fields.roomFloor,
      district: fields.district,
      postalCode: fields.postalCode,
      slogan: fields.slogan,
      services: fields.services,
      businessHours: fields.businessHours,
      qrInfo: fields.qrInfo,
      notes: fields.notes,
      tags: tags,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      cards: cards,
    );
  }
}
