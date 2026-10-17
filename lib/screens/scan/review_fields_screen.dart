import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/business_card_fields.dart';
import '../../models/ocr_result.dart';
import '../../providers/contacts_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/contact_matcher.dart';
import '../../widgets/field_editor.dart';
import '../../widgets/merge_dialog.dart';
import '../contact_detail_screen.dart';

class ReviewFieldsScreen extends StatefulWidget {
  const ReviewFieldsScreen({
    super.key,
    required this.imagePath,
    required this.initialFields,
    required this.ocrResult,
  });

  final String imagePath;
  final BusinessCardFields initialFields;
  final OcrResult ocrResult;

  @override
  State<ReviewFieldsScreen> createState() => _ReviewFieldsScreenState();
}

class _ReviewFieldsScreenState extends State<ReviewFieldsScreen> {
  late BusinessCardFields _fields;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _fields = widget.initialFields;
  }

  String get _ocrSourceLabel {
    switch (widget.ocrResult.engine) {
      case OcrEngine.onDevice:
        return 'on_device';
      case OcrEngine.cloud:
        return 'cloud';
      case OcrEngine.stubDemo:
        return 'stub_demo';
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final l10n = AppLocalizations.of(context);
    final contacts = context.read<ContactsProvider>();
    final settings = context.read<SettingsProvider>().settings;

    try {
      final matches = ContactMatcher.findMatches(_fields, contacts.contacts);
      MatchCandidate? chosen;
      if (matches.isNotEmpty && mounted) {
        chosen = await showMergeDialog(context: context, candidates: matches);
      }

      final saved = chosen == null
          ? await contacts.createContactWithCard(
              fields: _fields,
              imagePath: widget.imagePath,
              ocrSource: _ocrSourceLabel,
              savePhoto: settings.saveCardPhoto,
            )
          : await contacts.mergeCardOntoContact(
              contactId: chosen.contact.id,
              fields: _fields,
              imagePath: widget.imagePath,
              ocrSource: _ocrSourceLabel,
              savePhoto: settings.saveCardPhoto,
            );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.saved)),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => ContactDetailScreen(contactId: saved.id),
        ),
        (route) => route.isFirst,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.errorGeneric}: $e')),
      );
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.reviewFields),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.save),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File(widget.imagePath),
              height: 160,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox(
                height: 80,
                child: Center(child: Icon(Icons.broken_image)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${l10n.ocrSource}: $_ocrSourceLabel'
            '${widget.ocrResult.errorMessage != null ? " — ${widget.ocrResult.errorMessage}" : ""}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          FieldEditor(
            fields: _fields,
            onChanged: (f) => setState(() => _fields = f),
          ),
        ],
      ),
    );
  }
}
