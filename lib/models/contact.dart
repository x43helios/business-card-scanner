import 'business_card_fields.dart';
import 'card_record.dart';

class Contact {
  final String id;
  final String? name;
  final String? title;
  final String? companyName;
  final String? companyAddress;
  final String? personalPhone;
  final String? personalEmail;
  final String? companyPhone;
  final String? companyEmail;
  final String? fax;
  final String? companyWebsite;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<CardRecord> cards;

  const Contact({
    required this.id,
    this.name,
    this.title,
    this.companyName,
    this.companyAddress,
    this.personalPhone,
    this.personalEmail,
    this.companyPhone,
    this.companyEmail,
    this.fax,
    this.companyWebsite,
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
    this.cards = const [],
  });

  BusinessCardFields get primaryFields => BusinessCardFields(
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

  String get displayName {
    if (name != null && name!.trim().isNotEmpty) return name!.trim();
    if (companyName != null && companyName!.trim().isNotEmpty) {
      return companyName!.trim();
    }
    return '—';
  }

  String? get subtitle {
    final parts = <String>[];
    if (title != null && title!.trim().isNotEmpty) parts.add(title!.trim());
    if (companyName != null &&
        companyName!.trim().isNotEmpty &&
        companyName!.trim() != displayName) {
      parts.add(companyName!.trim());
    }
    if (parts.isEmpty) return null;
    return parts.join(' · ');
  }

  Contact copyWith({
    String? id,
    String? name,
    String? title,
    String? companyName,
    String? companyAddress,
    String? personalPhone,
    String? personalEmail,
    String? companyPhone,
    String? companyEmail,
    String? fax,
    String? companyWebsite,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<CardRecord>? cards,
  }) {
    return Contact(
      id: id ?? this.id,
      name: name ?? this.name,
      title: title ?? this.title,
      companyName: companyName ?? this.companyName,
      companyAddress: companyAddress ?? this.companyAddress,
      personalPhone: personalPhone ?? this.personalPhone,
      personalEmail: personalEmail ?? this.personalEmail,
      companyPhone: companyPhone ?? this.companyPhone,
      companyEmail: companyEmail ?? this.companyEmail,
      fax: fax ?? this.fax,
      companyWebsite: companyWebsite ?? this.companyWebsite,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      cards: cards ?? this.cards,
    );
  }

  /// Merge non-empty fields from a card onto this contact (card wins when set).
  Contact mergeFromCard(BusinessCardFields f, {DateTime? now}) {
    String? pick(String? existing, String? incoming) {
      if (incoming != null && incoming.trim().isNotEmpty) return incoming.trim();
      return existing;
    }

    return copyWith(
      name: pick(name, f.name),
      title: pick(title, f.title),
      companyName: pick(companyName, f.companyName),
      companyAddress: pick(companyAddress, f.companyAddress),
      personalPhone: pick(personalPhone, f.personalPhone),
      personalEmail: pick(personalEmail, f.personalEmail),
      companyPhone: pick(companyPhone, f.companyPhone),
      companyEmail: pick(companyEmail, f.companyEmail),
      fax: pick(fax, f.fax),
      companyWebsite: pick(companyWebsite, f.companyWebsite),
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
      name: f.name,
      title: f.title,
      companyName: f.companyName,
      companyAddress: f.companyAddress,
      personalPhone: f.personalPhone,
      personalEmail: f.personalEmail,
      companyPhone: f.companyPhone,
      companyEmail: f.companyEmail,
      fax: f.fax,
      companyWebsite: f.companyWebsite,
      tags: tags,
      createdAt: t,
      updatedAt: t,
    );
  }

  Map<String, dynamic> toDbMap() => {
        'id': id,
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
    return Contact(
      id: map['id'] as String,
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
      tags: tags,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      cards: cards,
    );
  }
}
