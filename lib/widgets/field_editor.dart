import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/business_card_fields.dart';

typedef FieldsChanged = void Function(BusinessCardFields fields);

class FieldEditor extends StatelessWidget {
  const FieldEditor({
    super.key,
    required this.fields,
    required this.onChanged,
  });

  final BusinessCardFields fields;
  final FieldsChanged onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    Widget section(String title) => Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 10),
          child: Text(title, style: theme.textTheme.titleMedium),
        );

    Widget field(String label, String? value, BusinessCardFields Function(String) set) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          key: ValueKey(label),
          initialValue: value ?? '',
          decoration: InputDecoration(
            labelText: label,
            hintText: l10n.emptyFieldHint,
            border: const OutlineInputBorder(),
            isDense: true,
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
            (v) => fields.copyWith(chineseName: v)),
        field(l10n.fieldEnglishName, fields.englishName,
            (v) => fields.copyWith(englishName: v)),
        field(l10n.fieldTitleChinese, fields.titleChinese,
            (v) => fields.copyWith(titleChinese: v)),
        field(l10n.fieldTitleEnglish, fields.titleEnglish,
            (v) => fields.copyWith(titleEnglish: v)),
        field(l10n.fieldQualifications, fields.qualifications,
            (v) => fields.copyWith(qualifications: v)),
        field(l10n.fieldEducation, fields.education,
            (v) => fields.copyWith(education: v)),
        section(l10n.sectionOrganization),
        field(l10n.fieldCompanyChinese, fields.companyNameChinese,
            (v) => fields.copyWith(companyNameChinese: v)),
        field(l10n.fieldCompanyEnglish, fields.companyNameEnglish,
            (v) => fields.copyWith(companyNameEnglish: v)),
        field(l10n.fieldDepartment, fields.department,
            (v) => fields.copyWith(department: v)),
        section(l10n.sectionContact),
        field(l10n.fieldPersonalPhone, fields.personalPhone,
            (v) => fields.copyWith(personalPhone: v)),
        field(l10n.fieldWhatsapp, fields.whatsapp,
            (v) => fields.copyWith(whatsapp: v)),
        field(l10n.fieldWechat, fields.wechat,
            (v) => fields.copyWith(wechat: v)),
        field(l10n.fieldLineId, fields.lineId,
            (v) => fields.copyWith(lineId: v)),
        field(l10n.fieldCompanyPhone, fields.companyPhone,
            (v) => fields.copyWith(companyPhone: v)),
        field(l10n.fieldDirectLine, fields.directLine,
            (v) => fields.copyWith(directLine: v)),
        field(l10n.fieldExtension, fields.extension,
            (v) => fields.copyWith(extension: v)),
        field(l10n.fieldFax, fields.fax, (v) => fields.copyWith(fax: v)),
        field(l10n.fieldPersonalEmail, fields.personalEmail,
            (v) => fields.copyWith(personalEmail: v)),
        field(l10n.fieldCompanyEmail, fields.companyEmail,
            (v) => fields.copyWith(companyEmail: v)),
        field(l10n.fieldWebsite, fields.companyWebsite,
            (v) => fields.copyWith(companyWebsite: v)),
        field(l10n.fieldLinkedIn, fields.linkedIn,
            (v) => fields.copyWith(linkedIn: v)),
        field(l10n.fieldSocialMedia, fields.socialMedia,
            (v) => fields.copyWith(socialMedia: v)),
        section(l10n.sectionAddress),
        field(l10n.fieldAddressChinese, fields.companyAddressChinese,
            (v) => fields.copyWith(companyAddressChinese: v)),
        field(l10n.fieldAddressEnglish, fields.companyAddressEnglish,
            (v) => fields.copyWith(companyAddressEnglish: v)),
        field(l10n.fieldRoomFloor, fields.roomFloor,
            (v) => fields.copyWith(roomFloor: v)),
        field(l10n.fieldDistrict, fields.district,
            (v) => fields.copyWith(district: v)),
        field(l10n.fieldPostalCode, fields.postalCode,
            (v) => fields.copyWith(postalCode: v)),
        section(l10n.sectionOther),
        field(l10n.fieldSlogan, fields.slogan,
            (v) => fields.copyWith(slogan: v)),
        field(l10n.fieldServices, fields.services,
            (v) => fields.copyWith(services: v)),
        field(l10n.fieldBusinessHours, fields.businessHours,
            (v) => fields.copyWith(businessHours: v)),
        field(l10n.fieldQrInfo, fields.qrInfo,
            (v) => fields.copyWith(qrInfo: v)),
        field(l10n.fieldNotes, fields.notes,
            (v) => fields.copyWith(notes: v)),
      ],
    );
  }
}
