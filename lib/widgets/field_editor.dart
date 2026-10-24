import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/business_card_fields.dart';

typedef FieldsChanged = void Function(BusinessCardFields fields);

class FieldEditor extends StatelessWidget {
  const FieldEditor({
    super.key,
    required this.fields,
    required this.onChanged,
    this.aiContributedFields = const {},
  });

  final BusinessCardFields fields;
  final FieldsChanged onChanged;

  /// Keys from [BusinessCardFields.toMap] that LLM filled/refined — show ✓.
  final Set<String> aiContributedFields;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final checkColor = theme.colorScheme.primary;

    Widget section(String title) => Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 10),
          child: Text(title, style: theme.textTheme.titleMedium),
        );

    Widget field(
      String label,
      String? value,
      BusinessCardFields Function(String) set, {
      required String fieldKey,
    }) {
      final fromAi = aiContributedFields.contains(fieldKey);
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          key: ValueKey('$fieldKey|$label|${fromAi ? 1 : 0}'),
          initialValue: value ?? '',
          decoration: InputDecoration(
            labelText: label,
            hintText: l10n.emptyFieldHint,
            border: const OutlineInputBorder(),
            isDense: true,
            suffixText: fromAi ? '✓' : null,
            suffixStyle: fromAi
                ? TextStyle(
                    color: checkColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  )
                : null,
          ),
          minLines: 1,
          maxLines: 3,
          onChanged: (v) => onChanged(set(v)),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        section(l10n.sectionIdentity),
        field(l10n.fieldChineseName, fields.chineseName,
            (v) => fields.copyWith(chineseName: v),
            fieldKey: 'chineseName'),
        field(l10n.fieldEnglishName, fields.englishName,
            (v) => fields.copyWith(englishName: v),
            fieldKey: 'englishName'),
        field(l10n.fieldTitleChinese, fields.titleChinese,
            (v) => fields.copyWith(titleChinese: v),
            fieldKey: 'titleChinese'),
        field(l10n.fieldTitleEnglish, fields.titleEnglish,
            (v) => fields.copyWith(titleEnglish: v),
            fieldKey: 'titleEnglish'),
        field(l10n.fieldQualifications, fields.qualifications,
            (v) => fields.copyWith(qualifications: v),
            fieldKey: 'qualifications'),
        field(l10n.fieldEducation, fields.education,
            (v) => fields.copyWith(education: v),
            fieldKey: 'education'),
        section(l10n.sectionOrganization),
        field(l10n.fieldCompanyChinese, fields.companyNameChinese,
            (v) => fields.copyWith(companyNameChinese: v),
            fieldKey: 'companyNameChinese'),
        field(l10n.fieldCompanyEnglish, fields.companyNameEnglish,
            (v) => fields.copyWith(companyNameEnglish: v),
            fieldKey: 'companyNameEnglish'),
        field(l10n.fieldDepartment, fields.department,
            (v) => fields.copyWith(department: v),
            fieldKey: 'department'),
        section(l10n.sectionContact),
        field(l10n.fieldPersonalPhone, fields.personalPhone,
            (v) => fields.copyWith(personalPhone: v),
            fieldKey: 'personalPhone'),
        field(l10n.fieldWhatsapp, fields.whatsapp,
            (v) => fields.copyWith(whatsapp: v),
            fieldKey: 'whatsapp'),
        field(l10n.fieldWechat, fields.wechat,
            (v) => fields.copyWith(wechat: v),
            fieldKey: 'wechat'),
        field(l10n.fieldLineId, fields.lineId,
            (v) => fields.copyWith(lineId: v),
            fieldKey: 'lineId'),
        field(l10n.fieldCompanyPhone, fields.companyPhone,
            (v) => fields.copyWith(companyPhone: v),
            fieldKey: 'companyPhone'),
        field(l10n.fieldDirectLine, fields.directLine,
            (v) => fields.copyWith(directLine: v),
            fieldKey: 'directLine'),
        field(l10n.fieldExtension, fields.extension,
            (v) => fields.copyWith(extension: v),
            fieldKey: 'extension'),
        field(l10n.fieldFax, fields.fax, (v) => fields.copyWith(fax: v),
            fieldKey: 'fax'),
        field(l10n.fieldPersonalEmail, fields.personalEmail,
            (v) => fields.copyWith(personalEmail: v),
            fieldKey: 'personalEmail'),
        field(l10n.fieldCompanyEmail, fields.companyEmail,
            (v) => fields.copyWith(companyEmail: v),
            fieldKey: 'companyEmail'),
        field(l10n.fieldWebsite, fields.companyWebsite,
            (v) => fields.copyWith(companyWebsite: v),
            fieldKey: 'companyWebsite'),
        field(l10n.fieldLinkedIn, fields.linkedIn,
            (v) => fields.copyWith(linkedIn: v),
            fieldKey: 'linkedIn'),
        field(l10n.fieldSocialMedia, fields.socialMedia,
            (v) => fields.copyWith(socialMedia: v),
            fieldKey: 'socialMedia'),
        section(l10n.sectionAddress),
        field(l10n.fieldAddressChinese, fields.companyAddressChinese,
            (v) => fields.copyWith(companyAddressChinese: v),
            fieldKey: 'companyAddressChinese'),
        field(l10n.fieldAddressEnglish, fields.companyAddressEnglish,
            (v) => fields.copyWith(companyAddressEnglish: v),
            fieldKey: 'companyAddressEnglish'),
        field(l10n.fieldRoomFloor, fields.roomFloor,
            (v) => fields.copyWith(roomFloor: v),
            fieldKey: 'roomFloor'),
        field(l10n.fieldDistrict, fields.district,
            (v) => fields.copyWith(district: v),
            fieldKey: 'district'),
        field(l10n.fieldPostalCode, fields.postalCode,
            (v) => fields.copyWith(postalCode: v),
            fieldKey: 'postalCode'),
        section(l10n.sectionOther),
        field(l10n.fieldSlogan, fields.slogan,
            (v) => fields.copyWith(slogan: v),
            fieldKey: 'slogan'),
        field(l10n.fieldServices, fields.services,
            (v) => fields.copyWith(services: v),
            fieldKey: 'services'),
        field(l10n.fieldBusinessHours, fields.businessHours,
            (v) => fields.copyWith(businessHours: v),
            fieldKey: 'businessHours'),
        field(l10n.fieldQrInfo, fields.qrInfo,
            (v) => fields.copyWith(qrInfo: v),
            fieldKey: 'qrInfo'),
        field(l10n.fieldNotes, fields.notes,
            (v) => fields.copyWith(notes: v),
            fieldKey: 'notes'),
      ],
    );
  }
}
