import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/ocr_result.dart';
import '../../providers/settings_provider.dart';
import '../../services/crash_log.dart';
import '../../services/ocr/ocr_coordinator.dart';
import '../../services/ocr_flags.dart';
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
    // Never start ML Kit on the same frame as route push / activity resume.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>(() async {
        // Extra settle time after Preparing → Processing transition.
        await Future<void>.delayed(const Duration(milliseconds: 250));
        if (!mounted) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Future.microtask(() => _run());
        });
      });
    });
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

  Future<void> _goReview(OcrResult result) async {
    if (!mounted) return;
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ReviewFieldsScreen(
          imagePath: widget.imagePath,
          initialFields: result.fields,
          ocrResult: result,
        ),
      ),
    );
  }

  Future<void> _run() async {
    final l10n = AppLocalizations.of(context);
    await CrashLog.log('ProcessingScreen._run path=${widget.imagePath}');
    if (!mounted) return;

    // Capture providers before further awaits (lint: use_build_context_synchronously).
    final settingsProvider = context.read<SettingsProvider>();
    final coordinator = OcrCoordinator();

    if (!kEnableMlKit) {
      await CrashLog.log('ProcessingScreen: ML Kit flag off → empty review');
      await _goReview(
        OcrResult.failure(
          OcrEngine.onDevice,
          'On-device ML Kit disabled (ENABLE_ML_KIT=false).',
        ),
      );
      return;
    }

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
      await CrashLog.log(
        'ProcessingScreen: OCR done succeeded=${result.succeeded} '
        'engine=${result.engine}',
      );
      await _goReview(result);
    } catch (e, st) {
      await CrashLog.log('OCR processing failed', e, st);
      if (!mounted) return;

      // Prefer navigating to manual review with empty fields over killing the flow.
      try {
        await _goReview(
          OcrResult.failure(OcrEngine.onDevice, e.toString()),
        );
        return;
      } catch (navError, navSt) {
        await CrashLog.log('Fallback navigation failed', navError, navSt);
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
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => _goReview(
                        OcrResult.failure(
                          OcrEngine.onDevice,
                          'Skipped OCR — fill fields manually.',
                        ),
                      ),
                      child: Text(l10n.isZh ? '略過辨識，手動填寫' : 'Skip OCR, fill manually'),
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
