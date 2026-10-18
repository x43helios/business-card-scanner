import 'business_card_fields.dart';

/// One scanned card belonging to a [Contact]. A contact may have many cards.
class CardRecord {
  final String id;
  final String contactId;
  final BusinessCardFields fields;
  final String? imagePath;
  final String ocrSource; // on_device | cloud | manual
  final DateTime createdAt;

  const CardRecord({
    required this.id,
    required this.contactId,
    required this.fields,
    this.imagePath,
    this.ocrSource = 'on_device',
    required this.createdAt,
  });

  CardRecord copyWith({
    String? id,
    String? contactId,
    BusinessCardFields? fields,
    String? imagePath,
    String? ocrSource,
    DateTime? createdAt,
    bool clearImagePath = false,
  }) {
    return CardRecord(
      id: id ?? this.id,
      contactId: contactId ?? this.contactId,
      fields: fields ?? this.fields,
      imagePath: clearImagePath ? null : (imagePath ?? this.imagePath),
      ocrSource: ocrSource ?? this.ocrSource,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toDbMap() {
    final f = fields;
    return {
      'id': id,
      'contact_id': contactId,
      // New
      'chinese_name': f.chineseName,
      'english_name': f.englishName,
      'title_chinese': f.titleChinese,
      'title_english': f.titleEnglish,
      'qualifications': f.qualifications,
      'education': f.education,
      'company_name_chinese': f.companyNameChinese,
      'company_name_english': f.companyNameEnglish,
      'department': f.department,
      'whatsapp': f.whatsapp,
      'wechat': f.wechat,
      'line_id': f.lineId,
      'direct_line': f.directLine,
      'extension': f.extension,
      'linkedin': f.linkedIn,
      'social_media': f.socialMedia,
      'company_address_chinese': f.companyAddressChinese,
      'company_address_english': f.companyAddressEnglish,
      'room_floor': f.roomFloor,
      'district': f.district,
      'postal_code': f.postalCode,
      'slogan': f.slogan,
      'services': f.services,
      'business_hours': f.businessHours,
      'qr_info': f.qrInfo,
      'notes': f.notes,
      // Legacy bridge
      'name': f.name,
      'title': f.title,
      'company_name': f.companyName,
      'company_address': f.companyAddress,
      'personal_phone': f.personalPhone,
      'personal_email': f.personalEmail,
      'company_phone': f.companyPhone,
      'company_email': f.companyEmail,
      'fax': f.fax,
      'company_website': f.companyWebsite,
      'image_path': imagePath,
      'ocr_source': ocrSource,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory CardRecord.fromDbMap(Map<String, dynamic> map) {
    return CardRecord(
      id: map['id'] as String,
      contactId: map['contact_id'] as String,
      fields: BusinessCardFields.fromMap({
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
      }),
      imagePath: map['image_path'] as String?,
      ocrSource: (map['ocr_source'] as String?) ?? 'on_device',
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
