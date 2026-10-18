import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/app_settings.dart';
import '../providers/contacts_provider.dart';
import '../providers/settings_provider.dart';
import '../services/export_service.dart';
import '../services/ocr/ai_flags.dart';

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
          _SectionHeader(title: l10n.aiSection),
          SwitchListTile(
            secondary: const Icon(Icons.auto_awesome),
            title: Text(l10n.aiFieldExtraction),
            subtitle: Text(l10n.aiFieldExtractionDesc),
            value: s.aiFieldExtractionEnabled,
            onChanged: (v) => settingsProvider
                .update((x) => x.copyWith(aiFieldExtractionEnabled: v)),
          ),
          ListTile(
            leading: const Icon(Icons.vpn_key_outlined),
            title: Text(l10n.aiApiKey),
            subtitle: Text(
              s.aiApiKey.isNotEmpty
                  ? '•••••••• (${s.aiApiKey.length} chars)'
                  : (kCardAiApiKey.isNotEmpty
                      ? (l10n.isZh ? '使用編譯期金鑰' : 'Using build-time key')
                      : l10n.aiKeyMissing),
            ),
            trailing: const Icon(Icons.edit_outlined),
            onTap: () async {
              final controller = TextEditingController(text: s.aiApiKey);
              final saved = await showDialog<String>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(l10n.aiApiKey),
                  content: TextField(
                    controller: controller,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: l10n.aiApiKeyHint,
                      border: const OutlineInputBorder(),
                    ),
                    autofocus: true,
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(l10n.cancel),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, ''),
                      child: Text(l10n.isZh ? '清除' : 'Clear'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, controller.text),
                      child: Text(l10n.save),
                    ),
                  ],
                ),
              );
              if (saved != null) {
                await settingsProvider.update((x) => x.copyWith(aiApiKey: saved));
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.hub_outlined),
            title: Text(l10n.aiProvider),
            subtitle: Text(
              s.aiProvider.isNotEmpty
                  ? s.aiProvider
                  : '$kCardAiProvider (${l10n.isZh ? "預設" : "default"})',
            ),
            onTap: () async {
              final controller = TextEditingController(text: s.aiProvider);
              final saved = await showDialog<String>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(l10n.aiProvider),
                  content: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: l10n.aiProviderHint,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(l10n.cancel),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, controller.text.trim()),
                      child: Text(l10n.save),
                    ),
                  ],
                ),
              );
              if (saved != null) {
                await settingsProvider.update((x) => x.copyWith(aiProvider: saved));
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.link),
            title: Text(l10n.aiBaseUrl),
            subtitle: Text(
              s.aiBaseUrl.isNotEmpty ? s.aiBaseUrl : kCardAiBaseUrl,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () async {
              final controller = TextEditingController(
                text: s.aiBaseUrl.isNotEmpty ? s.aiBaseUrl : kCardAiBaseUrl,
              );
              final saved = await showDialog<String>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(l10n.aiBaseUrl),
                  content: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(l10n.cancel),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, controller.text.trim()),
                      child: Text(l10n.save),
                    ),
                  ],
                ),
              );
              if (saved != null) {
                await settingsProvider.update((x) => x.copyWith(aiBaseUrl: saved));
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.smart_toy_outlined),
            title: Text(l10n.aiModel),
            subtitle: Text(
              s.aiModel.isNotEmpty ? s.aiModel : kCardAiModel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () async {
              final controller = TextEditingController(
                text: s.aiModel.isNotEmpty ? s.aiModel : kCardAiModel,
              );
              final saved = await showDialog<String>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(l10n.aiModel),
                  content: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(l10n.cancel),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, controller.text.trim()),
                      child: Text(l10n.save),
                    ),
                  ],
                ),
              );
              if (saved != null) {
                await settingsProvider.update((x) => x.copyWith(aiModel: saved));
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
              'v1.0.6 · Business Card Scanner / 名片掃描',
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
