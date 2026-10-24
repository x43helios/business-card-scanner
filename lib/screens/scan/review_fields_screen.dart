import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/business_card_fields.dart';
import '../../models/ocr_result.dart';
import '../../providers/contacts_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/contact_matcher.dart';
import '../../services/ocr/ocr_coordinator.dart';
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
  late OcrResult _ocrResult;
  late Set<String> _aiContributedFields;
  int _editorEpoch = 0;
  bool _saving = false;
  bool _refreshingAi = false;

  @override
  void initState() {
    super.initState();
    _fields = widget.initialFields;
    _ocrResult = widget.ocrResult;
    _aiContributedFields = Set<String>.from(widget.ocrResult.aiContributedFields);
  }

  String get _ocrSourceLabel {
    switch (_ocrResult.engine) {
      case OcrEngine.onDevice:
        return 'on_device';
      case OcrEngine.cloud:
        return 'cloud';
      case OcrEngine.stubDemo:
        return 'stub_demo';
    }
  }

  String _ocrSourceDisplay(AppLocalizations l10n) {
    switch (_ocrResult.engine) {
      case OcrEngine.onDevice:
        return l10n.isZh ? '本機' : 'Local';
      case OcrEngine.cloud:
        return l10n.isZh ? '雲端 OCR' : 'Cloud OCR';
      case OcrEngine.stubDemo:
        return l10n.isZh ? '示範 OCR' : 'Demo OCR';
    }
  }

  Future<void> _refreshAi() async {
    if (_refreshingAi || _saving) return;
    final l10n = AppLocalizations.of(context);
    final raw = _ocrResult.rawText.trim();
    if (raw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.refreshAiNoRawText)),
      );
      return;
    }

    setState(() => _refreshingAi = true);
    final settings = context.read<SettingsProvider>().settings;
    try {
      final coordinator = OcrCoordinator();
      // Keep current edited fields as the regex/base fill for empties after merge.
      final base = OcrResult(
        fields: _fields,
        rawText: _ocrResult.rawText,
        engine: _ocrResult.engine,
        succeeded: _ocrResult.succeeded,
        errorMessage: _ocrResult.errorMessage,
        aiContributedFields: const {},
      );
      final enriched = await coordinator.enrichWithAi(base, settings);
      if (!mounted) return;
      setState(() {
        _fields = enriched.fields;
        _ocrResult = enriched;
        _aiContributedFields = Set<String>.from(enriched.aiContributedFields);
        _editorEpoch++;
        _refreshingAi = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.refreshAiSuccess)),
      );
    } on AiEnrichException catch (e) {
      if (!mounted) return;
      setState(() => _refreshingAi = false);
      final msg = switch (e.code) {
        'empty_raw' => l10n.refreshAiNoRawText,
        'no_api_key' => l10n.refreshAiNoKey,
        'disabled' => l10n.refreshAiDisabled,
        'empty_ai' => l10n.refreshAiEmpty,
        _ => '${l10n.refreshAiFailed}: ${e.detail ?? e.code}',
      };
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (!mounted) return;
      setState(() => _refreshingAi = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.refreshAiFailed}: $e')),
      );
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
    final hasRaw = _ocrResult.rawText.trim().isNotEmpty;
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
            '${l10n.ocrSource}: ${_ocrSourceDisplay(l10n)}'
            '${_ocrResult.errorMessage != null ? " — ${_ocrResult.errorMessage}" : ""}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: (_refreshingAi || _saving || !hasRaw) ? null : _refreshAi,
              icon: _refreshingAi
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              label: Text(l10n.refreshAiFields),
            ),
          ),
          const SizedBox(height: 16),
          FieldEditor(
            key: ValueKey('fields-$_editorEpoch'),
            fields: _fields,
            aiContributedFields: _aiContributedFields,
            onChanged: (f) => setState(() => _fields = f),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.save_outlined),
            label: Text(l10n.save),
          ),
        ],
      ),
    );
  }
}
