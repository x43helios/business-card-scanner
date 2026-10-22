import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
        chineseName: f.chineseName,
        englishName: f.englishName,
        titleChinese: f.titleChinese,
        titleEnglish: f.titleEnglish,
        qualifications: f.qualifications,
        education: f.education,
        companyNameChinese: f.companyNameChinese,
        companyNameEnglish: f.companyNameEnglish,
        department: f.department,
        personalPhone: f.personalPhone,
        whatsapp: f.whatsapp,
        wechat: f.wechat,
        lineId: f.lineId,
        companyPhone: f.companyPhone,
        directLine: f.directLine,
        extension: f.extension,
        fax: f.fax,
        personalEmail: f.personalEmail,
        companyEmail: f.companyEmail,
        companyWebsite: f.companyWebsite,
        linkedIn: f.linkedIn,
        socialMedia: f.socialMedia,
        companyAddressChinese: f.companyAddressChinese,
        companyAddressEnglish: f.companyAddressEnglish,
        roomFloor: f.roomFloor,
        district: f.district,
        postalCode: f.postalCode,
        slogan: f.slogan,
        services: f.services,
        businessHours: f.businessHours,
        qrInfo: f.qrInfo,
        notes: f.notes,
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
            void openCardImage() {
              final path = card.imagePath;
              if (path != null && path.isNotEmpty) {
                final file = File(path);
                if (!file.existsSync()) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.cardImageMissing)),
                  );
                  return;
                }
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => _ImageViewer(
                      path: path,
                      title: l10n.openImage,
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.cardImageNotSaved)),
                );
              }
            }

            Widget? leading;
            if (card.imagePath != null && card.imagePath!.isNotEmpty) {
              leading = ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.file(
                  File(card.imagePath!),
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox(
                    width: 56,
                    height: 56,
                    child: Icon(Icons.broken_image_outlined),
                  ),
                ),
              );
            }

            return Card(
              child: ListTile(
                leading: leading,
                title: Text(
                  card.fields.name ??
                      card.fields.companyName ??
                      card.id.substring(0, 8),
                ),
                subtitle: Text(
                  '${l10n.ocrSource}: ${card.ocrSource}\n'
                  '${DateFormat.yMMMd().add_Hm().format(card.createdAt.toLocal())}',
                ),
                isThreeLine: true,
                onTap: openCardImage,
                trailing: IconButton(
                  tooltip: l10n.openImage,
                  icon: const Icon(Icons.image_outlined),
                  onPressed: openCardImage,
                ),
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

    Widget section(String title) => Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 6),
          child: Text(title, style: Theme.of(context).textTheme.titleSmall),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        section(l10n.sectionIdentity),
        row(l10n.fieldChineseName, contact.chineseName),
        row(l10n.fieldEnglishName, contact.englishName),
        row(l10n.fieldTitleChinese, contact.titleChinese),
        row(l10n.fieldTitleEnglish, contact.titleEnglish),
        row(l10n.fieldQualifications, contact.qualifications),
        row(l10n.fieldEducation, contact.education),
        section(l10n.sectionOrganization),
        row(l10n.fieldCompanyChinese, contact.companyNameChinese),
        row(l10n.fieldCompanyEnglish, contact.companyNameEnglish),
        row(l10n.fieldDepartment, contact.department),
        section(l10n.sectionContact),
        row(l10n.fieldPersonalPhone, contact.personalPhone),
        row(l10n.fieldWhatsapp, contact.whatsapp),
        row(l10n.fieldWechat, contact.wechat),
        row(l10n.fieldLineId, contact.lineId),
        row(l10n.fieldCompanyPhone, contact.companyPhone),
        row(l10n.fieldDirectLine, contact.directLine),
        row(l10n.fieldExtension, contact.extension),
        row(l10n.fieldFax, contact.fax),
        row(l10n.fieldPersonalEmail, contact.personalEmail),
        row(l10n.fieldCompanyEmail, contact.companyEmail),
        row(l10n.fieldWebsite, contact.companyWebsite),
        row(l10n.fieldLinkedIn, contact.linkedIn),
        row(l10n.fieldSocialMedia, contact.socialMedia),
        section(l10n.sectionAddress),
        row(l10n.fieldAddressChinese, contact.companyAddressChinese),
        row(l10n.fieldAddressEnglish, contact.companyAddressEnglish),
        row(l10n.fieldRoomFloor, contact.roomFloor),
        row(l10n.fieldDistrict, contact.district),
        row(l10n.fieldPostalCode, contact.postalCode),
        section(l10n.sectionOther),
        row(l10n.fieldSlogan, contact.slogan),
        row(l10n.fieldServices, contact.services),
        row(l10n.fieldBusinessHours, contact.businessHours),
        row(l10n.fieldQrInfo, contact.qrInfo),
        row(l10n.fieldNotes, contact.notes),
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
