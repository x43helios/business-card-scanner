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
    if (contacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.noContacts)),
      );
      return;
    }
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
          _SectionHeader(title: l10n.isZh ? '一般' : 'General'),
          ListTile(
            leading: const Icon(Icons.language),
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
                showDragHandle: true,
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
                await settingsProvider
                    .update((x) => x.copyWith(language: choice));
              }
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.image_outlined),
            title: Text(l10n.saveCardPhoto),
            subtitle: Text(l10n.saveCardPhotoDesc),
            value: s.saveCardPhoto,
            onChanged: (v) =>
                settingsProvider.update((x) => x.copyWith(saveCardPhoto: v)),
          ),
          const Divider(),
          _SectionHeader(title: l10n.cloudOcr),
          ListTile(
            leading: const Icon(Icons.cloud_outlined),
            title: Text(l10n.cloudConsentStatus),
            subtitle: Text(consentLabel()),
          ),
          ListTile(
            leading: const Icon(Icons.restart_alt),
            title: Text(l10n.resetCloudConsent),
            onTap: () async {
              await settingsProvider.update(
                (x) => x.copyWith(
                  cloudOcrConsentAsked: false,
                  cloudOcrConsentGranted: false,
                  localOnlyMode: false,
                ),
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.saved)),
                );
              }
            },
          ),
          const Divider(),
          _SectionHeader(title: l10n.isZh ? '同步' : 'Sync'),
          ListTile(
            leading: const Icon(Icons.cloud_sync_outlined),
            title: Text(l10n.syncPlaceholder),
            enabled: false,
          ),
          const Divider(),
          _SectionHeader(title: l10n.export),
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
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'v1.0.0 · Business Card Scanner / 名片掃描',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
