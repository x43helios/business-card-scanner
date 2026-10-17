import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/contacts_provider.dart';
import '../services/export_service.dart';
import '../widgets/contact_list_tile.dart';
import '../widgets/tag_chips.dart';
import 'contact_detail_screen.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: Text(_selectMode ? l10n.selectForExport : l10n.appTitle),
        actions: [
          if (_selectMode) ...[
            PopupMenuButton<ExportFormat>(
              tooltip: l10n.exportSelected,
              onSelected: _exportSelected,
              itemBuilder: (_) => [
                PopupMenuItem(value: ExportFormat.vcard, child: Text(l10n.exportVcard)),
                PopupMenuItem(value: ExportFormat.csv, child: Text(l10n.exportCsv)),
                PopupMenuItem(value: ExportFormat.pdf, child: Text(l10n.exportPdf)),
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
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: l10n.searchHint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
              ),
              onChanged: provider.setSearch,
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
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            l10n.noContacts,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: provider.load,
                        child: ListView.separated(
                          itemCount: provider.filtered.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
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
                                      builder: (_) =>
                                          ContactDetailScreen(contactId: c.id),
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
