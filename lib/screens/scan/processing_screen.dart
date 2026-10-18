import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/business_card_fields.dart';
import '../../models/ocr_result.dart';
import '../../providers/settings_provider.dart';
import '../../services/ocr/ocr_coordinator.dart';
import 'review_fields_screen.dart';

class ProcessingScreen extends StatefulWidget {
  const ProcessingScreen({super.key, required this.imagePath});

  final String imagePath;

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> {
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<bool> _askConsent() async {
    if (!mounted) return false;
    final l10n = AppLocalizations.of(context);
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.cloudConsentTitle),
        content: Text(l10n.cloudConsentBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.disagree),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.agree),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _run() async {
    final l10n = AppLocalizations.of(context);
    final settingsProvider = context.read<SettingsProvider>();
    final coordinator = OcrCoordinator();

    try {
      final file = File(widget.imagePath);
      if (!await file.exists()) {
        throw StateError('Image missing at ${widget.imagePath}');
      }
      final len = await file.length();
      if (len < 32) {
        throw StateError('Image is empty or unreadable ($len bytes).');
      }

      final result = await coordinator.recognize(
        imageFile: file,
        settings: settingsProvider.settings,
        persistSettings: settingsProvider.persist,
        askCloudConsent: _askConsent,
      );

      if (!mounted) return;

      // Always open review so the user can fill fields manually if OCR failed.
      // Soft-fail: if OCR reported failure, still proceed with empty/partial fields.
      final fields = result.fields;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ReviewFieldsScreen(
            imagePath: widget.imagePath,
            initialFields: fields,
            ocrResult: result,
          ),
        ),
      );

      // After returning from review is not expected (pushReplacement); if OCR
      // failed and review was skipped somehow, surface a snackbar on prior route.
      if (result.errorMessage != null && mounted) {
        // no-op: review screen shows fields; error is in ocrResult
      }
    } catch (e, st) {
      debugPrint('OCR processing failed: $e\n$st');
      if (!mounted) return;

      // Prefer navigating to manual review with empty fields over killing the flow.
      if (!mounted) return;
      try {
        final fallback = OcrResult.failure(
          OcrEngine.onDevice,
          e.toString(),
        );
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ReviewFieldsScreen(
              imagePath: widget.imagePath,
              initialFields: const BusinessCardFields(),
              ocrResult: fallback,
            ),
          ),
        );
        return;
      } catch (navError) {
        debugPrint('Fallback navigation failed: $navError');
      }

      if (!mounted) return;
      setState(() => _error = '${l10n.errorGeneric}: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.errorGeneric}: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.processing)),
      body: Center(
        child: _error != null
            ? Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(l10n.cancel),
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(l10n.processing),
                ],
              ),
      ),
    );
  }
}
