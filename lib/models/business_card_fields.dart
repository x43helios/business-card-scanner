/// Shared OCR / card field set for a single business card face.
class BusinessCardFields {
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

  const BusinessCardFields({
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
  });

  BusinessCardFields copyWith({
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
    bool clearName = false,
    bool clearTitle = false,
    bool clearCompanyName = false,
    bool clearCompanyAddress = false,
    bool clearPersonalPhone = false,
    bool clearPersonalEmail = false,
    bool clearCompanyPhone = false,
    bool clearCompanyEmail = false,
    bool clearFax = false,
    bool clearCompanyWebsite = false,
  }) {
    return BusinessCardFields(
      name: clearName ? null : (name ?? this.name),
      title: clearTitle ? null : (title ?? this.title),
      companyName: clearCompanyName ? null : (companyName ?? this.companyName),
      companyAddress:
          clearCompanyAddress ? null : (companyAddress ?? this.companyAddress),
      personalPhone:
          clearPersonalPhone ? null : (personalPhone ?? this.personalPhone),
      personalEmail:
          clearPersonalEmail ? null : (personalEmail ?? this.personalEmail),
      companyPhone:
          clearCompanyPhone ? null : (companyPhone ?? this.companyPhone),
      companyEmail:
          clearCompanyEmail ? null : (companyEmail ?? this.companyEmail),
      fax: clearFax ? null : (fax ?? this.fax),
      companyWebsite:
          clearCompanyWebsite ? null : (companyWebsite ?? this.companyWebsite),
    );
  }

  Map<String, String?> toMap() => {
        'name': name,
        'title': title,
        'companyName': companyName,
        'companyAddress': companyAddress,
        'personalPhone': personalPhone,
        'personalEmail': personalEmail,
        'companyPhone': companyPhone,
        'companyEmail': companyEmail,
        'fax': fax,
        'companyWebsite': companyWebsite,
      };

  factory BusinessCardFields.fromMap(Map<String, dynamic> map) {
    String? s(String key) {
      final v = map[key];
      if (v == null) return null;
      final t = v.toString().trim();
      return t.isEmpty ? null : t;
    }

    return BusinessCardFields(
      name: s('name'),
      title: s('title'),
      companyName: s('companyName'),
      companyAddress: s('companyAddress'),
      personalPhone: s('personalPhone'),
      personalEmail: s('personalEmail'),
      companyPhone: s('companyPhone'),
      companyEmail: s('companyEmail'),
      fax: s('fax'),
      companyWebsite: s('companyWebsite'),
    );
  }

  bool get isEmpty =>
      (name == null || name!.isEmpty) &&
      (title == null || title!.isEmpty) &&
      (companyName == null || companyName!.isEmpty) &&
      (companyAddress == null || companyAddress!.isEmpty) &&
      (personalPhone == null || personalPhone!.isEmpty) &&
      (personalEmail == null || personalEmail!.isEmpty) &&
      (companyPhone == null || companyPhone!.isEmpty) &&
      (companyEmail == null || companyEmail!.isEmpty) &&
      (fax == null || fax!.isEmpty) &&
      (companyWebsite == null || companyWebsite!.isEmpty);

  /// Prefer personal, fall back to company for contact-level display.
  String? get displayPhone =>
      (personalPhone != null && personalPhone!.isNotEmpty)
          ? personalPhone
          : companyPhone;

  String? get displayEmail =>
      (personalEmail != null && personalEmail!.isNotEmpty)
          ? personalEmail
          : companyEmail;
}
