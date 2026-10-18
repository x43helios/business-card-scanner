import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/contacts_provider.dart';
import '../services/export_service.dart';
import '../services/crash_log.dart';
import '../widgets/contact_list_tile.dart';
import '../widgets/tag_chips.dart';
import 'contact_detail_screen.dart';
import 'scan/preparing_screen.dart';
import 'scan/scan_source_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _selectMode = false;
  final _searchController = TextEditingController();
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // After camera/gallery, Android may have killed MainActivity; recover the pick.
    WidgetsBinding.instance.addPostFrameCallback((_) => _recoverLostPick());
  }

  Future<void> _recoverLostPick() async {
    try {
      final response = await _picker.retrieveLostData();
      if (response.isEmpty) return;
      final file = response.file;
      if (file == null) {
        if (response.exception != null && mounted) {
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${l10n.errorGeneric}: ${response.exception}')),
          );
        }
        return;
      }
      await CrashLog.log('HomeScreen retrieveLostData: ${file.path}');
      if (!mounted) return;
      // Defer off the recover callback / activity-resume stack.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.microtask(() async {
          if (!mounted) return;
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PreparingScreen(rawImagePath: file.path),
            ),
          );
        });
      });
    } catch (e, st) {
      await CrashLog.log('HomeScreen retrieveLostData failed', e, st);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _exportSelected(ExportFormat format) async {
    final l10n = AppLocalizations.of(context);
    final provider = context.read<ContactsProvider>();
    final list = provider.selectedContacts;
    if (list.isEmpty) return;
    try {
      final svc = ExportService();
      final file = await svc.exportContacts(list, format);
      await svc.shareFile(file);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.errorGeneric}: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final provider = context.watch<ContactsProvider>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_selectMode ? l10n.selectForExport : l10n.appTitle),
        actions: [
          if (_selectMode) ...[
            IconButton(
              tooltip: l10n.isZh ? '全選' : 'Select all',
              icon: const Icon(Icons.select_all),
              onPressed: provider.selectAllFiltered,
            ),
            PopupMenuButton<ExportFormat>(
              tooltip: l10n.exportSelected,
              onSelected: _exportSelected,
              itemBuilder: (_) => [
                PopupMenuItem(
                    value: ExportFormat.vcard, child: Text(l10n.exportVcard)),
                PopupMenuItem(
                    value: ExportFormat.csv, child: Text(l10n.exportCsv)),
                PopupMenuItem(
                    value: ExportFormat.pdf, child: Text(l10n.exportPdf)),
              ],
              icon: const Icon(Icons.ios_share),
            ),
            TextButton(
              onPressed: () {
                setState(() => _selectMode = false);
                provider.clearSelection();
              },
              child: Text(l10n.done),
            ),
          ] else ...[
            IconButton(
              tooltip: l10n.selectForExport,
              icon: const Icon(Icons.checklist),
              onPressed: () => setState(() => _selectMode = true),
            ),
            IconButton(
              tooltip: l10n.settings,
              icon: const Icon(Icons.settings_outlined),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: SearchBar(
              controller: _searchController,
              hintText: l10n.searchHint,
              leading: const Icon(Icons.search),
              trailing: [
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      provider.setSearch('');
                      setState(() {});
                    },
                  ),
              ],
              onChanged: (v) {
                provider.setSearch(v);
                setState(() {});
              },
              elevation: const WidgetStatePropertyAll(0),
              backgroundColor: WidgetStatePropertyAll(
                scheme.surfaceContainerHighest.withValues(alpha: 0.6),
              ),
            ),
          ),
          if (provider.allTags.isNotEmpty)
            TagFilterBar(
              tags: provider.allTags,
              selected: provider.tagFilter,
              onSelected: provider.setTagFilter,
            ),
          Expanded(
            child: provider.loading
                ? const Center(child: CircularProgressIndicator())
                : provider.filtered.isEmpty
                    ? _EmptyState(
                        message: l10n.noContacts,
                        onScan: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ScanSourceScreen(),
                            ),
                          );
                        },
                        scanLabel: l10n.scan,
                      )
                    : RefreshIndicator(
                        onRefresh: provider.load,
                        child: ListView.separated(
                          padding: const EdgeInsets.only(bottom: 88),
                          itemCount: provider.filtered.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1, indent: 72),
                          itemBuilder: (context, index) {
                            final c = provider.filtered[index];
                            return ContactListTile(
                              contact: c,
                              selectMode: _selectMode,
                              selected: provider.selectedIds.contains(c.id),
                              onTap: () {
                                if (_selectMode) {
                                  provider.toggleSelected(c.id);
                                } else {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => ContactDetailScreen(
                                        contactId: c.id,
                                      ),
                                    ),
                                  );
                                }
                              },
                              onLongPress: () {
                                setState(() => _selectMode = true);
                                provider.toggleSelected(c.id);
                              },
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ScanSourceScreen()),
          );
        },
        icon: const Icon(Icons.document_scanner_outlined),
        label: Text(l10n.scan),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.message,
    required this.onScan,
    required this.scanLabel,
  });

  final String message;
  final VoidCallback onScan;
  final String scanLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.contact_page_outlined,
              size: 72,
              color: scheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onScan,
              icon: const Icon(Icons.document_scanner_outlined),
              label: Text(scanLabel),
            ),
          ],
        ),
      ),
    );
  }
}
