import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/business_card_fields.dart';
import '../models/contact.dart';
import '../providers/contacts_provider.dart';
import '../services/export_service.dart';
import '../widgets/field_editor.dart';
import '../widgets/tag_chips.dart';

class ContactDetailScreen extends StatefulWidget {
  const ContactDetailScreen({super.key, required this.contactId});

  final String contactId;

  @override
  State<ContactDetailScreen> createState() => _ContactDetailScreenState();
}

class _ContactDetailScreenState extends State<ContactDetailScreen> {
  bool _editing = false;
  BusinessCardFields? _draft;

  Contact? _find(ContactsProvider p) {
    for (final c in p.contacts) {
      if (c.id == widget.contactId) return c;
    }
    return null;
  }

  Future<void> _export(ExportFormat format, Contact contact) async {
    final l10n = AppLocalizations.of(context);
    try {
      final svc = ExportService();
      final file = await svc.exportContacts([contact], format);
      await svc.shareFile(file);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.errorGeneric}: $e')),
      );
    }
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.delete),
        content: Text(l10n.confirmDelete),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await context.read<ContactsProvider>().deleteContact(widget.contactId);
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _toggleEdit(Contact contact) async {
    final l10n = AppLocalizations.of(context);
    if (_editing) {
      final f = _draft ?? contact.primaryFields;
      final updated = contact.copyWith(
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
      );
      await context.read<ContactsProvider>().updateContact(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.saved)),
        );
      }
      setState(() {
        _editing = false;
        _draft = null;
      });
    } else {
      setState(() {
        _editing = true;
        _draft = contact.primaryFields;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final provider = context.watch<ContactsProvider>();
    final contact = _find(provider);

    if (contact == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(contact.displayName),
        actions: [
          IconButton(
            icon: Icon(_editing ? Icons.check : Icons.edit_outlined),
            onPressed: () => _toggleEdit(contact),
          ),
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'vcard') await _export(ExportFormat.vcard, contact);
              if (v == 'csv') await _export(ExportFormat.csv, contact);
              if (v == 'pdf') await _export(ExportFormat.pdf, contact);
              if (v == 'delete') await _delete();
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'vcard', child: Text(l10n.exportVcard)),
              PopupMenuItem(value: 'csv', child: Text(l10n.exportCsv)),
              PopupMenuItem(value: 'pdf', child: Text(l10n.exportPdf)),
              PopupMenuItem(value: 'delete', child: Text(l10n.delete)),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n.tags, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          EditableTags(
            tags: contact.tags,
            onChanged: (tags) async {
              await context.read<ContactsProvider>().setTags(contact.id, tags);
            },
          ),
          const SizedBox(height: 24),
          if (_editing && _draft != null)
            FieldEditor(
              fields: _draft!,
              onChanged: (f) => setState(() => _draft = f),
            )
          else
            _ReadOnlyFields(contact: contact),
          const SizedBox(height: 24),
          Text(
            '${l10n.cards} (${contact.cards.length})',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ...contact.cards.map((card) {
            return Card(
              child: ListTile(
                title: Text(
                  card.fields.name ??
                      card.fields.companyName ??
                      card.id.substring(0, 8),
                ),
                subtitle: Text(
                  '${l10n.ocrSource}: ${card.ocrSource}\n'
                  '${card.createdAt.toLocal()}',
                ),
                isThreeLine: true,
                trailing: card.imagePath != null
                    ? IconButton(
                        tooltip: l10n.openImage,
                        icon: const Icon(Icons.image_outlined),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => _ImageViewer(
                                path: card.imagePath!,
                                title: l10n.openImage,
                              ),
                            ),
                          );
                        },
                      )
                    : null,
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ReadOnlyFields extends StatelessWidget {
  const _ReadOnlyFields({required this.contact});

  final Contact contact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Widget row(String label, String? value) {
      if (value == null || value.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 110,
              child: Text(label, style: Theme.of(context).textTheme.bodySmall),
            ),
            Expanded(child: Text(value)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        row(l10n.fieldName, contact.name),
        row(l10n.fieldTitle, contact.title),
        row(l10n.fieldCompany, contact.companyName),
        row(l10n.fieldAddress, contact.companyAddress),
        row(l10n.fieldPersonalPhone, contact.personalPhone),
        row(l10n.fieldPersonalEmail, contact.personalEmail),
        row(l10n.fieldCompanyPhone, contact.companyPhone),
        row(l10n.fieldCompanyEmail, contact.companyEmail),
        row(l10n.fieldFax, contact.fax),
        row(l10n.fieldWebsite, contact.companyWebsite),
      ],
    );
  }
}

class _ImageViewer extends StatelessWidget {
  const _ImageViewer({required this.path, required this.title});

  final String path;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: InteractiveViewer(child: Image.file(File(path))),
      ),
    );
  }
}
