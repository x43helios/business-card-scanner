import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/app_settings.dart';
import '../providers/contacts_provider.dart';
import '../providers/settings_provider.dart';
import '../services/export_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _exportAll(BuildContext context, ExportFormat format) async {
    final l10n = AppLocalizations.of(context);
    final contacts = context.read<ContactsProvider>().contacts;
    if (contacts.isEmpty) return;
    try {
      final svc = ExportService();
      final file = await svc.exportContacts(contacts, format);
      await svc.shareFile(file);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.errorGeneric}: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settingsProvider = context.watch<SettingsProvider>();
    final s = settingsProvider.settings;

    String consentLabel() {
      if (!s.cloudOcrConsentAsked) return l10n.consentNotAsked;
      if (s.cloudOcrConsentGranted) return l10n.consentGranted;
      return l10n.consentDenied;
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        children: [
          ListTile(
            title: Text(l10n.language),
            subtitle: Text({
              AppLanguage.system: l10n.languageSystem,
              AppLanguage.english: l10n.languageEn,
              AppLanguage.traditionalChinese: l10n.languageZh,
            }[s.language]!),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final choice = await showModalBottomSheet<AppLanguage>(
                context: context,
                builder: (ctx) => SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        title: Text(l10n.languageSystem),
                        onTap: () => Navigator.pop(ctx, AppLanguage.system),
                      ),
                      ListTile(
                        title: Text(l10n.languageEn),
                        onTap: () => Navigator.pop(ctx, AppLanguage.english),
                      ),
                      ListTile(
                        title: Text(l10n.languageZh),
                        onTap: () =>
                            Navigator.pop(ctx, AppLanguage.traditionalChinese),
                      ),
                    ],
                  ),
                ),
              );
              if (choice != null) {
                await settingsProvider.update((x) => x.copyWith(language: choice));
              }
            },
          ),
          SwitchListTile(
            title: Text(l10n.saveCardPhoto),
            subtitle: Text(l10n.saveCardPhotoDesc),
            value: s.saveCardPhoto,
            onChanged: (v) =>
                settingsProvider.update((x) => x.copyWith(saveCardPhoto: v)),
          ),
          ListTile(
            title: Text(l10n.cloudOcr),
            subtitle: Text('${l10n.cloudConsentStatus}: ${consentLabel()}'),
          ),
          ListTile(
            title: Text(l10n.resetCloudConsent),
            onTap: () => settingsProvider.update(
              (x) => x.copyWith(
                cloudOcrConsentAsked: false,
                cloudOcrConsentGranted: false,
                localOnlyMode: false,
              ),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.cloud_outlined),
            title: Text(l10n.syncPlaceholder),
            enabled: false,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.contact_page_outlined),
            title: Text(l10n.exportVcard),
            onTap: () => _exportAll(context, ExportFormat.vcard),
          ),
          ListTile(
            leading: const Icon(Icons.table_chart_outlined),
            title: Text(l10n.exportCsv),
            onTap: () => _exportAll(context, ExportFormat.csv),
          ),
          ListTile(
            leading: const Icon(Icons.picture_as_pdf_outlined),
            title: Text(l10n.exportPdf),
            onTap: () => _exportAll(context, ExportFormat.pdf),
          ),
        ],
      ),
    );
  }
}
