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

    Widget field(String label, String? value, void Function(String) set) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          initialValue: value ?? '',
          decoration: InputDecoration(
            labelText: label,
            hintText: l10n.emptyFieldHint,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
          onChanged: set,
        ),
      );
    }

    return Column(
      children: [
        field(l10n.fieldName, fields.name, (v) => onChanged(fields.copyWith(name: v))),
        field(l10n.fieldTitle, fields.title, (v) => onChanged(fields.copyWith(title: v))),
        field(l10n.fieldCompany, fields.companyName,
            (v) => onChanged(fields.copyWith(companyName: v))),
        field(l10n.fieldAddress, fields.companyAddress,
            (v) => onChanged(fields.copyWith(companyAddress: v))),
        field(l10n.fieldPersonalPhone, fields.personalPhone,
            (v) => onChanged(fields.copyWith(personalPhone: v))),
        field(l10n.fieldPersonalEmail, fields.personalEmail,
            (v) => onChanged(fields.copyWith(personalEmail: v))),
        field(l10n.fieldCompanyPhone, fields.companyPhone,
            (v) => onChanged(fields.copyWith(companyPhone: v))),
        field(l10n.fieldCompanyEmail, fields.companyEmail,
            (v) => onChanged(fields.copyWith(companyEmail: v))),
        field(l10n.fieldFax, fields.fax, (v) => onChanged(fields.copyWith(fax: v))),
        field(l10n.fieldWebsite, fields.companyWebsite,
            (v) => onChanged(fields.copyWith(companyWebsite: v))),
      ],
    );
  }
}
