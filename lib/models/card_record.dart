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

  Map<String, dynamic> toDbMap() => {
        'id': id,
        'contact_id': contactId,
        'name': fields.name,
        'title': fields.title,
        'company_name': fields.companyName,
        'company_address': fields.companyAddress,
        'personal_phone': fields.personalPhone,
        'personal_email': fields.personalEmail,
        'company_phone': fields.companyPhone,
        'company_email': fields.companyEmail,
        'fax': fields.fax,
        'company_website': fields.companyWebsite,
        'image_path': imagePath,
        'ocr_source': ocrSource,
        'created_at': createdAt.toIso8601String(),
      };

  factory CardRecord.fromDbMap(Map<String, dynamic> map) {
    return CardRecord(
      id: map['id'] as String,
      contactId: map['contact_id'] as String,
      fields: BusinessCardFields(
        name: map['name'] as String?,
        title: map['title'] as String?,
        companyName: map['company_name'] as String?,
        companyAddress: map['company_address'] as String?,
        personalPhone: map['personal_phone'] as String?,
        personalEmail: map['personal_email'] as String?,
        companyPhone: map['company_phone'] as String?,
        companyEmail: map['company_email'] as String?,
        fax: map['fax'] as String?,
        companyWebsite: map['company_website'] as String?,
      ),
      imagePath: map['image_path'] as String?,
      ocrSource: (map['ocr_source'] as String?) ?? 'on_device',
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
