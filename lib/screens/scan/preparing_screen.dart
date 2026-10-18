import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/business_card_fields.dart';
import '../../models/ocr_result.dart';
import '../../services/crash_log.dart';
import '../../services/ocr_flags.dart';
import '../../services/scan_image_store.dart';
import 'processing_screen.dart';
import 'review_fields_screen.dart';

/// Intermediate route shown immediately after image_picker returns.
///
/// Responsibilities:
/// - Paint a simple “Preparing…” UI BEFORE any OCR / ML Kit
/// - Copy + validate + downscale the picked file into app documents
/// - Only THEN navigate to [ProcessingScreen] (or empty [ReviewFieldsScreen]
///   when ML Kit is disabled via dart-define)
///
/// Never call ML Kit from this widget — keeps native work off the pick stack.
class PreparingScreen extends StatefulWidget {
  const PreparingScreen({super.key, required this.rawImagePath});

  final String rawImagePath;

  @override
  State<PreparingScreen> createState() => _PreparingScreenState();
}

class _PreparingScreenState extends State<PreparingScreen> {
  String? _error;

  @override
  void initState() {
    super.initState();
    // Defer past the first paint so the user always sees Preparing… before I/O.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>(() => _prepare());
    });
  }

  Future<void> _prepare() async {
    await CrashLog.log('PreparingScreen: start ${widget.rawImagePath}');
    // Give the framework another frame + a short beat after activity resume.
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;

    try {
      final stablePath =
          await ScanImageStore.persistAndValidate(widget.rawImagePath);
      if (!mounted) return;

      if (!kEnableMlKit) {
        await CrashLog.log('PreparingScreen: ML Kit disabled → empty review');
        if (!mounted) return;
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ReviewFieldsScreen(
              imagePath: stablePath,
              initialFields: const BusinessCardFields(),
              ocrResult: OcrResult.failure(
                OcrEngine.onDevice,
                'On-device ML Kit disabled (ENABLE_ML_KIT=false). Fill fields manually.',
              ),
            ),
          ),
        );
        return;
      }

      await CrashLog.log('PreparingScreen: → ProcessingScreen');
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ProcessingScreen(imagePath: stablePath),
        ),
      );
    } catch (e, st) {
      await CrashLog.log('PreparingScreen failed', e, st);
      if (!mounted) return;
      // Still try to open empty review if we at least have a readable path.
      try {
        final fallbackPath = widget.rawImagePath;
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ReviewFieldsScreen(
              imagePath: fallbackPath,
              initialFields: const BusinessCardFields(),
              ocrResult: OcrResult.failure(
                OcrEngine.onDevice,
                'Prepare failed: $e',
              ),
            ),
          ),
        );
        return;
      } catch (_) {}

      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.preparing)),
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
                  Text(l10n.preparing),
                ],
              ),
      ),
    );
  }
}
